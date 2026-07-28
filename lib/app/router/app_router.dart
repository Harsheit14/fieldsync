import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/home_page.dart';
import 'routes.dart';

class AppRouter {
	AppRouter._();

	static final GoRouter _router = GoRouter(
		initialLocation: AppRoutes.home,
		routes: [
			GoRoute(
				path: AppRoutes.home,
				builder: (context, state) => const HomePage(),
			),
		],
	);

	static GoRouter get router => _router;
}
