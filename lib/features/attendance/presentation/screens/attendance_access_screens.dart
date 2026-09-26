import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/attendance_access_invitation.dart';
import '../../../../domain/attendance_window_policy.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import '../providers/attendance_access_provider.dart';
import '../providers/attendance_controller.dart';
import '../providers/attendance_provider.dart';
import '../../../classes/presentation/providers/class_provider.dart';

class TeacherAttendanceAccessQrScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceAccessQrScreen({super.key, this.offeringId});
  final String? offeringId;

  @override
  ConsumerState<TeacherAttendanceAccessQrScreen> createState() =>
      _TeacherAttendanceAccessQrScreenState();
}

class _TeacherAttendanceAccessQrScreenState
    extends ConsumerState<TeacherAttendanceAccessQrScreen> {
  List<AttendanceAccessQrFrame>? _frames;
  List<ClassSection> _createdOfferings = const [];
  final Set<String> _selectedOfferingIds = {};
  bool _selectionInitialized = false;
  int _index = 0;
  String? _error;

  Future<void> _create(
    List<ClassSection> offerings,
    Set<String> selectedIds,
  ) async {
    setState(() => _error = null);
    try {
      final frames = await ref
          .read(attendanceAccessQrControllerProvider.notifier)
          .create(selectedIds);
      if (!mounted) return;
      setState(() {
        _frames = frames;
        _createdOfferings = offerings
            .where((offering) => selectedIds.contains(offering.id))
            .toList(growable: false);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance QR created.')));
    } on RepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to create this QR.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(classListProvider);
    final busy = ref.watch(attendanceAccessQrControllerProvider);
    return PageScaffold(
      title: 'Share Attendance Access',
      showBack: true,
      body: offeringsAsync.when(
        data: (offerings) {
          if (!_selectionInitialized) {
            _selectedOfferingIds
              ..clear()
              ..addAll(
                offerings
                    .where((offering) => offering.id == widget.offeringId)
                    .map((offering) => offering.id),
              );
            _selectionInitialized = true;
          }
          final frames = _frames;
          if (frames == null) {
            return ListView(
              padding: const EdgeInsets.only(
                top: Spacing.md,
                bottom: Spacing.xl,
              ),
              children: [
                const SectionCard(
                  child: Text(
                    'Select the class offerings this Attendance Officer may handle. The QR includes only those rosters and their registered BLE device mappings. It does not enroll students.',
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    TextButton(
                      onPressed: offerings.isEmpty || busy
                          ? null
                          : () => setState(() {
                              _selectedOfferingIds
                                ..clear()
                                ..addAll(offerings.map((item) => item.id));
                            }),
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(_selectedOfferingIds.clear),
                      child: const Text('Clear All'),
                    ),
                    const Spacer(),
                    Text('${_selectedOfferingIds.length} selected'),
                  ],
                ),
                if (offerings.isEmpty)
                  const HelpfulEmptyState(
                    title: 'No offerings yet',
                    message: 'Create a class offering before sharing access.',
                  )
                else
                  SectionCard(
                    child: Column(
                      children: [
                        for (final offering in offerings)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _selectedOfferingIds.contains(offering.id),
                            title: Text(offering.subject),
                            subtitle: Text(
                              '${offering.sectionCode} · ${offering.schedule}',
                            ),
                            onChanged: busy
                                ? null
                                : (selected) => setState(() {
                                    if (selected == true) {
                                      _selectedOfferingIds.add(offering.id);
                                    } else {
                                      _selectedOfferingIds.remove(offering.id);
                                    }
                                  }),
                          ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                PrimaryActionButton(
                  label: busy
                      ? 'Creating QR...'
                      : 'Create Attendance Officer QR',
                  icon: Icons.qr_code_2,
                  onPressed: busy || _selectedOfferingIds.isEmpty
                      ? null
                      : () => _create(
                          offerings,
                          Set<String>.of(_selectedOfferingIds),
                        ),
                ),
              ],
            );
          }
          final frame = frames[_index];
          return ListView(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
            children: [
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(Spacing.sm),
                  child: QrImageView(data: frame.encode(), size: 320),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'ATTENDANCE ACCESS',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.md),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance Officer access'),
                    const SizedBox(height: Spacing.sm),
                    for (final offering in _createdOfferings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.xs),
                        child: Text(
                          '${offering.subject} · ${offering.sectionCode}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Ask the officer to scan every code in order. Code ${_index + 1} of ${frames.length}.',
                textAlign: TextAlign.center,
              ),
              if (frames.length > 1) ...[
                const SizedBox(height: Spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous QR',
                      onPressed: _index == 0
                          ? null
                          : () => setState(() => _index--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${_index + 1} / ${frames.length}'),
                    IconButton(
                      tooltip: 'Next QR',
                      onPressed: _index == frames.length - 1
                          ? null
                          : () => setState(() => _index++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
              TextButton(
                onPressed: () => setState(() {
                  _frames = null;
                  _index = 0;
                }),
                child: const Text('Create a new QR set'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const HelpfulEmptyState(
          title: 'Offerings unavailable',
          message: 'Your class offerings could not be loaded.',
        ),
      ),
    );
  }
}

class AttendanceAccessImportScreen extends ConsumerStatefulWidget {
  const AttendanceAccessImportScreen({super.key});

  @override
  ConsumerState<AttendanceAccessImportScreen> createState() =>
      _AttendanceAccessImportScreenState();
}

class _AttendanceAccessImportScreenState
    extends ConsumerState<AttendanceAccessImportScreen> {
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final Map<int, AttendanceAccessQrFrame> _frames = {};
  Timer? _releaseFrame;
  String? _invitationId;
  int? _total;
  String? _message;
  bool _processing = false;
  AttendanceAccessInvitation? _pendingInvitation;

  @override
  void dispose() {
    _releaseFrame?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing ||
        _pendingInvitation != null ||
        _releaseFrame?.isActive == true) {
      return;
    }
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (raw == null) return;
    try {
      final frame = AttendanceAccessQrFrame.decode(raw);
      if (_invitationId != null &&
          (_invitationId != frame.invitationId || _total != frame.total)) {
        setState(() {
          _frames.clear();
          _invitationId = frame.invitationId;
          _total = frame.total;
          _message = 'A different QR set was scanned. Start this set again.';
        });
      } else {
        setState(() {
          _invitationId = frame.invitationId;
          _total = frame.total;
          _frames[frame.index] = frame;
          _message = 'Scanned ${_frames.length} of ${frame.total} codes.';
        });
      }
      if (_frames.length == frame.total) unawaited(_importCompleteSet());
    } on FormatException catch (error) {
      setState(() => _message = error.message);
      _releaseFrame = Timer(const Duration(milliseconds: 700), () {});
    }
  }

  Future<void> _importCompleteSet() async {
    if (_processing) return;
    try {
      final invitation = AttendanceAccessQrFrame.decodeFrames(
        _frames.values.toList(),
      );
      if (!mounted) return;
      setState(() {
        _pendingInvitation = invitation;
        _message = null;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Attendance QR import failed.');
    }
  }

  Future<void> _confirmImport() async {
    final invitation = _pendingInvitation;
    if (invitation == null || _processing) return;
    setState(() => _processing = true);
    try {
      await ref
          .read(attendanceAccessRepositoryProvider)
          .importInvitation(invitation);
      await ref.read(applicationSessionProvider).selectAttendanceOfficer();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Attendance access granted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final offering in invitation.offerings)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: Text(offering.offering.subject),
                ),
              const SizedBox(height: Spacing.sm),
              const Text('Role: Attendance Officer'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/attendance-officer');
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on RepositoryException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Attendance QR import failed.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Scan attendance access',
    showBack: true,
    body: Column(
      children: [
        const SizedBox(height: Spacing.md),
        Text(
          'Scan each Attendance Officer code shown by the teacher.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        if (_pendingInvitation case final invitation?)
          Expanded(
            child: ListView(
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance access will be granted for:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Spacing.sm),
                      for (final offering in invitation.offerings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.xs),
                          child: Text(
                            '${offering.offering.subject} · ${offering.offering.sectionCode}',
                          ),
                        ),
                      const SizedBox(height: Spacing.sm),
                      const Text('Role: Attendance Officer'),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                PrimaryActionButton(
                  label: _processing
                      ? 'Importing...'
                      : 'Grant attendance access',
                  icon: Icons.fact_check_outlined,
                  onPressed: _processing ? null : _confirmImport,
                ),
                TextButton(
                  onPressed: _processing
                      ? null
                      : () => setState(() {
                          _frames.clear();
                          _invitationId = null;
                          _total = null;
                          _pendingInvitation = null;
                          _message = null;
                        }),
                  child: const Text('Discard this QR'),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: MobileScanner(controller: _scanner, onDetect: _onDetect),
            ),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(_message!, textAlign: TextAlign.center),
          ),
        if (_processing) const LinearProgressIndicator(),
        if (_pendingInvitation == null)
          TextButton(
            onPressed: () => setState(() {
              _frames.clear();
              _invitationId = null;
              _total = null;
              _message = null;
            }),
            child: const Text('Start over'),
          ),
        const SizedBox(height: Spacing.sm),
      ],
    ),
  );
}

class AttendanceOfficerHomeScreen extends ConsumerWidget {
  const AttendanceOfficerHomeScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    AttendanceAccessGrant grant,
  ) async {
    final offering = await ref
        .read(classRepositoryProvider)
        .getClass(grant.localOfferingId);
    if (offering == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject or class not found.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final window = const AttendanceWindowPolicy().evaluate(
      offering,
      DateTime.now(),
    );
    final override = !window.isScheduled;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          override
              ? 'Attendance is outside the schedule.'
              : 'Start attendance?',
        ),
        content: Text(
          override
              ? '${offering.subject} is outside its scheduled attendance window. Starting anyway will be recorded as a manual override.'
              : '${offering.subject}\n${grant.sectionCode}\n\nThe offline class roster is ready to scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(override ? 'Start Anyway' : 'Start scan'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    if (!context.mounted) return;
    try {
      final session = await ref
          .read(attendanceControllerProvider.notifier)
          .prepareSession(grant.localOfferingId, manualOverride: override);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance session started.')),
        );
        context.push('/attendance-officer/scanner/${session.id}');
      }
    } on RepositoryException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start attendance.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grants = ref.watch(attendanceAccessGrantsProvider);
    final history = ref.watch(attendanceHistoryProvider);
    return PageScaffold(
      title: 'Attendance Officer',
      trailing: IconButton(
        tooltip: 'Scan attendance QR',
        onPressed: () => context.push('/attendance-access/import'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
      body: grants.when(
        data: (items) => items.isEmpty
            ? const HelpfulEmptyState(
                title: 'No attendance-access subjects',
                message: 'Scan an Attendance Officer QR from a teacher to get started.',
              )
            : ListView(
                padding: const EdgeInsets.only(
                  top: Spacing.md,
                  bottom: Spacing.xl,
                ),
                children: [
                  const Text(
                    'Attendance access is available for these classes.',
                  ),
                  const SizedBox(height: Spacing.md),
                  for (final grant in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grant.subject,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${grant.sectionCode} · Attendance Officer'),
                            const SizedBox(height: Spacing.sm),
                            history.when(
                              data: (sessions) {
                                final active = sessions
                                    .where(
                                      (session) =>
                                          session.classOfferingId ==
                                          grant.localOfferingId,
                                    )
                                    .where(
                                      (session) =>
                                          session.status ==
                                              AttendanceSessionStatus
                                                  .scanning ||
                                          session.status ==
                                              AttendanceSessionStatus.review,
                                    )
                                    .firstOrNull;
                                if (active == null) {
                                  return PrimaryActionButton(
                                    label: 'Start attendance',
                                    icon: Icons.bluetooth_searching,
                                    onPressed: () =>
                                        _start(context, ref, grant),
                                  );
                                }
                                return PrimaryActionButton(
                                  label:
                                      active.status ==
                                          AttendanceSessionStatus.review
                                      ? 'Review attendance'
                                      : 'Continue attendance',
                                  icon: Icons.fact_check_outlined,
                                  onPressed: () => context.push(
                                    active.status ==
                                            AttendanceSessionStatus.review
                                        ? '/attendance-officer/results/${active.id}'
                                        : '/attendance-officer/scanner/${active.id}',
                                  ),
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (error, stack) => const Text(
                                'Attendance status is unavailable.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const HelpfulEmptyState(
          title: 'Attendance access unavailable',
          message: 'Saved attendance access could not be loaded.',
        ),
      ),
    );
  }
}
