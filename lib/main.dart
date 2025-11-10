// @dart=3.0
import 'package:classroom_mini/app/core/services/auth_service.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:ui' as ui show TextDirection;
import 'package:classroom_mini/app/core/bindings/core_binding.dart';
import 'package:classroom_mini/app/core/app_binding.dart';
import 'package:classroom_mini/app/routes/app_pages_responsive.dart';
import 'package:classroom_mini/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/modules/assignments/assignment_module.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- SharedPreferences Persistence Test --- START
  final prefs = await SharedPreferences.getInstance();
  final dummyValue = prefs.getString('dummy_test_key');
  debugPrint('[SharedPreferences Test] Dummy value on startup: $dummyValue');
  // --- SharedPreferences Persistence Test --- END

  await CoreBinding().init();

  await DioClient.initCache();

  // Initialize Flutter Gemini
  Gemini.init(
    apiKey: 'AIzaSyDL_BRhcT6Okr7rCIcHahMAQKfTYo6O3UY',
    disableAutoUpdateModelName: true,
  ); // Use the provided API key

  // Khởi tạo AppConfig và các dependencies toàn cục
  AppBinding().dependencies();

  // Register assignment module routes and bindings
  AssignmentModule.init();

  // Determine initial route from the single source of truth: AuthService
  final authService = Get.find<AuthService>();
  debugPrint(
      '[main] AuthService.isAuthenticated.value: ${authService.isAuthenticated.value}');
  final initialRoute =
      authService.isAuthenticated.value ? Routes.HOME : Routes.LOGIN;
  debugPrint('[main] Determined initialRoute: $initialRoute');

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Get.isRegistered<SyncService>()) {
      final syncService = Get.find<SyncService>();
      Future.delayed(const Duration(milliseconds: 500), () {
        syncService.syncQueue();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Classroom Mini',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      getPages: AppPages.routes,
      initialRoute: widget.initialRoute,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: child!,
          ),
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        );
      },
    );
  }
}
