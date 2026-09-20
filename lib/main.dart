import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/committee_service.dart';
import 'models/models.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/organizer/organizer_home_screen.dart';
import 'screens/organizer/committee_detail_screen.dart';
import 'screens/organizer/add_member_screen.dart';
import 'screens/organizer/payment_entry_screen.dart';
import 'screens/member/member_home_screen.dart';
import 'screens/member/member_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  await authService.initialize();

  runApp(ComityApp(authService: authService));
}

class ComityApp extends StatelessWidget {
  final AuthService authService;

  const ComityApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<CommitteeService>(create: (_) => CommitteeService()),
      ],
      child: MaterialApp(
        title: 'Comity',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/otp': (_) => const OTPScreen(phoneNumber: ''),
          '/role-selection': (_) => const RoleSelectionScreen(phoneNumber: ''),
          '/organizer-home': (_) => const OrganizerHomeScreen(),
          '/member-home': (_) => const MemberHomeScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/otp':
              final args = settings.arguments as String;
              return MaterialPageRoute(builder: (_) => OTPScreen(phoneNumber: args));
            case '/role-selection':
              final args = settings.arguments as String;
              return MaterialPageRoute(builder: (_) => RoleSelectionScreen(phoneNumber: args));
            case '/committee-detail':
              final args = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => CommitteeDetailScreen(committeeId: args),
              );
            case '/member-detail':
              final args = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => MemberDetailScreen(membershipId: args),
              );
            case '/add-member':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => AddMemberScreen(committee: args['committee'] as Committee),
              );
            case '/payment-entry':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => PaymentEntryScreen(
                  committee: args['committee'] as Committee,
                  membership: args['membership'] as Membership,
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return StreamBuilder(
      stream: authService.currentUserStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        if (user.role == 'organizer') {
          return const OrganizerHomeScreen();
        } else {
          return const MemberHomeScreen();
        }
      },
    );
  }
}