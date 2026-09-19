import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth_provider.dart';
import 'core/config.dart';
import 'core/push_service.dart';
import 'data/admin_repository.dart';
import 'data/mock/mock_admin_repository.dart';
import 'data/mock/mock_parent_repository.dart';
import 'data/mock/mock_staff_repository.dart';
import 'data/parent_repository.dart';
import 'data/staff_repository.dart';
import 'data/supabase/supabase_admin_repository.dart';
import 'data/supabase/supabase_parent_repository.dart';
import 'data/supabase/supabase_staff_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_picker_screen.dart';
import 'features/parent/parent_provider.dart';
import 'features/parent/parent_shell.dart';
import 'features/admin/admin_shell.dart';
import 'features/staff/staff_provider.dart';
import 'features/staff/staff_shell.dart';
import 'models/user.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  await PushService.instance.init();

  runApp(const TimbitwireApp());
}

class TimbitwireApp extends StatelessWidget {
  const TimbitwireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ParentRepository>(
          create: (_) => AppConfig.hasSupabase
              ? SupabaseParentRepository(Supabase.instance.client)
              : MockParentRepository(),
        ),
        Provider<StaffRepository>(
          create: (_) => AppConfig.hasSupabase
              ? SupabaseStaffRepository(Supabase.instance.client)
              : MockStaffRepository(),
        ),
        Provider<AdminRepository>(
          create: (_) => AppConfig.hasSupabase
              ? SupabaseAdminRepository(Supabase.instance.client)
              : MockAdminRepository(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.schoolName,
        debugShowCheckedModeBanner: false,
        theme: TgsTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

/// Routes to the right shell based on auth state and active role.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        if (auth.needsRolePicker) return const RolePickerScreen();
        final shell = auth.shell ?? AppShell.parent;
        final user = auth.user!;
        PushService.instance.registerToken(user.id);
        // Parent + Staff are PHONE apps (framed on wide web screens);
        // Admin is a WEB console.
        return switch (shell) {
          AppShell.parent => PhoneFrame(
            label: 'Parent app · mobile',
            child: ChangeNotifierProvider(
              key: ValueKey('parent-${user.id}'),
              create: (ctx) =>
                  ParentProvider(ctx.read<ParentRepository>(), user.id),
              child: const ParentShell(),
            ),
          ),
          AppShell.staff => PhoneFrame(
            label: 'Staff app · mobile',
            child: ChangeNotifierProvider(
              key: ValueKey('staff-${user.id}'),
              create: (ctx) =>
                  StaffProvider(ctx.read<StaffRepository>(), user.id),
              child: const StaffShell(),
            ),
          ),
          AppShell.admin => AdminShell(key: ValueKey('admin-${user.id}-${auth.activeRole}')),
        };
    }
  }
}
