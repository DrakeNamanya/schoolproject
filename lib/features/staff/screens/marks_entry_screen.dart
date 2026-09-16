import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';

/// Marks grid for one assessment. Read-only once the 7-day lock has passed.
/// Saved marks become `report_card_results` when the DOS compiles the term.
class MarksEntryScreen extends StatefulWidget {
  const MarksEntryScreen({super.key, required this.assessment, required this.assignment});
  final Assessment assessment;
  final TeachingAssignment assignment;

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  List<MarkEntry>? _rows;
  bool _dirty = false;
  bool _saving = false;
  final _ctrls = <String, TextEditingController>{};

  bool get _locked => widget.assessment.isLocked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await context.read<StaffRepository>().marks(widget.assessment.id);
    for (final r in rows) {
      _ctrls[r.studentId] = TextEditingController(text: r.score?.toString() ?? '');
    }
    if (mounted) setState(() => _rows = rows);
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _entered => _rows?.where((r) => r.score != null).length ?? 0;
  double? get _mean {
    final s = _rows?.where((r) => r.score != null).map((r) => r.score!).toList() ?? [];
    return s.isEmpty ? null : s.reduce((a, b) => a + b) / s.length;
  }

  Future<void> _save() async {
    if (_rows == null) return;
    setState(() => _saving = true);
    final uid = context.read<AuthProvider>().user!.id;
    await context.read<StaffRepository>().saveMarks(widget.assessment.id, _rows!, uid);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $_entered of ${_rows!.length} marks · ${widget.assessment.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assessment;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.label),
        actions: [
          if (!_locked)
            TextButton(
              onPressed: _dirty && !_saving ? _save : null,
              child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
        ],
      ),
      body: _rows == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ---- toolbar -----------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: TgsCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _Sel('Assessment', a.title),
                        _Sel('Out of', '${a.outOf}'),
                        _Sel('Entered', '$_entered/${_rows!.length}'),
                        _Sel('Mean', _mean == null ? '—' : _mean!.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _locked ? TgsColors.paper2 : TgsColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(_locked ? Icons.lock_rounded : Icons.lock_clock_rounded, size: 14, color: _locked ? TgsColors.fg3 : TgsColors.warningText),
                        const SizedBox(width: 6),
                        Text(
                          _locked
                              ? 'Locked on ${Fmt.dayMonthYear(a.locksAt)} · contact the DOS to amend'
                              : 'Locks in ${a.daysToLock} days · ${Fmt.dayMonthYear(a.locksAt)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _locked ? TgsColors.fg3 : TgsColors.warningText),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ---- grid ------------------------------------------------------
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    itemCount: _rows!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _Row(
                      entry: _rows![i],
                      ctrl: _ctrls[_rows![i].studentId]!,
                      outOf: a.outOf,
                      locked: _locked,
                      onScore: (v) => setState(() {
                        _rows![i].score = v;
                        _dirty = true;
                      }),
                      onComment: () => _editComment(_rows![i]),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _locked || _rows == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: TgsColors.navy500),
                  onPressed: _dirty && !_saving ? _save : null,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(_dirty ? 'Save marks' : 'All changes saved'),
                ),
              ),
            ),
    );
  }

  Future<void> _editComment(MarkEntry e) async {
    if (_locked) return;
    final c = TextEditingController(text: e.comment ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e.studentName),
        content: TextField(controller: c, autofocus: true, maxLength: 80, decoration: const InputDecoration(labelText: 'Comment')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (v != null) {
      setState(() {
        e.comment = v.isEmpty ? null : v;
        _dirty = true;
      });
    }
  }
}

class _Sel extends StatelessWidget {
  const _Sel(this.k, this.v);
  final String k, v;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k.toUpperCase(), style: const TextStyle(fontSize: 8, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
        const SizedBox(height: 2),
        Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.ctrl, required this.outOf, required this.locked, required this.onScore, required this.onComment});
  final MarkEntry entry;
  final TextEditingController ctrl;
  final int outOf;
  final bool locked;
  final ValueChanged<int?> onScore;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final over = (entry.score ?? 0) > outOf;
    return TgsCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          InitialsAvatar(entry.initials, size: 32, color: TgsColors.navy400),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onComment,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    entry.comment ?? (locked ? entry.admissionNo : 'Tap to add comment'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: entry.comment == null ? TgsColors.fgMuted : TgsColors.fg2, fontStyle: entry.comment == null ? FontStyle.italic : null),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: ctrl,
              enabled: !locked,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 15, fontWeight: FontWeight.w600, color: over ? TgsColors.brick600 : TgsColors.fg1),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                hintText: '—',
                fillColor: locked ? TgsColors.paper : Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: over ? TgsColors.brick500 : TgsColors.border1)),
              ),
              onChanged: (v) => onScore(v.isEmpty ? null : int.tryParse(v)),
            ),
          ),
          const SizedBox(width: 6),
          Text('/$outOf', style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, color: TgsColors.fg3)),
        ],
      ),
    );
  }
}
