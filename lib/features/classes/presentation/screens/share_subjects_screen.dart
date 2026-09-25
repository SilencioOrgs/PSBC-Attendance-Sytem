import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/models.dart';
import '../../../../domain/subject_invitation.dart';
import '../../../teacher/presentation/providers/teacher_provider.dart';
import '../providers/class_provider.dart';

class ShareSubjectsScreen extends ConsumerStatefulWidget {
  const ShareSubjectsScreen({super.key});

  @override
  ConsumerState<ShareSubjectsScreen> createState() =>
      _ShareSubjectsScreenState();
}

class _ShareSubjectsScreenState extends ConsumerState<ShareSubjectsScreen> {
  final Set<String> _selected = {};
  String? _payload;

  @override
  Widget build(BuildContext context) {
    final offerings = ref.watch(classListProvider);
    final teacher = ref.watch(teacherProvider);
    return PageScaffold(
      title: 'Share subjects',
      showBack: true,
      body: offerings.when(
        data: (classes) => teacher.when(
          data: (teacher) => ListView(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
            children: [
              const Text(
                'Choose the subjects students can add from this offline invitation.',
              ),
              const SizedBox(height: Spacing.md),
              if (classes.isEmpty)
                const HelpfulEmptyState(
                  title: 'No subjects available',
                  message: 'Create a subject offering before sharing it.',
                )
              else
                ...classes.map(
                  (offering) => CheckboxListTile(
                    value: _selected.contains(offering.id),
                    title: Text(offering.subject),
                    subtitle: Text(
                      '${offering.sectionCode} · ${offering.schedule}',
                    ),
                    onChanged:
                        _payload == null && offering.scheduleDays.isNotEmpty
                        ? (value) => setState(() {
                            if (value == true) {
                              _selected.add(offering.id);
                            } else {
                              _selected.remove(offering.id);
                            }
                          })
                        : null,
                  ),
                ),
              const SizedBox(height: Spacing.md),
              if (_payload == null)
                PrimaryActionButton(
                  label: 'Create subjects QR',
                  icon: Icons.qr_code_2,
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          final selected = classes.where(
                            (item) => _selected.contains(item.id),
                          );
                          final invitation = SubjectInvitation(
                            teacherId: teacher.id,
                            teacherName: teacher.name,
                            offerings: selected
                                .map(_toInvitationOffering)
                                .toList(growable: false),
                          );
                          setState(() => _payload = invitation.encode());
                        },
                )
              else ...[
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(Spacing.md),
                    child: QrImageView(data: _payload!, size: 280),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                const Text(
                  'Students scan this code, review the subjects, and choose which ones to add.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => setState(() => _payload = null),
                  child: const Text('Choose different subjects'),
                ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const HelpfulEmptyState(
            title: 'Teacher unavailable',
            message: 'Teacher details could not be loaded.',
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const HelpfulEmptyState(
          title: 'Subjects unavailable',
          message: 'Try again later.',
        ),
      ),
    );
  }

  SubjectInvitationOffering _toInvitationOffering(ClassSection offering) =>
      SubjectInvitationOffering(
        id: offering.id,
        subject: offering.subject,
        sectionCode: offering.sectionCode,
        gradeLevel: offering.gradeLevel,
        sectionLabel: offering.sectionLabel,
        room: offering.room,
        scheduleDays: offering.scheduleDays,
        startMinutesOfDay:
            offering.startMinutesOfDay ??
            offering.scheduleStart!.hour * 60 + offering.scheduleStart!.minute,
        endMinutesOfDay:
            offering.endMinutesOfDay ??
            offering.scheduleEnd!.hour * 60 + offering.scheduleEnd!.minute,
      );
}
