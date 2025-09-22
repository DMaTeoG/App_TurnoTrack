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

  return GoRouter(
    initialLocation: session == null ? '/login' : '/home',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/registro/captura',
        name: 'registro-captura',
        builder: (context, state) => const CapturaPage(),
      ),
      GoRoute(
        path: '/registro/entrada',
        name: 'registro-entrada',
        builder: (context, state) => const EntradaPage(),
      ),
      GoRoute(
        path: '/registro/salida',
        name: 'registro-salida',
        builder: (context, state) => const SalidaPage(),
      ),
      GoRoute(
        path: '/gestion',
        name: 'gestion',
        builder: (context, state) => const GestionHomePage(),
        routes: [
          GoRoute(
            path: 'empleados',
            name: 'gestion-empleados',
            builder: (context, state) => const EmpleadosListPage(),
            routes: [
              GoRoute(
                path: 'nuevo',
                name: 'empleado-nuevo',
                builder: (context, state) => const EmpleadoFormPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'empleado-detalle',
                builder: (context, state) => EmpleadoFormPage(
                  empleadoId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'supervisores',
            name: 'gestion-supervisores',
            builder: (context, state) => const SupervisoresListPage(),
            routes: [
              GoRoute(
                path: 'nuevo',
                name: 'supervisor-nuevo',
                builder: (context, state) => const SupervisorFormPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'supervisor-detalle',
                builder: (context, state) => SupervisorFormPage(
                  supervisorId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/analitica',
        name: 'analitica',
        builder: (context, state) => const DashboardPage(),
        routes: [
          GoRoute(
            path: 'mapa',
            name: 'analitica-mapa',
            builder: (context, state) => const MapaPage(),
          ),
          GoRoute(
            path: 'detalle',
            name: 'analitica-detalle',
            builder: (context, state) => const DetallePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/desempeno',
        name: 'desempeno',
        builder: (context, state) => const RankingPage(),
        routes: [
          GoRoute(
            path: 'mis-consejos',
            name: 'mis-consejos',
            builder: (context, state) => const MisConsejosPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: \'${state.uri}\''),
      ),
    ),
  );
});

