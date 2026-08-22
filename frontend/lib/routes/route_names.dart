/// Central registry of route paths and names.
///
/// Keeping these as constants avoids typo-prone magic strings when
/// calling `context.go(...)` / `context.push(...)` throughout the app.
class RouteNames {
  RouteNames._();

  // Auth flow
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';


  // Shell (bottom nav root)
  static const String shell = '/';

  // Main tabs (children of shell)
  static const String home = '/home';
  static const String journey = '/journey';
  static const String emergency = '/emergency';
  static const String community = '/community';
  static const String profile = '/profile';

  // Emergency sub-routes
  static const String sos = '/sos';
  static const String siren = '/siren';
  static const String incidentReport = '/incident-report';
  static const String emergencyHistory = '/emergency-history';

  // Journey sub-routes
  static const String journeyActive = '/journey/active';
  static const String journeyHistory = '/journey/history';
  static const String journeyShare = '/journey/share';

  // Contacts sub-routes
  static const String contacts = '/contacts';
  static const String addContact = '/contacts/add';
  static const String editContact = '/contacts/edit';

  // Community sub-routes
  static const String createPost = '/community/create';
  static const String postDetail = '/community/post';
  static const String nearbyAlerts = '/community/nearby';

  // AI Assistant
  static const String aiAssistant = '/ai';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notifications/detail';

  // History
  static const String history = '/history';

  // Profile sub-routes
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String privacySettings = '/settings/privacy';
  static const String securitySettings = '/settings/security';
  static const String about = '/about';
}
