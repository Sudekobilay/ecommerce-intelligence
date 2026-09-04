import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/intelligence_models.dart';
import '../utils/formatters.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() =>
      _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  final TextEditingController _idController = TextEditingController(
    text: '12347',
  );
  CustomerProfile? _customer;
  bool _isLoadingCustomer = false;
  String? _customerError;

  // --- GÜN 13: WHAT-IF SİMÜLASYON STATE'LERİ ---
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
    "POPPY'S PLAYHOUSE BEDROOM ",
    "GREEN REGENCY TEACUP AND SAUCER",
    "SET/10 BLUE SPOTTY PARTY CANDLES",
  ];

  @override
  void initState() {
    super.initState();
    _searchCustomer();
  }

  void _searchCustomer() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;

    setState(() {
      _isLoadingCustomer = true;
      _customerError = null;
      _simResult =
          null; // Yeni arama yapıldığında eski simülasyon sonucunu sıfırla
    });

    try {
      final res = await ApiService.fetchCustomerProfile(id);
      setState(() {
        _customer = res;
        if (res == null) _customerError = "Müşteri bulunamadı.";
      });
    } catch (e) {
      setState(() => _customerError = "HATA: $e");
    } finally {
      setState(() => _isLoadingCustomer = false);
    }
  }

  void _runSimulation() async {
    if (_customer == null) return;

    setState(() => _isSimulating = true);

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
            backgroundColor: Colors.redAccent,
            content: Text('Simülasyon motoru hatası: $e'),
          ),
        );
      }
    } finally {
      setState(() => _isSimulating = false);
    }
  }

  void _addToCart(String product) {
    if (!_cart.contains(product)) {
      setState(() => _cart.add(product));
      _getRecommendations();
    }
  }

  void _getRecommendations() async {
    if (_cart.isEmpty) return;
    setState(() => _isLoadingRecs = true);
    try {
      final recs = await ApiService.fetchRecommendations(_cart);
      setState(() => _recommendations = recs);
    } catch (_) {
    } finally {
      setState(() => _isLoadingRecs = false);
    }
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.person_search_rounded, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text(
              'Customer Intelligence & Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Müşteri Numarası (Customer ID)",
                      labelStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _isLoadingCustomer ? null : _searchCustomer,
                  icon: const Icon(Icons.search),
                  label: const Text(
                    "Analiz Et",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingCustomer)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
              ),

            if (_customerError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(
                  _customerError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            if (_customer != null) ...[
              _buildCustomerHeaderCard(_customer!),
              const SizedBox(height: 16),
              if (_customer!.scorecard != null)
                _buildScorecardCard(_customer!.scorecard!),
              const SizedBox(height: 16),
              if (_customer!.actionPlan != null)
                _buildActionPlanCard(_customer!.actionPlan!),
              const SizedBox(height: 16),
              // --- GÜN 13 SIMÜLATÖR BİLEŞENİ ---
              _buildWhatIfSimulationCard(),
            ],

            const Divider(height: 40, color: Colors.white10),

            const Text(
              "SEPET BİRLİKTELİK ANALİZİ & APRIORI MOTORU",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sampleProducts.map((p) {
                final isInCart = _cart.contains(p);
                return ActionChip(
                  backgroundColor: isInCart
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : const Color(0xFF1E293B),
                  side: BorderSide(
                    color: isInCart ? Colors.cyanAccent : Colors.white24,
                  ),
                  avatar: Icon(
                    isInCart ? Icons.check : Icons.add,
                    size: 16,
                    color: isInCart ? Colors.cyanAccent : Colors.white70,
                  ),
                  label: Text(
                    p,
                    style: TextStyle(
                      fontSize: 11,
                      color: isInCart ? Colors.cyanAccent : Colors.white,
                    ),
                  ),
                  onPressed: () => _addToCart(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              "Mevcut Sepet: ${_cart.isEmpty ? 'Boş' : _cart.join(', ')}",
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingRecs)
              const LinearProgressIndicator(color: Colors.cyanAccent),
            if (_recommendations.isNotEmpty) ...[
              const Text(
                "Birlikte Sık Satın Alınanlar (Apriori Önerisi):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ..._recommendations.map(
                (r) => Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.shopping_bag,
                      color: Colors.greenAccent,
                    ),
                    title: Text(
                      r.product,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "Güven: %${(r.confidence * 100).toStringAsFixed(1)}",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Chip(
                      backgroundColor: Colors.greenAccent.withValues(
                        alpha: 0.15,
                      ),
                      label: Text(
                        "Lift: ${r.lift.toStringAsFixed(1)}x",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhatIfSimulationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: Colors.cyanAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "WHAT-IF SENARYO SİMÜLATÖRÜ",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Pazarlama aksiyonlarının sağlık skoru ve churn olasılığı üzerindeki etkisini öngörün.",
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Slider 1: Gün
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sonraki Siparişe Kalan Süre:",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "${_simDays.toInt()} Gün",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              thumbColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white12,
            ),
            child: Slider(
              value: _simDays,
              min: 1,
              max: 90,
              divisions: 89,
              onChanged: (val) => setState(() => _simDays = val),
            ),
          ),

          // Slider 2: Sipariş
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Eklenecek Sipariş Sayısı:",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "+${_simOrders.toInt()} Sipariş",
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF34D399),
              thumbColor: const Color(0xFF34D399),
              inactiveTrackColor: Colors.white12,
            ),
            child: Slider(
              value: _simOrders,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (val) => setState(() => _simOrders = val),
            ),
          ),

          // Slider 3: Harcama
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tahmini Ek Harcama:",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "£${_simSpend.toInt()}",
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFBBF24),
              thumbColor: const Color(0xFFFBBF24),
              inactiveTrackColor: Colors.white12,
            ),
            child: Slider(
              value: _simSpend,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (val) => setState(() => _simSpend = val),
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isSimulating ? null : _runSimulation,
              icon: _isSimulating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                _isSimulating ? "Simüle Ediliyor..." : "Senaryoyu Simüle Et",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (_simResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSimulationDeltaItem(
                        title: "Müşteri Sağlık Skoru",
                        before: "${_simResult!.healthScore.current.toInt()}",
                        after: "${_simResult!.healthScore.simulated.toInt()}",
                        delta: _simResult!.healthScore.delta,
                        isHigherBetter: true,
                        unit: "/100",
                      ),
                      _buildSimulationDeltaItem(
                        title: "Churn (Kayıp) Olasılığı",
                        before: "%${_simResult!.churnProbabilityPct.current}",
                        after: "%${_simResult!.churnProbabilityPct.simulated}",
                        delta: _simResult!.churnProbabilityPct.delta,
                        isHigherBetter: false,
                        unit: "",
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.white10),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.cyanAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _simResult!.impactSummary,
                          style: const TextStyle(
                            color: Colors.white70,
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
  }) {
    final isPositiveGood = isHigherBetter ? delta > 0 : delta < 0;
    final deltaColor = delta == 0
        ? Colors.white54
        : (isPositiveGood ? const Color(0xFF34D399) : const Color(0xFFF87171));

    final deltaText = delta > 0 ? "+$delta" : "$delta";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "$before$unit",
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              "$after$unit",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                deltaText,
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerHeaderCard(CustomerProfile cust) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Segment: ${cust.segment.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Chip(
                backgroundColor: Colors.white10,
                side: BorderSide.none,
                label: Text(
                  "Küme #${cust.kmeansCluster}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCol(
                "Recency",
                "${cust.recency.toInt()} gün",
                "(Skor: ${cust.rScore}/5)",
              ),
              _buildMetricCol(
                "Frequency",
                "${cust.frequency.toInt()} sipariş",
                "(Skor: ${cust.fScore}/5)",
              ),
              _buildMetricCol(
                "Monetary",
                MetricFormatter.currency(cust.monetary),
                "(Skor: ${cust.mScore}/5)",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardCard(CustomerScorecard sc) {
    final healthColor = _getHealthColor(sc.healthScore);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MÜŞTERİ SAĞLIK SKORU (CHS)",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sc.healthStatus,
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "/100",
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildPercentileBar(
                      "Harcama Gücü",
                      sc.monetaryPercentile,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    _buildPercentileBar(
                      "Sipariş Sıklığı",
                      sc.frequencyPercentile,
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 6),
                    _buildPercentileBar(
                      "Ziyaret Güncelliği",
                      sc.recencyPercentile,
                      const Color(0xFFF59E0B),
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

  Widget _buildPercentileBar(String title, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            Text(
              "Üst %${(100 - pct).toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPlanCard(PrescriptiveAction action) {
    Color riskColor = Colors.blueAccent;
    if (action.riskLevel.contains("Yüksek") ||
        action.riskLevel.contains("Kritik")) {
      riskColor = Colors.redAccent;
    } else if (action.riskLevel.contains("Orta")) {
      riskColor = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text(
                "REÇETELİ EYLEM PLANI",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "Risk: ${action.riskLevel}",
                style: TextStyle(
                  color: riskColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action.actionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.actionDetail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Önerilen Kanal: ${action.recommendedChannel}",
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, String sub) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
        ),
      ],
    );
  }
}
