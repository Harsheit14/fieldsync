import 'package:fieldsync/features/sync/presentation/providers/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FieldSyncApp extends ConsumerWidget {
  const FieldSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the synchronization engine alive for the lifetime
    // of the application. This ensures synchronization does not
    // depend on any particular screen being opened.
    ref.watch(syncCoordinatorProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FieldSync',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
