import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('E-Commerce Intelligence smoke test', (
    WidgetTester tester,
  ) async {
    // Uygulamayı başlat ve ilk kareyi oluştur
    await tester.pumpWidget(const EcommerceIntelligenceApp());

    // Başlığın ekranda olduğunu doğrula
    expect(find.text('E-Commerce Intelligence Dashboard'), findsOneWidget);

    // Müşteri ID metin kutusunun yüklendiğini doğrula
    expect(find.text('Customer ID'), findsOneWidget);
  });
}
