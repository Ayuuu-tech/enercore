import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/auth/splash_screen.dart';
import '../../features/auth/presentation/screens/auth/login_screen.dart';
import '../../features/auth/presentation/screens/auth/register_screen.dart';
import '../../features/auth/presentation/screens/auth/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/auth/role_selection_screen.dart';
import '../../features/auth/presentation/screens/onboarding/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/client_dashboard_screen.dart';
import '../../features/telemetry/presentation/screens/solar_grid_screen.dart';
import '../../features/telemetry/presentation/screens/telemetry_dashboard_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_home_screen.dart';
import '../../features/ticketing/presentation/screens/tickets_list_screen.dart';
import '../../features/ticketing/presentation/screens/create_ticket_screen.dart';
import '../../features/ticketing/presentation/screens/ticket_detail_screen.dart';
import '../../features/billing/presentation/screens/invoice_list_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/vendor/presentation/screens/vendor_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'user';
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/client-dashboard',
      builder: (context, state) => const ClientDashboardScreen(),
    ),
    GoRoute(
      path: '/solar-grid',
      builder: (context, state) => const SolarGridScreen(),
    ),
    GoRoute(
      path: '/telemetry',
      builder: (context, state) => const TelemetryDashboardScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const MarketplaceHomeScreen(),
    ),
    GoRoute(
      path: '/tickets',
      builder: (context, state) => const TicketsListScreen(),
    ),
    GoRoute(
      path: '/create-ticket',
      builder: (context, state) => const CreateTicketScreen(),
    ),
    GoRoute(
      path: '/ticket-detail',
      builder: (context, state) => const TicketsDetailScreen(),
    ),
    GoRoute(
      path: '/billing',
      builder: (context, state) => const InvoiceListScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/vendor-dashboard',
      builder: (context, state) => const VendorDashboardScreen(),
    ),
  ],
);
