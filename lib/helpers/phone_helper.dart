// lib/helpers/phone_helper.dart
class PhoneHelper {
  /// Normaliza telefone para padrão internacional: +55XXXXXXXXXXX
  /// Recebe telefone no formato do usuário e retorna no padrão internacional
  static String normalizeToInternational(String phone, {String countryCode = '55'}) {
    if (phone.isEmpty) return '';

    // Remove tudo que não é número
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // Adiciona código do país se não tiver
    if (!digits.startsWith(countryCode)) {
      digits = '$countryCode$digits';
    }

    return '+$digits';
  }

  /// Valida se o telefone está no padrão internacional
  static bool isValidInternational(String phone) {
    final pattern = RegExp(r'^\+\d{10,15}$'); // +55XXXXXXXXXXX (mínimo 10 dígitos)
    return pattern.hasMatch(phone);
  }
}
