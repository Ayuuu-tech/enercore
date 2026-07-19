import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/auth/splash_screen.dart';
import '../../features/auth/presentation/screens/auth/login_screen.dart';
import '../../features/auth/presentation/screens/auth/register_screen.dart';
import '../../features/auth/presentation/screens/auth/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/onboarding/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/client_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/alerts_screen.dart';
import '../../features/telemetry/presentation/screens/alarms_screen.dart';
import '../../features/telemetry/presentation/screens/solar_grid_screen.dart';
import '../../features/telemetry/presentation/screens/telemetry_dashboard_screen.dart';
import '../../features/telemetry/presentation/screens/reports_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_home_screen.dart';
import '../../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../../features/marketplace/presentation/screens/cart_screen.dart';
import '../../features/ticketing/presentation/screens/tickets_list_screen.dart';
import '../../features/ticketing/presentation/screens/create_ticket_screen.dart';
import '../../features/ticketing/presentation/screens/ticket_detail_screen.dart';
import '../../features/billing/presentation/screens/invoice_list_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_subscriptions_screen.dart';
import '../../features/admin/presentation/screens/admin_plants_screen.dart';
import '../../features/admin/presentation/screens/admin_audit_screen.dart';
import '../../features/admin/presentation/screens/admin_tickets_screen.dart';
import '../../features/admin/presentation/screens/admin_features_screen.dart';
import '../../features/admin/presentation/screens/admin_branding_screen.dart';
import '../../features/vendor/presentation/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/presentation/screens/vendor_products_screen.dart';
import '../../features/vendor/presentation/screens/vendor_add_product_screen.dart';
import '../../features/vendor/presentation/screens/vendor_orders_screen.dart';
import '../../features/vendor/presentation/screens/vendor_store_screen.dart';
import '../../features/vendor/presentation/screens/vendor_kyc_screen.dart';
import '../../features/admin/presentation/screens/admin_kyc_screen.dart';
import '../../features/vendor/domain/vendor_models.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';

final _authRoutes = <String>{
  '/splash', '/onboarding', '/login', '/register', '/forgot-password',
};

// Client feature routes gated by per-user module permissions. Admins bypass.
const _routeModule = <String, String>{
  '/solar-grid': 'plants',
  '/telemetry': 'telemetry',
  '/alarms': 'telemetry',
  '/reports': 'reports',
  '/billing': 'billing',
  '/tickets': 'tickets',
  '/create-ticket': 'tickets',
  '/ticket-detail': 'tickets',
  '/marketplace': 'marketplace',
  '/product-detail': 'marketplace',
  '/cart': 'marketplace',
  '/notifications': 'notifications',
};

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<dynamic>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authStateValue = ref.read(authControllerProvider);
      if (authStateValue.isLoading || authStateValue.isRefreshing) return null;

      final user = authStateValue.asData?.value;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(location);

      if (!isLoggedIn && !isAuthRoute) return '/splash';
      if (isLoggedIn && isAuthRoute) {
        final role = user.role.toUpperCase();
        if (role == 'ADMIN') return '/admin-dashboard';
        if (role == 'VENDOR') return '/vendor-dashboard';
        return '/client-dashboard';
      }
      // Module gating: non-admins can't open a feature they lack access to.
      if (isLoggedIn && user.role.toUpperCase() != 'ADMIN') {
        final requiredModule = _routeModule[location];
        if (requiredModule != null && !user.canAccess(requiredModule)) {
          return '/client-dashboard';
        }
      }
      return null;
    },
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
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin-users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/admin-subscriptions',
      builder: (context, state) => const AdminSubscriptionsScreen(),
    ),
    GoRoute(
      path: '/admin-plants',
      builder: (context, state) => const AdminPlantsScreen(),
    ),
    GoRoute(
      path: '/admin-audit',
      builder: (context, state) => const AdminAuditScreen(),
    ),
    GoRoute(
      path: '/vendor-kyc',
      builder: (context, state) => const VendorKycScreen(),
    ),
    GoRoute(
      path: '/admin-kyc',
      builder: (context, state) => const AdminKycScreen(),
    ),
    GoRoute(
      path: '/admin-tickets',
      builder: (context, state) => const AdminTicketsScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/alarms',
      builder: (context, state) => const AlarmsScreen(),
    ),
    GoRoute(
      path: '/admin-features',
      builder: (context, state) => const AdminFeaturesScreen(),
    ),
    GoRoute(
      path: '/admin-branding',
      builder: (context, state) => const AdminBrandingScreen(),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const MarketplaceHomeScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/product-detail',
      builder: (context, state) => ProductDetailScreen(productId: state.extra as String?),
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
      builder: (context, state) {
        final ticketId = state.uri.queryParameters['id'] ?? '';
        return TicketsDetailScreen(ticketId: ticketId);
      },
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
    GoRoute(
      path: '/vendor-products',
      builder: (context, state) => const VendorProductsScreen(),
    ),
    GoRoute(
      path: '/vendor-add-product',
      builder: (context, state) {
        final existing = state.extra is VendorProductModel ? state.extra as VendorProductModel : null;
        return VendorAddProductScreen(existing: existing);
      },
    ),
    GoRoute(
      path: '/vendor-orders',
      builder: (context, state) => const VendorOrdersScreen(),
    ),
    GoRoute(
      path: '/vendor-store',
      builder: (context, state) => const VendorStoreScreen(),
    ),
  ],
  );
});
