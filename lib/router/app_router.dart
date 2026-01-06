import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/descriptive_stats_page.dart';
import '../pages/inferential_stats_page.dart';

/// App router configuration using go_router
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/descriptive',
      name: 'descriptive',
      builder: (context, state) => const DescriptiveStatsPage(),
    ),
    GoRoute(
      path: '/inferential',
      name: 'inferential',
      builder: (context, state) => const InferentialStatsPage(),
    ),
  ],
);
