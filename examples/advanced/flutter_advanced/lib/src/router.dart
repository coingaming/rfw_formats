import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_advanced/src/ui/gallery_page.dart';
import 'package:flutter_advanced/src/ui/login_page.dart';
import 'package:flutter_advanced/src/ui/scaffold_with_navbar.dart';
import 'package:flutter_advanced/src/ui/settings_page.dart';
import 'package:flutter_advanced/src/services/auth_service.dart';

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: "root");
  final AuthService _authService;
  List<RouteBase> _currentRoutes = [];
  List<Map<String, dynamic>> _routeConfigs = [];

  AppRouter(this._authService) {
    _currentRoutes = _initialRoutes;
  }

  late final routingConfig = ValueNotifier<RoutingConfig>(
    RoutingConfig(
      redirect: _handleRedirect,
      routes: _currentRoutes,
    ),
  );

  late final router = GoRouter.routingConfig(
    navigatorKey: rootNavigatorKey,
    initialLocation: _getInitialLocation(_currentRoutes),
    routingConfig: routingConfig,
  );

  String _getInitialLocation(List<RouteBase> routes) {
    return _getFirstShellRoutePath(routes) ?? LoginPage.path;
  }

  String? _getFirstShellRoutePath(List<RouteBase> routes) {
    for (final route in routes) {
      if (route is StatefulShellRoute) {
        for (final branch in route.branches) {
          if (branch.routes.isNotEmpty && branch.routes.first is GoRoute) {
            return (branch.routes.first as GoRoute).path;
          }
        }
      }
    }
    return null;
  }

  Future<String?> _handleRedirect(
      BuildContext context, GoRouterState state) async {
    final isAuthenticated = await _authService.isAuthenticated();
    final isLoginRoute = state.matchedLocation == LoginPage.path;

    if (!isAuthenticated && !isLoginRoute) {
      return LoginPage.path;
    }

    if (isAuthenticated && isLoginRoute) {
      return _getFirstShellRoutePath(_currentRoutes);
    }

    return null;
  }

  List<RouteBase> get _initialRoutes => [
        GoRoute(
          path: LoginPage.path,
          builder: (context, state) => const LoginPage(),
        ),
        _createShellRoute([]),
      ];

  StatefulShellRoute _createShellRoute(
      List<Map<String, dynamic>> dynamicRoutes) {
    final List<StatefulShellBranch> branches = [];

    // Add dynamic branches
    for (final config in dynamicRoutes) {
      if (config['isShellRoute'] == true) {
        final path = config['path'] as String;
        final subRoutes = config['routes'] as List<dynamic>?;

        branches.add(
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                builder: (context, state) => _buildPage(path),
                routes: subRoutes
                        ?.map((r) => _createRoute(r as Map<String, dynamic>))
                        .whereType<RouteBase>()
                        .toList() ??
                    [],
              ),
            ],
          ),
        );
      }
    }

    // Add settings branch
    branches.add(
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: SettingsPage.path,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    );

    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ScaffoldWithNavBar(
        navigationShell: navigationShell,
        routeConfigs: _routeConfigs,
      ),
      branches: branches,
    );
  }

  Widget _buildPage(String path) {
    if (path == '/counter') {
      return const GalleryPage();
    }
    return Placeholder(
      child: Center(
        child: Text('Page for path: $path'),
      ),
    );
  }

  RouteBase _createRoute(Map<String, dynamic> config) {
    final path = config['path'] as String;
    final subRoutes = config['routes'] as List<dynamic>?;

    return GoRoute(
      path: path,
      builder: (context, state) => _buildPage(path),
      routes: subRoutes
              ?.map((r) => _createRoute(r as Map<String, dynamic>))
              .whereType<RouteBase>()
              .toList() ??
          [],
    );
  }

  // Method to merge dynamic routes with existing configuration
  void mergeRoutingConfiguration(List<Map<String, dynamic>> dynamicRoutes) {
    _routeConfigs = dynamicRoutes;

    // Update current routes with new shell route that includes dynamic routes
    _currentRoutes = [
      GoRoute(
        path: LoginPage.path,
        builder: (context, state) => const LoginPage(),
      ),
      _createShellRoute(dynamicRoutes),
    ];

    routingConfig.value = RoutingConfig(
      redirect: _handleRedirect,
      routes: _currentRoutes,
    );
  }
}
