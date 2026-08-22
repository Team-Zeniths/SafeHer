/// Static copy used across multiple screens.
///
/// Feature-specific strings live next to their screens; only text that
/// is reused or app-wide (branding, generic errors) belongs here.
class AppStrings {
  AppStrings._();

  static const String appName = 'SafeHer';
  static const String appTagline = 'Your safety, always within reach.';

  // Generic
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noInternet = 'No internet connection. Please check your network.';
  static const String requiredField = 'This field is required';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String loginSubtitle = 'Sign in to continue staying safe.';
  static const String createAccount = 'Create your account';
  static const String registerSubtitle = 'Join SafeHer and stay protected on the go.';
}
