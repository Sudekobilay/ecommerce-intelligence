import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../models/intelligence_models.dart';

class ApiService {
  // Canlı Render PaaS backend URL'i
  static const String baseUrl =
      'https://ecommerce-intelligence-8juv.onrender.com';

  /// Gün 11: Makro KPI'lar, Segment Dağılımı ve Otomatik İş İçgörüleri
  static Future<Map<String, dynamic>> getOverviewAnalytics() async {
    final url = Uri.parse('$baseUrl/api/v1/analytics/overview');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        throw Exception(
          'Makro analitik verileri alınamadı (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Bulut sunucu bağlantı hatası (Cold-start olabilir): $e');
    }
  }

  /// Müşteri RFM ve Segment Detayı
  static Future<CustomerProfile?> fetchCustomerProfile(int customerId) async {
    final url = Uri.parse('$baseUrl/api/v1/customer/$customerId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return CustomerProfile.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Apriori Pazar Sepeti Tavsiyeleri
  static Future<List<RecommendedItem>> fetchRecommendations(
    List<String> items,
  ) async {
    final url = Uri.parse('$baseUrl/api/v1/recommendations');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': items, 'top_n': 3}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data['recommendations'] as List;
        return list.map((item) => RecommendedItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Tavsiye servisi hatası: $e');
    }
  }

  /// Gün 13: What-If Churn Simülasyonu
  static Future<SimulationResult> simulateCustomer({
    required int customerId,
    required int daysToNextOrder,
    required int additionalOrders,
    required double additionalSpend,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/customer/$customerId/simulate');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'days_to_next_order': daysToNextOrder,
        'additional_orders': additionalOrders,
        'additional_spend': additionalSpend,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      return SimulationResult.fromJson(data);
    } else {
      throw Exception(
        'Simülasyon motoru hatası (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Gün 14: Kohort Retention Matrisi Verisi
  static Future<CohortMatrixData> fetchCohortMatrix() async {
    final url = Uri.parse('$baseUrl/api/v1/analytics/cohort');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return CohortMatrixData.fromJson(data);
      } else {
        throw Exception('Kohort verisi alınamadı: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kohort servisi bağlantı hatası: $e');
    }
  }

  /// Gün 14: Segment Müşteri CSV İhracı (Doğrudan Tarayıcı İndirmesi)
  static void exportSegmentCsv(String segmentName) {
    final cleanName = segmentName.toLowerCase().replaceAll(' ', '_');
    final url = '$baseUrl/api/v1/segments/$cleanName/export';

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = 'audience_$cleanName.csv';
    anchor.target = '_blank';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }
}
