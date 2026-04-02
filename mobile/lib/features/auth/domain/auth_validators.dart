class AuthValidators {
  const AuthValidators._();

  static String? required(String? value, {String message = 'Ce champ est requis'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    final requiredMessage = required(value, message: 'Veuillez entrer votre email');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final normalized = value!.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalized)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredMessage = required(
      value,
      message: 'Veuillez entrer votre mot de passe',
    );
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (value!.trim().length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caracteres';
    }
    return null;
  }

  static String? internationalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim();
    final phoneRegex = RegExp(r'^\+?[0-9 ()-]{6,20}$');
    if (!phoneRegex.hasMatch(normalized)) {
      return 'Veuillez entrer un numero international valide';
    }

    return null;
  }
}
