import 'main_common.dart';
import 'core/flavor_config.dart';

void main() {
  FlavorConfig(
    flavor: Flavor.user,
    appTitle: 'Premon Care',
    initialRoute: '/',
  );
  mainCommon();
}
