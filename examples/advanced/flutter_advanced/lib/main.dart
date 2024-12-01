import 'package:flutter/material.dart';
import 'package:flutter_advanced/src/gallery_page.dart';
import 'package:flutter_advanced/src/login_page.dart';
import 'package:flutter_advanced/src/scaffold_with_navbar.dart';
import 'package:flutter_advanced/src/services/auth_service.dart';
import 'package:flutter_advanced/src/settings_page.dart';
import 'package:flutter_advanced/src/todo_page.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: "root");
final _authService = AuthService();

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: TodosPage.path,
    redirect: (context, state) async {
      final isAuthenticated = await _authService.isAuthenticated();
      final isLoginRoute = state.matchedLocation == LoginPage.path;

      if (!isAuthenticated && !isLoginRoute) {
        return LoginPage.path;
      }

      if (isAuthenticated && isLoginRoute) {
        return TodosPage.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: LoginPage.path,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TodosPage.path,
                builder: (context, state) => const TodosPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: GalleryPage.path,
                builder: (context, state) => const GalleryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsPage.path,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Advanced RFW Example",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}
