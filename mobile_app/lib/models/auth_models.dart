enum UserRole {
  executive(
    'Yönetici (C-Level)',
    'Tüm makro finansal KPI ve kitle ihracına tam erişim.',
  ),
  marketing(
    'Pazarlama Uzmanı',
    'Müşteri 360°, sepet birlikteliği ve reçeteli aksiyonlara erişim.',
  );

  final String label;
  final String description;
  const UserRole(this.label, this.description);
}

class UserSession {
  final String email;
  final UserRole role;

  const UserSession({required this.email, required this.role});
}
