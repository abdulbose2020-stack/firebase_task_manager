
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'providers/task_provider.dart';
import 'services/task_service.dart';
import 'repositories/task_repository.dart';

const Color primaryNavy = Color(0xFF172B4D);
const Color secondaryNavy = Color(0xFF243F68);
const Color backgroundColor = Color(0xFFF5F7FB);
const Color textColor = Color(0xFF172B4D);
const Color mutedTextColor = Color(0xFF8993A4);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<TaskService>(
          create: (_) => TaskService(),
        ),
        Provider<TaskRepository>(
          create: (context) => TaskRepository(
            taskService: context.read<TaskService>(),
          ),
        ),
        ChangeNotifierProvider<TaskProvider>(
          create: (context) => TaskProvider(
            taskRepository: context.read<TaskRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Task Manager',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          brightness: Brightness.light,
          primary: primaryNavy,
          secondary: secondaryNavy,
          surface: Colors.white,
        ),

        scaffoldBackgroundColor: backgroundColor,

        fontFamily: 'Roboto',

        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: primaryNavy,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F8FA),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E9F0),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E9F0),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryNavy,
              width: 1.5,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.redAccent,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),

          labelStyle: const TextStyle(
            color: mutedTextColor,
          ),

          prefixIconColor: mutedTextColor,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}
