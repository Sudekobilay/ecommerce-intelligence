import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intelligence_models.dart';

class ApiService {
  // Windows/Web için 127.0.0.1, Android Emülatör için 10.0.2.2 kullan(termınalde ipconfig yazdık ve wıreless lan adapter baglantısı pıv4 adresını aldık(bıglısayar ve telefon aynı wıfıye baglı olmalıdır))
  static const String baseUrl =
      'https://ecommerce-intelligence-8juv.onrender.com';

  static Future<CustomerProfile?> fetchCustomerProfile(int customerId) async {
    final url = Uri.parse('$baseUrl/api/v1/customer/$customerId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return CustomerProfile.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

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
        final data = jsonDecode(response.body);
        final list = data['recommendations'] as List;
        return list.map((item) => RecommendedItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Tavsiye servisi hatası: $e');
    }
  }
}
