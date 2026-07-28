import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FieldSyncApp extends StatelessWidget {
	const FieldSyncApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp.router(
			debugShowCheckedModeBanner: false,
			title: 'FieldSync',
			theme: AppTheme.lightTheme,
			routerConfig: AppRouter.router,
		);
	}
}
