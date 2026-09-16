import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../data/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../staff_provider.dart';
import '../staff_shell.dart';
import 'marks_entry_screen.dart';
import 'roll_call_screen.dart';

/// Teacher's classes. Entry point to marks entry and roll call — the two
/// writes that populate the parent's Academics tab and attendance %.
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StaffProvider>();
    final classTeacherOf = p.assignments.where((a) => a.isClassTeacher).toList();

    return Column(
      children: [
        const StaffPageHeader(title: 'Classes', badge: 'Term 2 · 2026'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              if (classTeacherOf.isNotEmpty) ...[
                const SectionTitle('Class teacher', top: 8),
                for (final a in classTeacherOf)
                  TgsCard(
                    onTap: () => _openRollCall(context, a),
                    color: TgsColors.navy50,
                    child: Row(
                      children: [
                        const IconBox(Icons.checklist_rounded, tint: TgsColors.navy500, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Roll call · ${a.schoolClass.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              Text('${a.schoolClass.size} girls · feeds parent attendance %', style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
                            ],
                          ),
                        ),
                        const Chevron(color: TgsColors.navy600),
                      ],
                    ),
                  ),
              ],
              const SectionTitle('Subjects I teach'),
              for (final a in p.assignments) ...[
                _AssignmentCard(a),
                const SizedBox(height: 8),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Marks lock automatically 7 days after the assessment date. Report cards reach parents only after the DOS publishes them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: TgsColors.fg3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _openRollCall(BuildContext context, TeachingAssignment a) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RollCallScreen(assignment: a),
    ));
  }
}

class _AssignmentCard extends StatefulWidget {
  const _AssignmentCard(this.a);
  final TeachingAssignment a;
  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  List<Assessment>? _list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await context.read<StaffRepository>().assessments(widget.a.id);
    if (mounted) setState(() => _list = l);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    return TgsCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40, alignment: Alignment.center,
                decoration: BoxDecoration(color: TgsColors.brick50, borderRadius: BorderRadius.circular(10)),
                child: Text(a.subject.code, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, fontWeight: FontWeight.w700, color: TgsColors.brick600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('${a.schoolClass.size} girls', style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _newAssessment(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Assessment'),
              ),
            ],
          ),
          if (_list == null)
            const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator(minHeight: 2))
          else if (_list!.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text('No assessments yet this term.', style: TextStyle(fontSize: 12, color: TgsColors.fg3)),
            )
          else ...[
            const Divider(height: 16),
            for (final as in _list!) _AssessmentRow(as, a, onChanged: _load),
          ],
        ],
      ),
    );
  }

  Future<void> _newAssessment(BuildContext context) async {
    final result = await showModalBottomSheet<(String, int, DateTime)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewAssessmentSheet(),
    );
    if (result == null || !context.mounted) return;
    await context.read<StaffRepository>().createAssessment(widget.a.id, title: result.$1, outOf: result.$2, assessedOn: result.$3);
    await _load();
  }
}

class _AssessmentRow extends StatelessWidget {
  const _AssessmentRow(this.as, this.a, {required this.onChanged});
  final Assessment as;
  final TeachingAssignment a;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final locked = as.isLocked;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(locked ? Icons.lock_rounded : Icons.edit_note_rounded, color: locked ? TgsColors.fg3 : TgsColors.navy500),
      title: Text('${as.title} · out of ${as.outOf}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        locked ? 'Locked ${Fmt.dayMonth(as.locksAt)} · read only' : 'Locks in ${as.daysToLock} days · ${Fmt.dayMonthYear(as.locksAt)}',
        style: TextStyle(fontSize: 11, color: locked ? TgsColors.fg3 : TgsColors.warningText),
      ),
      trailing: const Chevron(),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MarksEntryScreen(assessment: as, assignment: a),
        ));
        onChanged();
      },
    );
  }
}

class _NewAssessmentSheet extends StatefulWidget {
  const _NewAssessmentSheet();
  @override
  State<_NewAssessmentSheet> createState() => _NewAssessmentSheetState();
}

class _NewAssessmentSheetState extends State<_NewAssessmentSheet> {
  final _title = TextEditingController(text: 'CAT 3');
  final _outOf = TextEditingController(text: '40');
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New assessment', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Marks will lock 7 days after the assessment date.', style: TextStyle(fontSize: 12, color: TgsColors.fg2)),
        const SizedBox(height: 14),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title (e.g. CAT 3, Mid-term)')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _outOf, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Out of'))),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime.now().add(const Duration(days: 60)));
                  if (d != null) setState(() => _date = d);
                },
                icon: const Icon(Icons.event_outlined, size: 16),
                label: Text(Fmt.dayMonthYear(_date)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: TgsColors.navy500),
          onPressed: () {
            final o = int.tryParse(_outOf.text) ?? 0;
            if (_title.text.trim().isEmpty || o <= 0) return;
            Navigator.pop(context, (_title.text.trim(), o, _date));
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
