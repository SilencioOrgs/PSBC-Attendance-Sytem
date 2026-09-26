import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/subject_invitation.dart';
import '../../../../domain/models.dart';
import '../providers/student_provider.dart';

class AddSubjectScreen extends ConsumerStatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  ConsumerState<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends ConsumerState<AddSubjectScreen> {
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  SubjectInvitation? _invitation;
  final Set<String> _selected = {};
  String? _error;
  bool _processing = false;
  bool _scanHandled = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanHandled) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (raw == null) return;
    _scanHandled = true;
    try {
      final invitation = SubjectInvitation.decode(raw);
      setState(() {
        _invitation = invitation;
        _error = null;
      });
      unawaited(_scanner.stop());
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _add(String studentId) async {
    final invitation = _invitation;
    if (invitation == null || _selected.isEmpty || _processing) return;
    setState(() => _processing = true);
    try {
      final count = await ref
          .read(enrollmentRepositoryProvider)
          .addFromInvitation(
            studentId: studentId,
            invitation: invitation,
            selectedOfferingIds: _selected,
          );
      ref.invalidate(currentStudentOfferingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Those subjects are already in your list.'
                : '$count subject${count == 1 ? '' : 's'} added.',
          ),
        ),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Subjects could not be added. Scan a valid teacher invitation and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider).asData?.value;
    return PageScaffold(
      title: 'Add subject',
      showBack: true,
      body: _invitation == null
          ? Column(
              children: [
                const SizedBox(height: Spacing.md),
                const Text('Scan a subject invitation shared by your teacher.'),
                const SizedBox(height: Spacing.md),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.card),
                    child: MobileScanner(
                      controller: _scanner,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                if (_error != null)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _error = null;
                          _scanHandled = false;
                        }),
                        child: const Text('Try another QR'),
                      ),
                    ],
                  ),
                const SizedBox(height: Spacing.md),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(
                top: Spacing.md,
                bottom: Spacing.xl,
              ),
              children: [
                Text(
                  'Teacher: ${_invitation!.teacherName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.sm),
                const Text('Choose the subjects you want to add.'),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    TextButton(
                      onPressed: _processing
                          ? null
                          : () => setState(() {
                              _selected
                                ..clear()
                                ..addAll(
                                  _invitation!.offerings.map((item) => item.id),
                                );
                            }),
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: _processing || _selected.isEmpty
                          ? null
                          : () => setState(_selected.clear),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                ..._invitation!.offerings.map(
                  (offering) => CheckboxListTile(
                    value: _selected.contains(offering.id),
                    title: Text(offering.subject),
                    subtitle: Text(
                      '${offering.sectionCode} · ${_daysLabel(offering.scheduleDays)} · ${_timeLabel(offering.startMinutesOfDay)}–${_timeLabel(offering.endMinutesOfDay)}',
                    ),
                    onChanged: _processing
                        ? null
                        : (value) => setState(() {
                            if (value == true) {
                              _selected.add(offering.id);
                            } else {
                              _selected.remove(offering.id);
                            }
                          }),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.md),
                PrimaryActionButton(
                  label: _processing ? 'Adding...' : 'Add Selected',
                  icon: Icons.add,
                  onPressed: student == null || _selected.isEmpty || _processing
                      ? null
                      : () => _add(student.id),
                ),
                TextButton(
                  onPressed: _processing
                      ? null
                      : () => setState(() {
                          _invitation = null;
                          _selected.clear();
                          _error = null;
                          _scanHandled = false;
                          unawaited(_scanner.start());
                        }),
                  child: const Text('Scan a different QR'),
                ),
              ],
            ),
    );
  }

  String _daysLabel(Set<Weekday> days) =>
      days.map((day) => day.name.substring(0, 3)).join(', ');

  String _timeLabel(int minutes) {
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return time.format(context);
  }
}
