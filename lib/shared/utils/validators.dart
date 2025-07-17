class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Campo requerido';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }
  // Agrega más validadores según necesidad
} 