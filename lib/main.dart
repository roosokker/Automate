import 'package:flutter/material.dart';
import 'screens/auth_wrapper.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/vehicle_details_screen.dart';
import 'screens/add_record_screen.dart';
import 'screens/reminder_details_screen.dart';
import 'theme/app_theme.dart';

import 'package:provider/provider.dart';
import 'providers/car_provider.dart';
import 'providers/specialist_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarProvider()),
        ChangeNotifierProvider(create: (_) => SpecialistProvider()),
      ],
      child: const MyCarEgyptApp(),
    ),
  );
}

class MyCarEgyptApp extends StatelessWidget {
  const MyCarEgyptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScaffold(),
        '/vehicle-details': (context) => const VehicleDetailsScreen(),
        '/add-vehicle': (context) => const AddVehicleScreen(),
        '/add-record': (context) => const AddRecordScreen(),
        '/reminder-details': (context) => const ReminderDetailsScreen(),
      },
    );
  }
}
