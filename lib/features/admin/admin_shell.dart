import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../core/config.dart';
import '../../data/mock/demo_store.dart';
import '../../models/user.dart';
import '../../theme/tokens.dart';
import '../../widgets/brand.dart';
import 'admin_modules.dart';
import 'modules/academics_module.dart';
import 'modules/attendance_module.dart';
import 'modules/audit_module.dart';
import 'modules/clinic_module.dart';
import 'modules/dashboard_module.dart';
import 'modules/events_module.dart';
import 'modules/finance_module.dart';
import 'modules/kitchen_module.dart';
import 'modules/procurement_module.dart';
import 'modules/reports_module.dart';
import 'modules/stores_module.dart';
import 'modules/students_module.dart';

/// Web console: persistent sidebar ≥ 1024 px, drawer below. Modules shown are
/// scoped to the signed-in sub-role.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminModule? _current;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.activeRole ?? UserRole.admin;
    final modules = AdminModule.forRole(role);
    final current = (_current != null && modules.contains(_current)) ? _current! : AdminModule.homeFor(role);
    final wide = MediaQuery.sizeOf(context).width >= 1024;

    final side = _Sidebar(
      modules: modules,
      current: current,
      role: role,
      onSelect: (m) {
        setState(() => _current = m);
        if (!wide) Navigator.of(context).maybePop();
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide ? null : Drawer(width: 260, child: side),
      body: Row(
        children: [
          if (wide) SizedBox(width: 248, child: side),
          Expanded(
            child: Column(
              children: [
                _TopBar(current: current, onMenu: wide ? null : () => _scaffoldKey.currentState?.openDrawer()),
                Expanded(
                  child: ListenableBuilder(
                    listenable: DemoStore.instance,
                    builder: (_, _) => Container(
                      color: TgsColors.paper,
                      child: SingleChildScrollView(
                        key: ValueKey(current),
                        padding: EdgeInsets.all(wide ? 28 : 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: _body(current, role),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AdminModule m, UserRole role) => switch (m) {
    AdminModule.dashboard => const DashboardModule(),
    AdminModule.finance => const FinanceModule(),
    AdminModule.students => const StudentsModule(),
    AdminModule.academics => const AcademicsModule(),
    AdminModule.attendance => const AttendanceModule(),
    AdminModule.clinic => const ClinicModule(),
    AdminModule.kitchen => const KitchenModule(),
    AdminModule.events => const EventsModule(),
    AdminModule.procurement => const ProcurementModule(),
    AdminModule.stores => const StoresModule(),
    AdminModule.reports => const ReportsModule(),
    AdminModule.audit => const AuditModule(),
  };
}

// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.modules, required this.current, required this.role, required this.onSelect});
  final List<AdminModule> modules;
  final AdminModule current;
  final UserRole role;
  final ValueChanged<AdminModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final groups = <String, List<AdminModule>>{};
    for (final m in modules) {
      (groups[m.group] ??= []).add(m);
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlagStrip(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(children: [
              const Crest(size: 36),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Timbitwire', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 17, height: 1)),
                Text('GIRLS SCHOOL · ADMIN', style: TextStyle(fontSize: 8.5, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
              ])),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                for (final g in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                    child: Text(g.key.toUpperCase(), style: const TextStyle(fontSize: 9.5, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
                  ),
                  for (final m in g.value) _Item(m: m, active: m == current, onTap: () => onSelect(m)),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Text(AppConfig.motto, style: const TextStyle(fontFamily: TgsFonts.display, fontStyle: FontStyle.italic, fontSize: 12, color: TgsColors.maroon500)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 14),
            child: Row(children: [
              InitialsAvatar(user.initials, size: 34, color: TgsColors.maroon500),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(role.label, style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
              ])),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 18, color: TgsColors.fg3),
                onSelected: (v) => v == 'switch' ? auth.switchRole() : auth.signOut(),
                itemBuilder: (_) => [
                  if (user.roles.length > 1) const PopupMenuItem(value: 'switch', child: Text('Switch role')),
                  const PopupMenuItem(value: 'out', child: Text('Sign out')),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.m, required this.active, required this.onTap});
  final AdminModule m;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Material(
      color: active ? TgsColors.brick50 : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: active
              ? const BoxDecoration(border: Border(left: BorderSide(color: TgsColors.brick500, width: 3)), borderRadius: BorderRadius.horizontal(right: Radius.circular(10)))
              : null,
          child: Row(children: [
            Icon(m.icon, size: 18, color: active ? TgsColors.brick600 : TgsColors.fg2),
            const SizedBox(width: 10),
            Text(m.label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? TgsColors.brick700 : TgsColors.fg1)),
          ]),
        ),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.current, this.onMenu});
  final AdminModule current;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: TgsColors.border1))),
      child: Row(children: [
        if (onMenu != null) IconButton(onPressed: onMenu, icon: const Icon(Icons.menu_rounded)),
        Text.rich(TextSpan(
          text: '${current.group}  ›  ',
          style: const TextStyle(fontSize: 12, color: TgsColors.fg3),
          children: [TextSpan(text: current.label, style: const TextStyle(fontWeight: FontWeight.w700, color: TgsColors.fg1))],
        )),
        const Spacer(),
        if (wide) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: TgsColors.border1), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: TgsColors.fg3),
              SizedBox(width: 6),
              Text('Term 2 · 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(Icons.expand_more_rounded, size: 16, color: TgsColors.fg3),
            ]),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 280,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students, staff, receipts…',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: TgsColors.paper,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TgsColors.border1)),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
        ],
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, size: 20), color: TgsColors.fg2),
        IconButton(onPressed: () {}, icon: const Icon(Icons.print_outlined, size: 20), color: TgsColors.fg2),
      ]),
    );
  }
}
