import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/calendario_screen.dart';
import '../../features/auth/recover_password_screen.dart';
import '../../features/home/player_detail_screen.dart';
import '../../features/home/plantilla_screen.dart';
import '../../features/home/resumen_screen.dart';
import '../../features/matches/acta_screen.dart';
import '../../features/matches/create_match_screen.dart';
import '../../features/matches/edit_match_screen.dart';
import '../../features/matches/ver_acta_screen.dart';
import '../../features/matches/votar_partido_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/stats/detalle_estadistica_screen.dart';
import '../../features/stats/goleadores_screen.dart';
import '../../features/stats/mis_valoraciones_screen.dart';
import '../../features/timer/timer_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: FirebaseAuth.instance.currentUser == null ? '/login' : '/resumen',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/recuperar-contrasena',
        builder: (context, state) => const RecoverPasswordScreen(),
      ),
      GoRoute(
        path: '/resumen',
        builder: (context, state) => const ResumenScreen(),
      ),
      GoRoute(
        path: '/timer',
        builder: (context, state) => const TimerTurnosScreen(),
      ),
      GoRoute(
        path: '/acta',
        builder: (context, state) => const ActaScreen(),
      ),
      GoRoute(
        path: '/plantilla',
        builder: (context, state) => const PlantillaScreen(),
      ),
      GoRoute(
        path: '/editar-perfil',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/goleadores',
        builder: (context, state) => const GoleadoresScreen(),
      ),
      GoRoute(
        path: '/calendario',
        builder: (context, state) => const CalendarioScreen(),
      ),
      GoRoute(
        path: '/detalle-estadistica/:tipo',
        builder: (context, state) {
          final tipo = state.pathParameters['tipo'] ?? 'goles';
          return DetalleEstadisticaScreen(tipo: tipo);
        },
      ),
      GoRoute(
        path: '/mis-valoraciones',
        builder: (context, state) => const MisValoracionesScreen(),
      ),
      GoRoute(
        path: '/crear-partido',
        builder: (context, state) => const CreateMatchScreen(),
      ),
      GoRoute(
        path: '/perfil-jugador/:jugadorId',
        builder: (context, state) {
          final id = state.pathParameters['jugadorId'] ?? '';
          return PlayerDetailScreen(playerId: id);
        },
      ),
      GoRoute(
        path: '/ver-acta/:partidoId',
        builder: (context, state) {
          final id = state.pathParameters['partidoId'] ?? '';
          return VerActaScreen(matchId: id);
        },
      ),
      GoRoute(
        path: '/votar-partido/:partidoId',
        builder: (context, state) {
          final id = state.pathParameters['partidoId'] ?? '';
          return VotarPartidoScreen(matchId: id);
        },
      ),
      GoRoute(
        path: '/editar-partido/:partidoId',
        builder: (context, state) {
          final id = state.pathParameters['partidoId'] ?? '';
          return EditMatchScreen(matchId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final inAuthFlow = state.matchedLocation == '/login' ||
          state.matchedLocation == '/registro' ||
          state.matchedLocation == '/recuperar-contrasena';

      if (!isLoggedIn && !inAuthFlow) {
        return '/login';
      }
      if (isLoggedIn && inAuthFlow) {
        return '/resumen';
      }
      return null;
    },
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Ruta no encontrada')),
    ),
  );
}
