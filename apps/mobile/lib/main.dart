import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'main_common.dart';
import 'core/flavor_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final flavor = appFlavor;
  
  if (flavor == 'admin') {
    FlavorConfig(
      flavor: Flavor.admin,
      appTitle: 'Premon Admin',
      initialRoute: '/admin-dashboard',
    );
  } else {
    // Default to user flavor
    FlavorConfig(
      flavor: Flavor.user,
      appTitle: 'Premon Care',
      initialRoute: '/',
    );
  }
  
  await mainCommon();
}
