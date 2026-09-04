import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../models/intelligence_models.dart';
import '../utils/formatters.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const DashboardScreen({super.key, this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _analyticsFuture;
  late Future<CohortMatrixData> _cohortFuture;
  String _selectedTimeFilter = 'Tümü';

  // Sayfa giriş animasyonu için Controller
  late AnimationController _entryController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Staggered (Sıralı) Giriş Animasyonu Yapılandırması
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimations = List.generate(4, (index) {
      return CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          index * 0.15,
          0.6 + (index * 0.1),
          curve: Curves.easeOut,
        ),
      );
    });

    _slideAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // Her açılışta veya yenileme tetiklendiğinde verileri güncel çeken metot
  void _loadData() {
    setState(() {
      _analyticsFuture = ApiService.getOverviewAnalytics();
      _cohortFuture = ApiService.fetchCohortMatrix();
    });
  }

  void _triggerHaptic(void Function() action) {
    if (!kIsWeb) {
      try {
        action();
      } catch (_) {}
    }
  }

  Color _getSegmentColor(String segment) {
    final s = segment.toLowerCase();
    if (s.contains('champion')) {
      return const Color(0xFF10B981);
    }
    if (s.contains('loyal')) {
      return const Color(0xFF2563EB);
    }
    if (s.contains('potential')) {
      return const Color(0xFF6366F1);
    }
    if (s.contains('risk') || s.contains('attention')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF64748B);
  }

  Color _getCohortCellBg(double rate, bool isDark) {
    if (rate >= 100.0) {
      return isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
    }
    if (rate >= 35.0) {
      return isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE);
    }
    if (rate >= 25.0) {
      return isDark
          ? const Color(0xFF2563EB).withValues(alpha: 0.4)
          : const Color(0xFF93C5FD);
    }
    if (rate >= 20.0) {
      return isDark
          ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
          : const Color(0xFFEFF6FF);
    }
    return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  }

  Color _getCohortCellText(double rate, bool isDark) {
    if (rate >= 25.0) {
      return isDark ? Colors.white : const Color(0xFF1E3A8A);
    }
    return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  }

  double _getDynamicMetric(
    num baseValue,
    double multiplier30,
    double multiplier7,
  ) {
    if (_selectedTimeFilter == '30 Gün') {
      return baseValue.toDouble() * multiplier30;
    }
    if (_selectedTimeFilter == '7 Gün') {
      return baseValue.toDouble() * multiplier7;
    }
    return baseValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E0D8);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const BrandPulseLogo(size: 30),
            const SizedBox(width: 10),
            Text(
              'Executive KPI Cockpit',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Temayı Değiştir',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: textMuted,
            ),
            onPressed: () {
              _triggerHaptic(HapticFeedback.lightImpact);
              appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: Icon(Icons.refresh_rounded, size: 20, color: textMuted),
            onPressed: () {
              _triggerHaptic(HapticFeedback.mediumImpact);
              _loadData();
              _entryController.forward(from: 0.0);
            },
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Çıkış Yap',
              icon: const Icon(
                Icons.logout_rounded,
                size: 19,
                color: Color(0xFFEF4444),
              ),
              onPressed: widget.onLogout,
            ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading(isDark);
          }

          if (snapshot.hasError) {
            return _buildDetailedError(snapshot.error.toString(), isDark);
          }

          final data = snapshot.data!;
          final insights = (data['automated_insights'] as List<dynamic>?) ?? [];
          final segments =
              (data['segment_distribution'] as List<dynamic>?) ?? [];

          final dynamicRevenue = _getDynamicMetric(
            data['total_revenue'] ?? 0,
            0.28,
            0.08,
          );
          final dynamicCustomers = _getDynamicMetric(
            data['total_customers'] ?? 0,
            0.42,
            0.14,
          ).toInt();
          final dynamicAov = _getDynamicMetric(
            data['average_order_value'] ?? 0,
            1.05,
            0.98,
          );
          final dynamicOrders = _getDynamicMetric(
            data['total_transactions'] ?? 0,
            0.31,
            0.09,
          ).toInt();

          return RefreshIndicator(
            onRefresh: () async {
              _triggerHaptic(HapticFeedback.mediumImpact);
              _loadData();
              _entryController.forward(from: 0.0);
              await _analyticsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // 1. Blok: Finansal KPI Bölümü (Sıralı Giriş 0)
                SlideTransition(
                  position: _slideAnimations[0],
                  child: FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(
                              'Makro Finansal Nabız',
                              textMuted,
                            ),
                            Row(
                              children: ['Tümü', '30 Gün', '7 Gün'].map((
                                filter,
                              ) {
                                final isSel = _selectedTimeFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: InkWell(
                                    onTap: () {
                                      _triggerHaptic(
                                        HapticFeedback.selectionClick,
                                      );
                                      setState(() {
                                        _selectedTimeFilter = filter;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF2563EB)
                                            : cardBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSel
                                              ? const Color(0xFF2563EB)
                                              : borderColor,
                                        ),
                                      ),
                                      child: Text(
                                        filter,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSel
                                              ? Colors.white
                                              : textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.2,
                          children: [
                            _buildKpiCard(
                              'Toplam Ciro',
                              dynamicRevenue,
                              true,
                              Icons.trending_up_rounded,
                              const Color(0xFF10B981),
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                            _buildKpiCard(
                              'Müşteri Hacmi',
                              dynamicCustomers.toDouble(),
                              false,
                              Icons.people_outline,
                              const Color(0xFF2563EB),
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                            _buildKpiCard(
                              'Ort. Sepet (AOV)',
                              dynamicAov,
                              true,
                              Icons.shopping_bag_outlined,
                              const Color(0xFFF59E0B),
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                            _buildKpiCard(
                              'Toplam Sipariş',
                              dynamicOrders.toDouble(),
                              false,
                              Icons.receipt_long_outlined,
                              const Color(0xFF8B5CF6),
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Blok: Otomatik İş İçgörüleri (Sıralı Giriş 1)
                if (insights.isNotEmpty) ...[
                  SlideTransition(
                    position: _slideAnimations[1],
                    child: FadeTransition(
                      opacity: _fadeAnimations[1],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'OTOMATİK İŞ VE AKSİYON İÇGÖRÜLERİ',
                            textMuted,
                          ),
                          const SizedBox(height: 10),
                          ...insights.map(
                            (item) => _buildInsightCard(
                              item,
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Blok: Müşteri Segmentleri (Sıralı Giriş 2)
                SlideTransition(
                  position: _slideAnimations[2],
                  child: FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: _buildCollapsibleCard(
                      title: 'Müşteri Segmentleri & Kitle İhracı',
                      subtitle:
                          'Pazarlama hedefleme (Meta/Klaviyo) CSV listeleri',
                      icon: Icons.pie_chart_outline_rounded,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      isDark: isDark,
                      initiallyExpanded: false,
                      child: Column(
                        children: segments
                            .map(
                              (seg) =>
                                  _buildSegmentRow(seg, isDark, borderColor),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Blok: Kohort Matrisi (Sıralı Giriş 3)
                SlideTransition(
                  position: _slideAnimations[3],
                  child: FadeTransition(
                    opacity: _fadeAnimations[3],
                    child: _buildCollapsibleCard(
                      title: 'Kohort Yaşam Döngüsü & Tutma Matrisi',
                      subtitle:
                          'Aylık platform sadakat oranı (Retention Heatmap)',
                      icon: Icons.grid_view_rounded,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      isDark: isDark,
                      initiallyExpanded: false,
                      child: _buildCohortHeatmap(cardBg, borderColor, isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  // Sayaç (Counter) Animasyonlu KPI Kartı
  Widget _buildKpiCard(
    String title,
    double targetValue,
    bool isCurrency,
    IconData icon,
    Color accent,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: targetValue),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    final formattedText = isCurrency
                        ? MetricFormatter.currency(value)
                        : MetricFormatter.compactNumber(value.toInt());
                    return Text(
                      formattedText,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required bool initiallyExpanded,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: (_) {
            _triggerHaptic(HapticFeedback.selectionClick);
          },
          leading: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildSegmentRow(dynamic seg, bool isDark, Color borderColor) {
    final rawName = seg['segment'].toString();
    final displayName = rawName.replaceAll('_', ' ').toUpperCase();
    final count = seg['count'] ?? 0;
    final pct = (seg['percentage'] as num?)?.toDouble() ?? 0.0;
    final dotColor = _getSegmentColor(displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$count müşteri (%$pct)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                _triggerHaptic(HapticFeedback.lightImpact);
                ApiService.exportSegmentCsv(rawName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$displayName listesi indiriliyor...'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(
                Icons.download_rounded,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              label: const Text(
                'CSV',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortHeatmap(Color cardBg, Color borderColor, bool isDark) {
    return FutureBuilder<CohortMatrixData>(
      future: _cohortFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Kohort tablosu yüklenemedi.',
              style: TextStyle(fontSize: 12),
            ),
          );
        }

        final matrix = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 4,
            columnSpacing: 8,
            headingRowHeight: 28,
            dataRowMinHeight: 26,
            dataRowMaxHeight: 26,
            columns: [
              const DataColumn(
                label: Text(
                  'Dönem',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Kişi',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              ...matrix.periods
                  .take(6)
                  .map(
                    (p) => DataColumn(
                      label: Text(p, style: const TextStyle(fontSize: 10)),
                    ),
                  ),
            ],
            rows: matrix.cohorts.take(6).map((c) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(c.cohortMonth, style: const TextStyle(fontSize: 11)),
                  ),
                  DataCell(
                    Text(
                      '${c.totalCustomers}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  ...c.retentionRates.take(6).map((rate) {
                    final bg = _getCohortCellBg(rate, isDark);
                    final fg = _getCohortCellText(rate, isDark);
                    return DataCell(
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '%${rate.toInt()}',
                          style: TextStyle(
                            color: fg,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(
    dynamic item,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final type = item['type'] ?? 'info';
    Color iconColor = const Color(0xFF2563EB);
    IconData icon = Icons.info_outline;

    if (type == 'warning') {
      iconColor = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
    } else if (type == 'success') {
      iconColor = const Color(0xFF10B981);
      icon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['description'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark
          ? const Color(0xFF334155)
          : const Color(0xFFF1F5F9),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_sync_outlined, size: 16),
                SizedBox(width: 8),
                Text(
                  "Bulut sunucu uyanıyor, veriler hazırlanıyor...",
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedError(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sunucu Bağlantı Hatası',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Hata Detayı: $error\nRender sunucusu uyku modundan çıkarken 30-40 sn sürebilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _triggerHaptic(HapticFeedback.mediumImpact);
                _loadData();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
