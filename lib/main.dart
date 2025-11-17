import 'dart:io';
import 'package:get/get.dart';
import 'package:stelacom_check/controllers/appstate_controller.dart';
import 'package:stelacom_check/no_permisisons.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();
List<CameraDescription> cameras = <CameraDescription>[];

class PostHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> clearAppCache() async {
  try {
    // Clear external cache
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }

    // Clear external storage files
    final appDir = await getApplicationDocumentsDirectory();
    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }

    // 3️⃣ Clear application support directory (extra stored files)
    final supportDir = await getApplicationSupportDirectory();
    if (supportDir.existsSync()) {
      supportDir.deleteSync(recursive: true);
    }
    print("Cache Cleared!");
  } catch (e) {
    print("Error clearing cache: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clearAppCache(); // Ensures old cache is cleared before launching app
  Get.put(AppStateController());

  // await Firebase.initializeApp();
  // await FirebaseApi().initNotifications();

  cameras = await availableCameras();

  Map<Permission, PermissionStatus> permissions = await [
    Permission.camera,
    Permission.location,
  ].request();

  HttpOverrides.global = new PostHttpOverrides();

  if ((permissions[Permission.camera] == PermissionStatus.granted ||
          permissions[Permission.camera] == PermissionStatus.restricted ||
          permissions[Permission.camera] ==
              PermissionStatus.permanentlyDenied) &&
      (permissions[Permission.location] == PermissionStatus.granted ||
          permissions[Permission.location] == PermissionStatus.restricted ||
          permissions[Permission.location] ==
              PermissionStatus.permanentlyDenied)) {
    SharedPreferences storage = await SharedPreferences.getInstance();

    runApp(MyApp(storage));
  } else {
    runApp(NoPermissionGranted());
  }
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  SharedPreferences storage;
  MyApp(this.storage);
  @override
  Widget build(BuildContext context) {
    String? employeeCode = storage.getString('employee_code');
    bool? isGoToHomeScreen = storage.getBool('userInHomeScreen');

    if (employeeCode == null || employeeCode == '') {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ICheck',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: CodeVerificationScreen(),
      );
    } else if (isGoToHomeScreen == false || isGoToHomeScreen == null) {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ICheck',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: CodeVerificationScreen(),
      );
    } else {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ICheck',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(index2: 0),
      );
    }
  }
}
