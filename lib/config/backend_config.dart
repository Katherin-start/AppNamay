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
  static String doctorDetailUrl(String doctorId) => '$apiBaseUrl/mobile/odontologos/$doctorId';
  static const String mobileDiscountsUrl = '$apiBaseUrl/mobile/discounts';

  // Mobile appointments endpoints
  static const String mobileAppointmentsUrl = '$apiBaseUrl/mobile/appointments';
  static String mobileAppointmentDetailUrl(String id) => '$apiBaseUrl/mobile/appointments/$id';
  static String mobileAppointmentPaymentUrl(String id) => '$apiBaseUrl/mobile/appointments/$id/payment';
  static String mobileAppointmentCancelUrl(String id) => '$apiBaseUrl/mobile/appointments/$id/cancel';
  static String mobileAppointmentProcessUrl(String id) => '$apiBaseUrl/mobile/appointments/$id/process';
  static String mobileAppointmentConfirmUrl(String id) => '$apiBaseUrl/mobile/appointments/$id/confirm';

  static String doctorReviewUrl(String doctorId) => '$apiBaseUrl/mobile/odontologos/$doctorId/reviews';

  // Clinical history
  static const String mobileClinicalHistoryUrl = '$apiBaseUrl/mobile/clinical-history';

  // Chat endpoints
  static const String mobileChatContactsUrl = '$apiBaseUrl/mobile/chat/contacts';
  static const String chatMessagesUrl = '$apiBaseUrl/chat/messages';
  static String chatHistoryUrl(String userId) => '$apiBaseUrl/chat/messages/$userId';
  static const String chatMarkReadUrl = '$apiBaseUrl/chat/messages/mark-as-read';
  static const String chatUnreadCountUrl = '$apiBaseUrl/chat/unread-count';
}
