enum Flavor {
  user,
  admin,
}

class FlavorConfig {
  final Flavor flavor;
  final String appTitle;
  final String initialRoute;

  static FlavorConfig? _instance;

  FlavorConfig._internal({
    required this.flavor,
    required this.appTitle,
    required this.initialRoute,
  });

  factory FlavorConfig({
    required Flavor flavor,
    required String appTitle,
    required String initialRoute,
  }) {
    _instance = FlavorConfig._internal(
      flavor: flavor,
      appTitle: appTitle,
      initialRoute: initialRoute,
    );
    return _instance!;
  }

  static FlavorConfig get instance {
    if (_instance == null) {
      throw FlutterError(
        'FlavorConfig.instance accessed before initialization. '
        'Call FlavorConfig() factory constructor first.',
      );
    }
    return _instance!;
  }

  static bool get isUser => instance.flavor == Flavor.user;
  static bool get isAdmin => instance.flavor == Flavor.admin;
}
