// 
// ⚠️ THIS FILE IS NOT CURRENTLY USED ⚠️
// The app uses simple MaterialApp navigation in main.dart instead of go_router
// This file is kept for reference but all imports/code are commented out
// 
// If you want to use go_router in the future:
// 1. Add go_router to pubspec.yaml dependencies
// 2. Create the missing feature pages
// 3. Uncomment and update this file
// 4. Update main.dart to use GoRouter

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/grievances/presentation/pages/grievances_list_page.dart';
import '../../features/grievances/presentation/pages/grievance_detail_page.dart';
import '../../features/visits/presentation/pages/visits_page.dart';
import '../../features/promises/presentation/pages/promises_page.dart';
import '../../features/intelligence/presentation/pages/intelligence_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      
      // Grievances
      GoRoute(
        path: '/grievances',
        name: 'grievances',
        builder: (context, state) => const GrievancesListPage(),
      ),
      GoRoute(
        path: '/grievances/:id',
        name: 'grievance-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GrievanceDetailPage(grievanceId: id);
        },
      ),
      
      // Visits
      GoRoute(
        path: '/visits',
        name: 'visits',
        builder: (context, state) => const VisitsPage(),
      ),
      
      // Promises
      GoRoute(
        path: '/promises',
        name: 'promises',
        builder: (context, state) => const PromisesPage(),
      ),
      
      // Intelligence
      GoRoute(
        path: '/intelligence',
        name: 'intelligence',
        builder: (context, state) => const IntelligencePage(),
      ),
    ],
  );
});
*/