import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/intelligence_models.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;
  late Future<CohortMatrixData> _cohortFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _analyticsFuture = ApiService.getOverviewAnalytics();
    _cohortFuture = ApiService.fetchCohortMatrix();
  }

  Color _getSegmentColor(String segment) {
    final s = segment.toLowerCase();
    if (s.contains('champion')) return const Color(0xFF10B981);
    if (s.contains('loyal')) return const Color(0xFF3B82F6);
    if (s.contains('potential')) return const Color(0xFF6366F1);
    if (s.contains('risk') || s.contains('attention')) {
      return const Color(0xFFF59E0B);
    }
    if (s.contains('hibernating') ||
        s.contains('sleep') ||
        s.contains('loose')) {
      return const Color(0xFF64748B);
    }
    return const Color(0xFF8B5CF6);
  }

  Color _getCohortCellColor(double rate) {
    if (rate >= 100.0) return const Color(0xFF0284C7);
    if (rate >= 35.0) return const Color(0xFF0D9488);
    if (rate >= 25.0) return const Color(0xFF059669);
    if (rate >= 20.0) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text(
              'Executive BI Cockpit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => setState(_loadData),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 16),
                  Text(
                    'Makro metrikler ve içgörüler derleniyor...\n(Render uyanıyorsa 20-30 sn sürebilir)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.amberAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                      ),
                      onPressed: () => setState(_loadData),
                      child: const Text(
                        'Yeniden Dene',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final insights = (data['automated_insights'] as List<dynamic>?) ?? [];
          final segments =
              (data['segment_distribution'] as List<dynamic>?) ?? [];

          return RefreshIndicator(
            onRefresh: () async => setState(_loadData),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'KURUMSAL KPI GÖSTERGELERİ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildKpiCard(
                      'Toplam Gelir',
                      MetricFormatter.currency(data['total_revenue'] ?? 0),
                      Icons.monetization_on_outlined,
                      const Color(0xFF10B981),
                    ),
                    _buildKpiCard(
                      'Müşteri Tabanı',
                      MetricFormatter.compactNumber(
                        data['total_customers'] ?? 0,
                      ),
                      Icons.people_alt_outlined,
                      const Color(0xFF3B82F6),
                    ),
                    _buildKpiCard(
                      'Ort. Sepet (AOV)',
                      MetricFormatter.currency(
                        data['average_order_value'] ?? 0,
                      ),
                      Icons.shopping_basket_outlined,
                      const Color(0xFFF59E0B),
                    ),
                    _buildKpiCard(
                      'Toplam Sipariş',
                      MetricFormatter.compactNumber(
                        data['total_transactions'] ?? 0,
                      ),
                      Icons.receipt_long_outlined,
                      const Color(0xFFA855F7),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (insights.isNotEmpty) ...[
                  const Text(
                    'OTOMATİK İŞ VE AKSİYON İÇGÖRÜLERİ',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...insights.map((item) => _buildInsightCard(item)),
                  const SizedBox(height: 24),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'MÜŞTERİ SEGMENTLERİ & HEDEF KİTLE AKTARIMI',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Meta / Klaviyo',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: segments
                        .map((seg) => _buildSegmentRow(seg))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // --- GÜN 14: KOHORT RETENTION ISI HARİTASI ---
                const Row(
                  children: [
                    Icon(
                      Icons.grid_on_rounded,
                      color: Colors.cyanAccent,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'MÜŞTERİ YAŞAM DÖNGÜSÜ & KOHORT ISI HARİTASI',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCohortSection(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(dynamic item) {
    final type = item['type'] ?? 'info';
    Color accentColor = Colors.cyanAccent;
    IconData iconData = Icons.info_outline;

    if (type == 'warning') {
      accentColor = const Color(0xFFF59E0B);
      iconData = Icons.warning_amber_rounded;
    } else if (type == 'success') {
      accentColor = const Color(0xFF10B981);
      iconData = Icons.verified_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: accentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category']?.toString().toUpperCase() ?? 'İÇGÖRÜ',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

  Widget _buildSegmentRow(dynamic seg) {
    final rawName = seg['segment'].toString();
    final displayName = rawName.replaceAll('_', ' ').toUpperCase();
    final count = seg['count'] ?? 0;
    final pct = (seg['percentage'] as num?)?.toDouble() ?? 0.0;
    final color = _getSegmentColor(displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$count müşteri (%$pct)',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ApiService.exportSegmentCsv(rawName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1E293B),
                          content: Text(
                            '$displayName hedef kitlesi CSV olarak dışa aktarılıyor...',
                            style: const TextStyle(color: Colors.cyanAccent),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 12,
                            color: Colors.cyanAccent,
                          ),
                          SizedBox(width: 3),
                          Text(
                            "CSV",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortSection() {
    return FutureBuilder<CohortMatrixData>(
      future: _cohortFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Kohort verisi yüklenemedi.",
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          );
        }

        final matrix = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Aylık Kohort Tutma Oranı (Retention Heatmap)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Her satır bir edinim kohortunu, sütunlar takip eden aylardaki platforma dönüş oranını (%) gösterir.",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 8,
                  columnSpacing: 10,
                  headingRowHeight: 32,
                  dataRowMinHeight: 28,
                  dataRowMaxHeight: 28,
                  columns: [
                    const DataColumn(
                      label: Text(
                        "Kohort",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        "Kullanıcı",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...matrix.periods
                        .take(6)
                        .map(
                          (p) => DataColumn(
                            label: Text(
                              p,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  ],
                  rows: matrix.cohorts.take(6).map((c) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            c.cohortMonth,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${c.totalCustomers}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        ...c.retentionRates.take(6).map((rate) {
                          final cellColor = _getCohortCellColor(rate);
                          return DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cellColor.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: cellColor.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                "%${rate.toInt()}",
                                style: TextStyle(
                                  color: cellColor,
                                  fontSize: 10,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
