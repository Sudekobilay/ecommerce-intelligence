import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/intelligence_models.dart';

void main() {
  runApp(const EcommerceIntelligenceApp());
}

class EcommerceIntelligenceApp extends StatelessWidget {
  const EcommerceIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _idController = TextEditingController(
    text: '12347',
  );
  CustomerProfile? _customer;
  bool _isLoadingCustomer = false;
  String? _customerError;

  final List<String> _cart = [];
  List<RecommendedItem> _recommendations = [];
  bool _isLoadingRecs = false;

  // Örnek ürün listesi
  final List<String> _sampleProducts = [
    "POPPY'S PLAYHOUSE KITCHEN",
    "POPPY'S PLAYHOUSE BEDROOM ",
    "GREEN REGENCY TEACUP AND SAUCER",
    "SET/10 BLUE SPOTTY PARTY CANDLES",
  ];

  void _searchCustomer() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;

    setState(() {
      _isLoadingCustomer = true;
      _customerError = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Commerce Intelligence Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BÖLÜM 1: MÜŞTERİ ANALİTİĞİ SORGULAMA
            const Text(
              "Müşteri Segmentasyonu & RFM Sorgu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Customer ID",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoadingCustomer ? null : _searchCustomer,
                  icon: const Icon(Icons.search),
                  label: const Text("Analiz Et"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingCustomer)
              const Center(child: CircularProgressIndicator()),
            if (_customerError != null)
              Text(_customerError!, style: const TextStyle(color: Colors.red)),
            if (_customer != null) ...[
              Card(
                elevation: 3,
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // main.dart içinde Card içindeki ilk Row kısmını şu şekilde güncelle:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Segment: ${_customer!.segment.toUpperCase()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text("Küme #${_customer!.kmeansCluster}"),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MetricBox(
                            label: "Recency",
                            value: "${_customer!.recency.toInt()} gün",
                          ),
                          _MetricBox(
                            label: "Frequency",
                            value: "${_customer!.frequency.toInt()} sipariş",
                          ),
                          _MetricBox(
                            label: "Monetary",
                            value: "£${_customer!.monetary.toStringAsFixed(1)}",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: 36),

            // BÖLÜM 2: SEPET VE APRIORI TAVSİYE MOTORU
            const Text(
              "Pazar Sepeti Analizi & Akıllı Öneri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sampleProducts.map((p) {
                final isInCart = _cart.contains(p);
                return ActionChip(
                  avatar: Icon(isInCart ? Icons.check : Icons.add),
                  label: Text(p, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _addToCart(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              "Mevcut Sepet: ${_cart.isEmpty ? 'Boş' : _cart.join(', ')}",
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            if (_isLoadingRecs) const LinearProgressIndicator(),
            if (_recommendations.isNotEmpty) ...[
              const Text(
                "Birlikte Sık Satın Alınanlar (Apriori Önerisi):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              ..._recommendations.map(
                (r) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.shopping_bag,
                      color: Colors.green,
                    ),
                    title: Text(
                      r.product,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Güven (Confidence): %${(r.confidence * 100).toStringAsFixed(1)}",
                    ),
                    trailing: Chip(
                      backgroundColor: Colors.green.shade100,
                      label: Text("Lift: ${r.lift.toStringAsFixed(1)}x"),
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
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
