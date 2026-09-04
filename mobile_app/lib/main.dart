import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/auth_models.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customer_analytics_screen.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EcommerceIntelligenceApp());
}

class EcommerceIntelligenceApp extends StatefulWidget {
  const EcommerceIntelligenceApp({super.key});

  @override
  State<EcommerceIntelligenceApp> createState() =>
      _EcommerceIntelligenceAppState();
}

class _EcommerceIntelligenceAppState extends State<EcommerceIntelligenceApp>
    with SingleTickerProviderStateMixin {
  UserSession? _currentSession;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.08), // Hafif aşağıdan yukarı süzülme efekti
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _transitionController,
            curve: Curves.easeOutCubic,
          ),
        );

    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _handleLoginSuccess(UserSession session) {
    setState(() {
      _currentSession = session;
    });
    _transitionController.forward(from: 0.0);
  }

  void _handleLogout() {
    setState(() {
      _currentSession = null;
    });
    _transitionController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Pulse BI',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFBF9F5),
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
              outline: Color(0xFFE5E0D8),
            ),
            dividerColor: const Color(0xFFE5E0D8),
            fontFamily: 'Segoe UI',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            cardColor: const Color(0xFF1E293B),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF1E293B),
              onSurface: Color(0xFFF8FAFC),
              outline: Color(0xFF334155),
            ),
            dividerColor: const Color(0xFF334155),
            fontFamily: 'Segoe UI',
          ),
          home: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _currentSession == null
                  ? LoginScreen(onLoginSuccess: _handleLoginSuccess)
                  : MainNavigationScreen(
                      session: _currentSession!,
                      onLogout: _handleLogout,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _triggerHaptic(void Function() action) {
    if (!kIsWeb) {
      try {
        action();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExecutive = widget.session.role == UserRole.executive;

    final List<Widget> accessibleScreens = [
      if (isExecutive) DashboardScreen(onLogout: widget.onLogout),
      CustomerAnalyticsScreen(onLogout: widget.onLogout),
    ];

    if (!isExecutive) {
      return Scaffold(body: accessibleScreens[0]);
    }

    final List<NavigationDestination> destinations = const [
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF2563EB)),
        label: 'Executive Cockpit',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_search_outlined),
        selectedIcon: Icon(
          Icons.person_search_rounded,
          color: Color(0xFF2563EB),
        ),
        label: 'Müşteri 360°',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < accessibleScreens.length ? _currentIndex : 0,
        children: accessibleScreens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFBF9F5),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E0D8),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex < accessibleScreens.length
                ? _currentIndex
                : 0,
            onDestinationSelected: (idx) {
              _triggerHaptic(HapticFeedback.selectionClick);
              setState(() {
                _currentIndex = idx;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 62,
            indicatorColor: isDark
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : const Color(0xFF2563EB).withValues(alpha: 0.1),
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}

class BrandPulseLogo extends StatelessWidget {
  final double size;
  const BrandPulseLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _BrandLogoPainter());
  }
}

class _BrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.28),
    );

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    final barPaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1;

    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.65)
      ..lineTo(size.width * 0.44, size.height * 0.40)
      ..lineTo(size.width * 0.60, size.height * 0.55)
      ..lineTo(size.width * 0.78, size.height * 0.28);
    canvas.drawPath(path, barPaint);

    final dotPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.28),
      size.width * 0.08,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
