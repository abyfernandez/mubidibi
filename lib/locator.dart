import 'package:get_it/get_it.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/firestore_service.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<NavigationService>(() => NavigationService());
  locator.registerLazySingleton<DialogService>(() => DialogService());
  locator.registerLazySingleton<AuthenticationService>(
      () => AuthenticationService());
  locator.registerLazySingleton<FirestoreService>(() => FirestoreService());
}
