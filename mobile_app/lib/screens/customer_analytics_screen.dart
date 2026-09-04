import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/intelligence_models.dart';
import '../utils/formatters.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const CustomerAnalyticsScreen({super.key, this.onLogout});

  @override
  State<CustomerAnalyticsScreen> createState() =>
      _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  final TextEditingController _idController = TextEditingController(
    text: '12347',
  );
  final TextEditingController _customProductController =
      TextEditingController();

  CustomerProfile? _customer;
  bool _isLoadingCustomer = false;
  String? _customerError;

  double _simDays = 15;
  double _simOrders = 1;
  double _simSpend = 100;
  SimulationResult? _simResult;
  bool _isSimulating = false;

  final List<String> _cart = [];
  List<RecommendedItem> _recommendations = [];
  bool _isLoadingRecs = false;

  final List<String> _sampleProducts = [
    "POPPY'S PLAYHOUSE KITCHEN",
    "POPPY'S PLAYHOUSE BEDROOM",
    "GREEN REGENCY TEACUP AND SAUCER",
    "SET/10 BLUE SPOTTY PARTY CANDLES",
    "JUMBO BAG RED RETROSPOT",
    "WHITE HANGING HEART T-LIGHT HOLDER",
  ];

  @override
  void initState() {
    super.initState();
    _searchCustomer();
  }

  @override
  void dispose() {
    _idController.dispose();
    _customProductController.dispose();
    super.dispose();
  }

  void _triggerHaptic(void Function() action) {
    if (!kIsWeb) {
      try {
        action();
      } catch (_) {}
    }
  }

  void _searchCustomer() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    _triggerHaptic(HapticFeedback.lightImpact);

    setState(() {
      _isLoadingCustomer = true;
      _customerError = null;
      _simResult = null;
    });

    try {
      final res = await ApiService.fetchCustomerProfile(id);
      setState(() {
        _customer = res;
        if (res == null) {
          _customerError =
              "ID #$id numaralı müşteri bulunamadı. Lütfen geçerli bir müşteri numarası girin.";
        }
      });
    } catch (e) {
      setState(() {
        _customerError = "Bağlantı Hatası: $e";
      });
    } finally {
      setState(() {
        _isLoadingCustomer = false;
      });
    }
  }

  void _runSimulation() async {
    if (_customer == null) {
      return;
    }
    _triggerHaptic(HapticFeedback.mediumImpact);
    setState(() {
      _isSimulating = true;
    });

    try {
      final res = await ApiService.simulateCustomer(
        customerId: _customer!.customerId,
        daysToNextOrder: _simDays.toInt(),
        additionalOrders: _simOrders.toInt(),
        additionalSpend: _simSpend,
      );
      setState(() {
        _simResult = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            content: Text(
              'Simülasyon motoru hatası: $e',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSimulating = false;
      });
    }
  }

  void _confirmRemoveCartItem(String item) {
    _triggerHaptic(HapticFeedback.selectionClick);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Ürünü Çıkar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '\'$item\' ürününü sepetten çıkarmak istediğinizden emin misiniz?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _triggerHaptic(HapticFeedback.mediumImpact);
              setState(() {
                _cart.remove(item);
              });
              _getRecommendations();
            },
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }

  void _addToCart(String product) {
    final clean = product.trim();
    if (clean.isEmpty) {
      return;
    }
    _triggerHaptic(HapticFeedback.lightImpact);

    if (!_cart.contains(clean)) {
      setState(() {
        _cart.add(clean);
      });
      _getRecommendations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$clean zaten sepette ekli.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _addCustomProduct() {
    final text = _customProductController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _addToCart(text.toUpperCase());
    _customProductController.clear();
    FocusScope.of(context).unfocus();
  }

  void _getRecommendations() async {
    if (_cart.isEmpty) {
      setState(() {
        _recommendations = [];
      });
      return;
    }
    setState(() {
      _isLoadingRecs = true;
    });
    try {
      final recs = await ApiService.fetchRecommendations(_cart);
      setState(() {
        _recommendations = recs;
      });
    } catch (_) {
    } finally {
      setState(() {
        _isLoadingRecs = false;
      });
    }
  }

  Color _getHealthColor(int score) {
    if (score >= 80) {
      return const Color(0xFF10B981);
    }
    if (score >= 50) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: 0,
          actions: [
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
          title: Text(
            'Müşteri 360° & Yaşam Döngüsü Analitiği',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Müşteri ID (Örn: 12347)',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _searchCustomer(),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(9),
                              bottomRight: Radius.circular(9),
                            ),
                          ),
                        ),
                        onPressed: _isLoadingCustomer ? null : _searchCustomer,
                        child: const Text(
                          'Sorgula',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoadingCustomer)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28.0),
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              if (_customerError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _customerError!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_customer != null) ...[
                _buildCustomerHeaderCard(
                  _customer!,
                  cardBg,
                  borderColor,
                  isDark,
                ),
                const SizedBox(height: 12),
                if (_customer!.scorecard != null)
                  _buildScorecardCard(
                    _customer!.scorecard!,
                    cardBg,
                    borderColor,
                    isDark,
                  ),
                const SizedBox(height: 12),
                if (_customer!.actionPlan != null)
                  _buildActionPlanCard(
                    _customer!.actionPlan!,
                    cardBg,
                    borderColor,
                    isDark,
                  ),
                const SizedBox(height: 12),
                _buildWhatIfSimulationCard(cardBg, borderColor, isDark),
              ],

              const Divider(height: 36, color: Color(0xFFE2E8F0)),

              Text(
                "SEPET BİRLİKTELİK ANALİZİ & APRIORI ÇAPRAZ SATIŞ",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _customProductController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText:
                              'İstediğin ürünü yaz ve ekle (Örn: TEA CUP)...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 11),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addCustomProduct(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                      tooltip: 'Sepete Ekle',
                      onPressed: _addCustomProduct,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Önerilen Hızlı Ürünler:",
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _sampleProducts.map((p) {
                  final isInCart = _cart.contains(p);
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: isInCart
                        ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                        : cardBg,
                    side: BorderSide(
                      color: isInCart ? const Color(0xFF2563EB) : borderColor,
                    ),
                    avatar: Icon(
                      isInCart ? Icons.check : Icons.add,
                      size: 13,
                      color: isInCart ? const Color(0xFF2563EB) : textMuted,
                    ),
                    label: Text(
                      p,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isInCart
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isInCart
                            ? const Color(0xFF2563EB)
                            : (isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A)),
                      ),
                    ),
                    onPressed: () {
                      if (isInCart) {
                        _confirmRemoveCartItem(p);
                      } else {
                        _addToCart(p);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_basket_outlined,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Aktif Sepet (${_cart.length} Ürün)",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_cart.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _triggerHaptic(HapticFeedback.selectionClick);
                              setState(() {
                                _cart.clear();
                                _recommendations.clear();
                              });
                            },
                            child: const Text(
                              "Sepeti Boşalt",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_cart.isEmpty)
                      Text(
                        "Sepetiniz boş. Yukarıdaki önerilerden seçin veya arama kutusundan ürün ekleyin.",
                        style: TextStyle(color: textMuted, fontSize: 11),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _cart.map((item) {
                          return Chip(
                            backgroundColor: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.12),
                            side: BorderSide.none,
                            deleteIcon: const Icon(Icons.close, size: 14),
                            deleteIconColor: const Color(0xFF2563EB),
                            onDeleted: () => _confirmRemoveCartItem(item),
                            label: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoadingRecs)
                const LinearProgressIndicator(
                  color: Color(0xFF2563EB),
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                ),

              if (_recommendations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tamamlayıcı Ürün Tavsiyeleri (Apriori)",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Tek tıkla sepete ekle",
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._recommendations.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.product,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Güven: %${(r.confidence * 100).toStringAsFixed(1)} • Lift: ${r.lift.toStringAsFixed(1)}x",
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () => _addToCart(r.product),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text(
                              "Ekle",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatIfSimulationCard(
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "WHAT-IF SENARYO SİMÜLATÖRÜ",
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Pazarlama aksiyonlarının sağlık skoru ve churn olasılığı üzerindeki etkisini anlık simüle edin.",
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sonraki Siparişe Kalan Süre:",
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
              Text(
                "${_simDays.toInt()} Gün",
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF2563EB),
              thumbColor: const Color(0xFF2563EB),
              inactiveTrackColor: borderColor,
              trackHeight: 2,
            ),
            child: Slider(
              value: _simDays,
              min: 1,
              max: 90,
              divisions: 89,
              onChanged: (val) {
                _triggerHaptic(HapticFeedback.selectionClick);
                setState(() {
                  _simDays = val;
                });
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Eklenecek Sipariş Sayısı:",
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
              Text(
                "+${_simOrders.toInt()} Sipariş",
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF10B981),
              thumbColor: const Color(0xFF10B981),
              inactiveTrackColor: borderColor,
              trackHeight: 2,
            ),
            child: Slider(
              value: _simOrders,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (val) {
                _triggerHaptic(HapticFeedback.selectionClick);
                setState(() {
                  _simOrders = val;
                });
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tahmini Ek Harcama:",
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
              Text(
                "£${_simSpend.toInt()}",
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFF59E0B),
              thumbColor: const Color(0xFFF59E0B),
              inactiveTrackColor: borderColor,
              trackHeight: 2,
            ),
            child: Slider(
              value: _simSpend,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (val) {
                _triggerHaptic(HapticFeedback.selectionClick);
                setState(() {
                  _simSpend = val;
                });
              },
            ),
          ),

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSimulating ? null : _runSimulation,
              child: _isSimulating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : const Text(
                      "Senaryoyu Test Et",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
            ),
          ),

          if (_simResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSimulationDeltaItem(
                        title: "Sağlık Skoru",
                        before: "${_simResult!.healthScore.current.toInt()}",
                        after: "${_simResult!.healthScore.simulated.toInt()}",
                        delta: _simResult!.healthScore.delta,
                        isHigherBetter: true,
                        unit: "/100",
                        textMuted: textMuted,
                        isDark: isDark,
                      ),
                      _buildSimulationDeltaItem(
                        title: "Churn Riski",
                        before: "%${_simResult!.churnProbabilityPct.current}",
                        after: "%${_simResult!.churnProbabilityPct.simulated}",
                        delta: _simResult!.churnProbabilityPct.delta,
                        isHigherBetter: false,
                        unit: "",
                        textMuted: textMuted,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF2563EB),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _simResult!.impactSummary,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimulationDeltaItem({
    required String title,
    required String before,
    required String after,
    required double delta,
    required bool isHigherBetter,
    required String unit,
    required Color textMuted,
    required bool isDark,
  }) {
    final isPositiveGood = isHigherBetter ? delta > 0 : delta < 0;
    final deltaColor = delta == 0
        ? textMuted
        : (isPositiveGood ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    final deltaText = delta > 0 ? "+$delta" : "$delta";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: textMuted, fontSize: 11)),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              "$before$unit",
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 11, color: textMuted),
            const SizedBox(width: 4),
            Text(
              "$after$unit",
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                deltaText,
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerHeaderCard(
    CustomerProfile cust,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Müşteri #${cust.customerId}",
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Segment: ${cust.segment.replaceAll('_', ' ').toUpperCase()}",
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Küme #${cust.kmeansCluster}",
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCol(
                "Son Ziyaret",
                "${cust.recency.toInt()} gün",
                "Skor: ${cust.rScore}/5",
                isDark,
              ),
              _buildMetricCol(
                "Sipariş Hacmi",
                "${cust.frequency.toInt()} adet",
                "Skor: ${cust.fScore}/5",
                isDark,
              ),
              _buildMetricCol(
                "Toplam Ciro",
                MetricFormatter.currency(cust.monetary),
                "Skor: ${cust.mScore}/5",
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardCard(
    CustomerScorecard sc,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final healthColor = _getHealthColor(sc.healthScore);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MÜŞTERİ SAĞLIK SKORU (CHS)",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: healthColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  sc.healthStatus,
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "${sc.healthScore}",
                style: TextStyle(
                  color: healthColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text("/100", style: TextStyle(color: textMuted, fontSize: 13)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildPercentileBar(
                      "Harcama Gücü",
                      sc.monetaryPercentile,
                      const Color(0xFF10B981),
                      borderColor,
                      isDark,
                    ),
                    const SizedBox(height: 4),
                    _buildPercentileBar(
                      "Sipariş Sıklığı",
                      sc.frequencyPercentile,
                      const Color(0xFF2563EB),
                      borderColor,
                      isDark,
                    ),
                    const SizedBox(height: 4),
                    _buildPercentileBar(
                      "Ziyaret Güncelliği",
                      sc.recencyPercentile,
                      const Color(0xFFF59E0B),
                      borderColor,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentileBar(
    String title,
    double pct,
    Color color,
    Color borderColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
            Text(
              "Üst %${(100 - pct).toStringAsFixed(0)}",
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPlanCard(
    PrescriptiveAction action,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    Color riskColor = const Color(0xFF2563EB);
    if (action.riskLevel.contains("Yüksek") ||
        action.riskLevel.contains("Kritik")) {
      riskColor = const Color(0xFFEF4444);
    } else if (action.riskLevel.contains("Orta")) {
      riskColor = const Color(0xFFF59E0B);
    }

    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF2563EB),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "ÖNERİLEN EYLEM PLANI",
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                "Risk: ${action.riskLevel}",
                style: TextStyle(
                  color: riskColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.actionTitle,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            action.actionDetail,
            style: TextStyle(color: textMuted, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.campaign_outlined, color: textMuted, size: 14),
              const SizedBox(width: 5),
              Text(
                "Önerilen Kanal: ${action.recommendedChannel}",
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, String sub, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
