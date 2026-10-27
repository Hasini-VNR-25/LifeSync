import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/home_dashboard_screen.dart';
import '../../features/life_twin/presentation/life_twin_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/simulator/presentation/simulator_screen.dart';
import '../../features/comeback/presentation/comeback_screen.dart';
import '../../features/investigator/presentation/investigator_screen.dart';
import '../../features/experiments/presentation/experiment_detail_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/reflections/presentation/reflection_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../domain/models/experiment.dart';
import '../../core/theme/app_colors.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/dashboard')) currentIndex = 0;
    else if (location.startsWith('/planner')) currentIndex = 1;
    else if (location.startsWith('/simulator')) currentIndex = 2;
    else if (location.startsWith('/investigator')) currentIndex = 3;
    else if (location.startsWith('/settings')) currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accentTeal.withOpacity(0.15),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/planner');
              break;
            case 2:
              context.go('/simulator');
              break;
            case 3:
              context.go('/investigator');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.accentTeal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.accentTeal),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science, color: AppColors.accentTeal),
            label: 'Simulate',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph, color: AppColors.accentTeal),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.accentTeal),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Modal / Contextual Routes
    GoRoute(
      path: '/comeback',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ComebackScreen(),
    ),
    GoRoute(
      path: '/life-twin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LifeTwinScreen(),
    ),
    GoRoute(
      path: '/goals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalsScreen(),
    ),
    GoRoute(
      path: '/tasks',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TasksScreen(),
    ),
    GoRoute(
      path: '/reflections',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReflectionScreen(),
    ),
    GoRoute(
      path: '/experiment-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final exp = state.extra as Experiment;
        return ExperimentDetailScreen(experiment: exp);
      },
    ),

    // Shell with Bottom Navigation Bar
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const HomeDashboardScreen(),
        ),
        GoRoute(
          path: '/planner',
          builder: (context, state) => const PlannerScreen(),
        ),
        GoRoute(
          path: '/simulator',
          builder: (context, state) => const SimulatorScreen(),
        ),
        GoRoute(
          path: '/investigator',
          builder: (context, state) => const InvestigatorScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
