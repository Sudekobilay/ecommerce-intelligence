import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/intelligence_models.dart';
import '../models/auth_models.dart'; // UserSession ve UserRole için eklendi

class ApiService {
  // Canlı Render PaaS backend URL'i
  static const String baseUrl =
      'https://ecommerce-intelligence-8juv.onrender.com';

  /// Gün 15: Backend tabanlı kurumsal kimlik doğrulama (Login)
  static Future<UserSession> login(
    String email,
    String password,
    UserRole role,
  ) async {
    final roleStr = role == UserRole.executive ? 'executive' : 'marketing';
    final url = Uri.parse('$baseUrl/api/v1/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': roleStr,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserSession(
          email: data['email'],
          role: data['role'] == 'executive'
              ? UserRole.executive
              : UserRole.marketing,
        );
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorData['detail'] ?? 'Kimlik doğrulama başarısız oldu.',
        );
      }
    } catch (e) {
      throw Exception('Giriş servisi bağlantı hatası: $e');
    }
  }

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

  /// Dinamik/Canlı Hızlı Ürün Havuzu (Backend Entegrasyonlu)
  static Future<List<String>> fetchRandomProductsPool() async {
    final url = Uri.parse('$baseUrl/api/v1/products/random-pool');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => item.toString()).toList();
      }
    } catch (_) {}

    // Fallback/Yedek statik liste (Sunucu yanıt vermezse)
    return [
      "POPPY'S PLAYHOUSE KITCHEN",
      "POPPY'S PLAYHOUSE BEDROOM",
      "GREEN REGENCY TEACUP AND SAUCER",
      "SET/10 BLUE SPOTTY PARTY CANDLES",
      "JUMBO BAG RED RETROSPOT",
      "WHITE HANGING HEART T-LIGHT HOLDER",
      "REGENCY CAKESTAND 3 TIER",
      "HEART OF WICKER SMALL",
      "JUMBO STORAGE BAG SKULL",
      "PACK OF 72 RETRO SPOT CAKE CASES",
    ];
  }

  /// Gün 14: Segment Müşteri CSV İhracı (url_launcher kullanarak platform bağımsız güvenli indirme)
  static Future<void> exportSegmentCsv(String segmentName) async {
    final cleanName = segmentName.toLowerCase().replaceAll(' ', '_');
    final url = Uri.parse('$baseUrl/api/v1/segments/$cleanName/export');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
