import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/farmer_provider.dart';
import 'providers/consultation_provider.dart';
import 'providers/vet_provider.dart';
import 'providers/cooperative_provider.dart';
import 'providers/special_case_provider.dart';
import 'providers/statistics_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/farmer/farmer_dashboard.dart';
import 'screens/farmer/consult_vet_screen.dart';
import 'screens/farmer/education_screen.dart';
import 'screens/farmer/get_response_screen.dart';
import 'screens/farmer/farmer_profile_screen.dart';
import 'screens/vet/vet_dashboard.dart';
import 'screens/vet/consultations_screen.dart';
import 'screens/vet/reply_consultation_screen.dart';
import 'screens/vet/messages_screen.dart';
import 'screens/vet/vet_profile_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/farmers_management_screen.dart';
import 'screens/admin/veterinarians_management_screen.dart';
import 'screens/admin/cooperatives_screen.dart';
import 'screens/admin/special_cases_screen.dart';
import 'screens/admin/all_replies_screen.dart';
import 'screens/admin/statistics_screen.dart';
import 'services/storage/local_storage.dart';
import 'services/storage/secure_storage.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'screens/admin/admin_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await LocalStorage.init();
  await SecureStorage.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FarmerProvider()),
        ChangeNotifierProvider(create: (_) => ConsultationProvider()),
        ChangeNotifierProvider(create: (_) => VetProvider()),
        ChangeNotifierProvider(create: (_) => CooperativeProvider()),
        ChangeNotifierProvider(create: (_) => SpecialCaseProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

// GoRouter configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/role-select',
      name: 'roleSelect',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'farmer';
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'farmer';
        return RegisterScreen(role: role);
      },
    ),
    
    // Farmer Routes
    GoRoute(
      path: '/farmer-dashboard',
      name: 'farmerDashboard',
      builder: (context, state) => const FarmerDashboard(),
    ),
    GoRoute(
      path: '/consult-vet',
      name: 'consultVet',
      builder: (context, state) => const ConsultVetScreen(),
    ),
    GoRoute(
      path: '/education',
      name: 'education',
      builder: (context, state) => const EducationScreen(),
    ),
    GoRoute(
      path: '/get-response',
      name: 'getResponse',
      builder: (context, state) => const GetResponseScreen(),
    ),
    GoRoute(
      path: '/farmer-profile',
      name: 'farmerProfile',
      builder: (context, state) => const FarmerProfileScreen(),
    ),
    
    // Vet Routes
    GoRoute(
      path: '/vet-dashboard',
      name: 'vetDashboard',
      builder: (context, state) => const VetDashboard(),
    ),
    GoRoute(
      path: '/vet-consultations',
      name: 'vetConsultations',
      builder: (context, state) => const ConsultationsScreen(),
    ),
    GoRoute(
      path: '/vet-reply/:id',
      name: 'vetReply',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ReplyConsultationScreen(consultationId: id);
      },
    ),
    GoRoute(
      path: '/vet-messages',
      name: 'vetMessages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/vet-profile',
      name: 'vetProfile',
      builder: (context, state) => const VetProfileScreen(),
    ),
    
    // Admin Routes
    GoRoute(
      path: '/admin-dashboard',
      name: 'adminDashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/admin-farmers',
      name: 'adminFarmers',
      builder: (context, state) => const FarmersManagementScreen(),
    ),
    GoRoute(
      path: '/admin-vets',
      name: 'adminVets',
      builder: (context, state) => const VeterinariansManagementScreen(),
    ),
    GoRoute(
      path: '/admin-cooperatives',
      name: 'adminCooperatives',
      builder: (context, state) => const CooperativesScreen(),
    ),
    GoRoute(
      path: '/admin-special-cases',
      name: 'adminSpecialCases',
      builder: (context, state) => const SpecialCasesScreen(),
    ),
    GoRoute(
      path: '/admin-all-replies',
      name: 'adminAllReplies',
      builder: (context, state) => const AllRepliesScreen(),
    ),
    GoRoute(
      path: '/admin-statistics',
      name: 'adminStatistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    // Add this route in the admin section
    GoRoute(
      path: '/admin-profile',
      name: 'adminProfile',
      builder: (context, state) => const AdminProfileScreen(),
),
    
  ],
  
);