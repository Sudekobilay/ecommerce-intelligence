import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/auth_models.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserSession) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'yonetici@pulsebi.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '••••••••',
  );
  UserRole _selectedRole = UserRole.executive;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    HapticFeedback.mediumImpact();
    final session = UserSession(
      email: _emailController.text.trim(),
      role: _selectedRole,
    );
    widget.onLoginSuccess(session);
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

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandPulseLogo(size: 64),
                const SizedBox(height: 16),
                Text(
                  'Pulse Intelligence Platform',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'E-Ticaret Karar Destek & Analitik Portalı',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.04,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OTURUM AÇMA TÜRÜ & ROL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rol Seçim Kutuları
                      ...UserRole.values.map((role) {
                        final isSelected = _selectedRole == role;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedRole = role;
                              if (role == UserRole.marketing) {
                                _emailController.text = 'pazarlama@pulsebi.com';
                              } else {
                                _emailController.text = 'yonetici@pulsebi.com';
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A)),
                                        ),
                                      ),
                                      Text(
                                        role.description,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Kurumsal E-Posta',
                          labelStyle: TextStyle(fontSize: 12, color: textMuted),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: TextStyle(fontSize: 12, color: textMuted),
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleLogin,
                          child: const Text(
                            'Giriş Yap ve Portala Geç',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
