import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/supabase_client_provider.dart';
import 'features/analitica/presentation/dashboard_page.dart';
import 'features/analitica/presentation/detalle_page.dart';
import 'features/analitica/presentation/mapa_page.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/desempeno/presentation/mis_consejos_page.dart';
import 'features/desempeno/presentation/ranking_page.dart';
import 'features/gestion/presentation/empleado_form_page.dart';
import 'features/gestion/presentation/empleados_list_page.dart';
import 'features/gestion/presentation/gestion_home_page.dart';
import 'features/gestion/presentation/supervisor_form_page.dart';
import 'features/gestion/presentation/supervisores_list_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/registro/presentation/captura_page.dart';
import 'features/registro/presentation/entrada_page.dart';
import 'features/registro/presentation/salida_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(currentSessionProvider);
  Widget _transitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade + slide up subtle transition
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: offset, child: child),
    );
  }

  CustomTransitionPage<T> _page<T>({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: _transitionBuilder,
    );
  }

  return GoRouter(
    initialLocation: session == null ? '/login' : '/home',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _page(child: const LoginPage(), state: state),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) =>
            _page(child: const HomePage(), state: state),
      ),
      // Top-level registro route (home for registro) to allow '/registro' navigation
      GoRoute(
        path: '/registro',
        name: 'registro',
        pageBuilder: (context, state) =>
            _page(child: const EntradaPage(), state: state),
      ),
      GoRoute(
        path: '/registro/captura',
        name: 'registro-captura',
        pageBuilder: (context, state) =>
            _page(child: const CapturaPage(), state: state),
      ),
      GoRoute(
        path: '/registro/entrada',
        name: 'registro-entrada',
        pageBuilder: (context, state) =>
            _page(child: const EntradaPage(), state: state),
      ),
      GoRoute(
        path: '/registro/salida',
        name: 'registro-salida',
        pageBuilder: (context, state) =>
            _page(child: const SalidaPage(), state: state),
      ),
      GoRoute(
        path: '/gestion',
        name: 'gestion',
        pageBuilder: (context, state) =>
            _page(child: const GestionHomePage(), state: state),
        routes: [
          GoRoute(
            path: 'empleados',
            name: 'gestion-empleados',
            pageBuilder: (context, state) =>
                _page(child: const EmpleadosListPage(), state: state),
            routes: [
              GoRoute(
                path: 'nuevo',
                name: 'empleado-nuevo',
                pageBuilder: (context, state) =>
                    _page(child: const EmpleadoFormPage(), state: state),
              ),
              GoRoute(
                path: ':id',
                name: 'empleado-detalle',
                pageBuilder: (context, state) => _page(
                  child: EmpleadoFormPage(
                    empleadoId: state.pathParameters['id'],
                  ),
                  state: state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'supervisores',
            name: 'gestion-supervisores',
            pageBuilder: (context, state) =>
                _page(child: const SupervisoresListPage(), state: state),
            routes: [
              GoRoute(
                path: 'nuevo',
                name: 'supervisor-nuevo',
                pageBuilder: (context, state) =>
                    _page(child: const SupervisorFormPage(), state: state),
              ),
              GoRoute(
                path: ':id',
                name: 'supervisor-detalle',
                pageBuilder: (context, state) => _page(
                  child: SupervisorFormPage(
                    supervisorId: state.pathParameters['id'],
                  ),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/analitica',
        name: 'analitica',
        pageBuilder: (context, state) =>
            _page(child: const DashboardPage(), state: state),
        routes: [
          GoRoute(
            path: 'mapa',
            name: 'analitica-mapa',
            pageBuilder: (context, state) =>
                _page(child: const MapaPage(), state: state),
          ),
          GoRoute(
            path: 'detalle',
            name: 'analitica-detalle',
            pageBuilder: (context, state) =>
                _page(child: const DetallePage(), state: state),
          ),
        ],
      ),
      GoRoute(
        path: '/desempeno',
        name: 'desempeno',
        pageBuilder: (context, state) =>
            _page(child: const RankingPage(), state: state),
        routes: [
          GoRoute(
            path: 'mis-consejos',
            name: 'mis-consejos',
            pageBuilder: (context, state) =>
                _page(child: const MisConsejosPage(), state: state),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: \'${state.uri}\'')),
    ),
  );
});
