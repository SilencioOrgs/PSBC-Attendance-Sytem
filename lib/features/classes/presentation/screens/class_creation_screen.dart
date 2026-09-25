import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/repositories.dart';
import '../../../../domain/models.dart';
import '../providers/class_provider.dart';

class ClassCreationScreen extends ConsumerStatefulWidget {
  const ClassCreationScreen({super.key, this.initialSection});

  final ClassSection? initialSection;

  @override
  ConsumerState<ClassCreationScreen> createState() =>
      _ClassCreationScreenState();
}

class _ClassCreationScreenState extends ConsumerState<ClassCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _grade = TextEditingController();
  final _section = TextEditingController();
  final _subject = TextEditingController();
  final _room = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);
  final Set<Weekday> _scheduleDays = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    final section = widget.initialSection;
    if (section != null) {
      _grade.text = '${section.gradeLevel}';
      _section.text = section.sectionLabel;
      _subject.text = section.subject;
      _room.text = section.room;
      _scheduleDays.addAll(section.scheduleDays);
      if (section.scheduleStart != null) {
        _start = TimeOfDay.fromDateTime(section.scheduleStart!);
      }
      if (section.scheduleEnd != null) {
        _end = TimeOfDay.fromDateTime(section.scheduleEnd!);
      }
    }
  }

  @override
  void dispose() {
    _grade.dispose();
    _section.dispose();
    _subject.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final start = DateTime(2000, 1, 1, _start.hour, _start.minute);
    final end = DateTime(2000, 1, 1, _end.hour, _end.minute);
    if (!end.isAfter(start)) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    if (_scheduleDays.isEmpty) {
      setState(() => _error = 'Select at least one schedule day.');
      return;
    }
    try {
      final controller = ref.read(classCreationControllerProvider.notifier);
      final section = widget.initialSection;
      if (section == null) {
        await controller.create(
          gradeLevel: int.parse(_grade.text),
          sectionLabel: _section.text,
          subject: _subject.text,
          room: _room.text,
          scheduleStart: start,
          scheduleEnd: end,
          scheduleDays: _scheduleDays,
        );
      } else {
        await controller.update(
          ClassSection(
            id: section.id,
            updatedAt: section.updatedAt,
            syncStatus: section.syncStatus,
            name:
                'Grade ${_grade.text} - ${_section.text.trim().toUpperCase()}',
            subject: _subject.text,
            room: _room.text,
            schedule: '',
            studentCount: section.studentCount,
            gradeLevel: int.parse(_grade.text),
            sectionLabel: _section.text,
            sectionCode: '',
            scheduleStart: start,
            scheduleEnd: end,
            scheduleDays: _scheduleDays,
            startMinutesOfDay: _start.hour * 60 + _start.minute,
            endMinutesOfDay: _end.hour * 60 + _end.minute,
            bleBeaconId: section.bleBeaconId,
            teacherId: section.teacherId,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialSection == null ? 'Class created.' : 'Class updated.',
          ),
        ),
      );
      context.pop();
    } on RepositoryException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Unable to save class. Please try again.');
    }
  }

  Future<void> _pickTime(bool start) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (selected != null) {
      setState(() {
        if (start) {
          _start = selected;
        } else {
          _end = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: widget.initialSection == null ? 'Create class' : 'Edit class',
    showBack: true,
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _grade,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Grade level',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) {
                final grade = int.tryParse(value ?? '');
                return grade == null || grade < 1
                    ? 'Enter a valid grade level.'
                    : null;
              },
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _section,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Section',
                hintText: 'STEM A',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a section name.'
                  : null,
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _subject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a subject.'
                  : null,
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _room,
              decoration: const InputDecoration(
                labelText: 'Room',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a room.'
                  : null,
            ),
            const SizedBox(height: Spacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Schedule days',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Wrap(
              spacing: Spacing.xs,
              children: Weekday.values
                  .map(
                    (day) => FilterChip(
                      label: Text(
                        day.name[0].toUpperCase() + day.name.substring(1, 3),
                      ),
                      selected: _scheduleDays.contains(day),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _scheduleDays.add(day);
                        } else {
                          _scheduleDays.remove(day);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Starts ${_start.format(context)}'),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.schedule),
                    label: Text('Ends ${_end.format(context)}'),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: Spacing.lg),
            PrimaryActionButton(
              label: ref.watch(classCreationControllerProvider)
                  ? 'Saving...'
                  : widget.initialSection == null
                  ? 'Create class'
                  : 'Save changes',
              icon: Icons.add,
              onPressed: ref.watch(classCreationControllerProvider)
                  ? null
                  : _save,
            ),
          ],
        ),
      ),
    ),
  );
}

class ClassEditLoaderScreen extends ConsumerWidget {
  const ClassEditLoaderScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(classByIdProvider(classId))
      .when(
        data: (section) => section == null
            ? const PageScaffold(
                title: 'Edit class',
                showBack: true,
                body: HelpfulEmptyState(
                  title: 'Class unavailable',
                  message: 'This class could not be loaded.',
                ),
              )
            : ClassCreationScreen(initialSection: section),
        loading: () => const PageScaffold(
          title: 'Edit class',
          showBack: true,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => const PageScaffold(
          title: 'Edit class',
          showBack: true,
          body: HelpfulEmptyState(
            title: 'Class unavailable',
            message: 'Please go back and try again.',
          ),
        ),
      );
}
