import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';

/// Daily register for the class teacher. Writes `attendance` rows which the
/// parent hero card summarises as attendance %.
class RollCallScreen extends StatefulWidget {
  const RollCallScreen({super.key, required this.assignment});
  final TeachingAssignment assignment;

  @override
  State<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends State<RollCallScreen> {
  List<RollCallEntry>? _rows;
  DateTime _date = DateTime.now();
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _rows = null);
    final rows = await context.read<StaffRepository>().rollCall(widget.assignment.schoolClass.id, _date);
    if (mounted) setState(() => _rows = rows);
  }

  int get _present => _rows?.where((r) => r.present).length ?? 0;

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = context.read<AuthProvider>().user!.id;
    await context.read<StaffRepository>().saveRollCall(widget.assignment.schoolClass.id, _date, _rows!, uid);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Register saved · $_present of ${_rows!.length} present')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.assignment.schoolClass;
    return Scaffold(
      appBar: AppBar(
        title: Text('Roll call · ${cls.name}'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 14)), lastDate: DateTime.now());
              if (d != null) {
                setState(() => _date = d);
                _load();
              }
            },
            icon: const Icon(Icons.event_outlined, size: 16),
            label: Text(Fmt.dayMonth(_date)),
          ),
        ],
      ),
      body: _rows == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TgsCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Eyebrow('Present'),
                                    Text('$_present / ${_rows!.length}', style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 24, color: TgsColors.success)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Eyebrow('Absent'),
                                    Text('${_rows!.length - _present}', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 24, color: _rows!.length - _present > 0 ? TgsColors.brick600 : TgsColors.fg1)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  for (final r in _rows!) {
                                    r.present = true;
                                  }
                                  _dirty = true;
                                }),
                                child: const Text('All present'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    itemCount: _rows!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final r = _rows![i];
                      return TgsCard(
                        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                        color: r.present ? Colors.white : TgsColors.dangerBg,
                        onTap: () => setState(() {
                          r.present = !r.present;
                          _dirty = true;
                        }),
                        child: Row(
                          children: [
                            InitialsAvatar(_ini(r.studentName), size: 32, color: r.present ? TgsColors.navy400 : TgsColors.brick400),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(r.admissionNo, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3)),
                                ],
                              ),
                            ),
                            Pip(r.present ? 'Present' : 'Absent', tone: r.present ? PipTone.ok : PipTone.due),
                            const SizedBox(width: 4),
                            Switch(
                              value: r.present,
                              activeTrackColor: TgsColors.success,
                              onChanged: (v) => setState(() {
                                r.present = v;
                                _dirty = true;
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _rows == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: TgsColors.navy500),
                  onPressed: _dirty && !_saving ? _save : null,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(_dirty ? 'Save register' : 'Register saved'),
                ),
              ),
            ),
    );
  }

  static String _ini(String n) {
    final p = n.split(' ');
    return p.length > 1 ? '${p[0][0]}${p[1][0]}' : p[0][0];
  }
}
