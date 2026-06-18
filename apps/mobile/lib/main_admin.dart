import 'main_common.dart';
import 'core/flavor_config.dart';

void main() {
  FlavorConfig(
    flavor: Flavor.admin,
    appTitle: 'Premon Admin',
    initialRoute: '/admin-login',
  );
  mainCommon();
}
