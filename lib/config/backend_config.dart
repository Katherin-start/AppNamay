class BackendConfig {
  static const String apiBaseUrl = 'http://10.0.2.2:4000/api';


  // Web / admin endpoints
  static const String adminLoginUrl = '$apiBaseUrl/auth/login';
  static const String adminRegisterUrl = '$apiBaseUrl/auth/register';

  // Mobile endpoints
  static const String mobileLoginUrl = '$apiBaseUrl/mobile/auth/login';
  static const String mobileRegisterUrl = '$apiBaseUrl/mobile/auth/register';

  // Defaults used by current mobile flows
  static const String loginUrl = mobileLoginUrl;
  static const String registerUrl = mobileRegisterUrl;
  static const String profileUrl = '$apiBaseUrl/mobile/profile';
  static const String odontologosUrl = '$apiBaseUrl/mobile/odontologos';
  static const String mobileDiscountsUrl = '$apiBaseUrl/mobile/discounts';
}
