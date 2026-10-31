import 'dart:async';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_dialogs.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/job_status_badge.dart';
import 'package:awnneaapp/app/core/widgets/job_status_timeline.dart';
import 'package:awnneaapp/app/data/models/booking_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:awnneaapp/app/modules/booking/views/live_tracking_view.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// The helper's screen for a job he accepted: what to do next (travel → arrive →
/// finished), contact the client, cancel (early) or report a problem.
class ActiveJobDetailsView extends StatefulWidget {
  const ActiveJobDetailsView({super.key});

  @override
  State<ActiveJobDetailsView> createState() => _ActiveJobDetailsViewState();
}

class _ActiveJobDetailsViewState extends State<ActiveJobDetailsView> {
  late Map<String, dynamic> job;
  StreamSubscription? _cancelSub;
  StreamSubscription? _updateSub;
  Worker? _listWorker;
  bool _busy = false;
  // Guards against popping twice: the backend emits job:cancelled to the
  // helper too, so both the socket listener and the cancel button try to
  // close this screen. A second pop removes the home route -> black screen.
  bool _leaving = false;

  HelperJobsController get _controller => Get.find<HelperJobsController>();

  String get _jobId => (job['id'] ?? job['_id'] ?? '').toString();
  String get _status => (job['status'] ?? '').toString();
  bool get _finished => job['helperFinishedAt'] != null && job['helperFinishedAt'].toString().isNotEmpty;
  bool get _dispute => job['disputeOpen'] == true;
  bool get _isCash => (job['paymentMethod'] ?? '').toString() == 'cash';

  @override
  void initState() {
    super.initState();
    job = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};

    final id = _jobId;
    if (id.isEmpty) return;

    // The list is patched by the controller after every action; follow it.
    _listWorker = ever(_controller.activeJobs, (_) {
      final fresh = _controller.findJobById(id);
      if (fresh != null && mounted) setState(() => job = fresh);
    });
    // Also load the newest copy (the list may be a few seconds old).
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());

    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      _cancelSub = socket.onJobCancelled.listen((data) {
        final remoteId = (data['id'] ?? data['_id'] ?? data['jobId'])?.toString();
        if (remoteId == id) _leaveScreen();
      });
      _updateSub = socket.onJobUpdated.listen((data) {
        if (data['jobId']?.toString() == id) _reload();
      });
    }
  }

  Future<void> _reload() async {
    try {
      final data = await Get.find<JobService>().getJobById(_jobId);
      if (!mounted) return;
      setState(() => job = Map<String, dynamic>.from(data));
      if ((data['status'] ?? '') == 'cancelled') _leaveScreen();
    } catch (_) {}
  }

  /// Closes this screen exactly once, without ever emptying the navigator.
  void _leaveScreen() {
    if (_leaving || !mounted) return;
    _leaving = true;
    final route = ModalRoute.of(context);
    final nav = Navigator.of(context);
    if (route == null || !route.isActive) return;
    // Close anything stacked above this screen (e.g. the cancel sheet) first.
    nav.popUntil((r) => r == route);
    if (nav.canPop()) {
      nav.pop();
    } else {
      Get.offAllNamed(Routes.helperHome);
    }
  }

  @override
  void dispose() {
    _cancelSub?.cancel();
    _updateSub?.cancel();
    _listWorker?.dispose();
    super.dispose();
  }

  // ─── Actions ────────────────────────────────────────────

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startTravelling() async {
    final ok = await AppDialogs.confirm(
      title: 'job_confirm_start_travel_title'.tr,
      message: 'job_confirm_start_travel_body'.tr,
      confirmLabel: 'job_start_travelling'.tr,
    );
    if (!ok) return;
    // Sharing needs GPS: ask now, with the reason in front of the helper.
    if (Get.isRegistered<LocationService>()) {
      final loc = Get.find<LocationService>();
      if (!await loc.checkGpsStatus()) {
        await loc.requestGpsAndPermission();
      }
    }
    await _run(() => _controller.startTravelling(_jobId));
  }

  Future<void> _arrived() => _run(() => _controller.markArrived(_jobId));

  Future<void> _workFinished() async {
    final ok = await AppDialogs.confirm(
      title: 'job_confirm_finished_title'.tr,
      message: 'job_confirm_finished_body'.tr,
      confirmLabel: 'job_work_finished'.tr,
    );
    if (!ok) return;
    await _run(() => _controller.markFinished(_jobId));
  }

  Future<void> _reportProblem() async {
    final text = await AppDialogs.askReason(
      title: 'job_report_problem'.tr,
      hint: 'job_report_problem_hint'.tr,
      minLength: 10,
    );
    if (text == null) return;
    await _run(() => _controller.reportProblem(_jobId, text));
  }

  Future<void> _cancel() async {
    final reason = await AppDialogs.askReason(
      title: 'booking_cancel_booking'.tr,
      message: 'job_helper_cancel_warning'.tr,
      hint: 'job_cancel_reason_hint'.tr,
      confirmLabel: 'booking_yes_cancel'.tr,
      danger: true,
    );
    if (reason == null) return;
    final ok = await _controller.cancelJob(_jobId, reason: reason);
    if (ok) _leaveScreen();
  }

  Future<void> _chatWithClient() async {
    final postedBy = job['postedBy'];
    final clientId = postedBy is Map ? (postedBy['_id'] ?? postedBy['id'] ?? '').toString() : '';
    if (clientId.isEmpty) return;
    final messages = Get.find<MessagesController>();
    final conversation = await messages.startConversation(clientId);
    if (conversation != null) {
      final other = conversation.otherParticipant;
      Get.toNamed(
        Routes.helperChatDetail,
        arguments: ChatSummary(
          id: conversation.id,
          name: other?.name ?? JobDisplay.personName(postedBy),
          image: other?.avatar ?? JobDisplay.personAvatar(postedBy),
          otherUserId: clientId,
        ),
      );
    }
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    AppFeedback.info(phone);
  }

  ({double? lat, double? lon}) get _coords {
    final coords = job['location'] is Map ? job['location']['coordinates'] : null;
    if (coords is List && coords.length >= 2) {
      return (lat: (coords[1] as num?)?.toDouble(), lon: (coords[0] as num?)?.toDouble());
    }
    return (lat: null, lon: null);
  }

  Future<void> _openExternalDirections() async {
    final c = _coords;
    if (c.lat == null || c.lon == null) {
      AppFeedback.info('ui_coordinates_not_available_for_direct_navigation'.tr);
      return;
    }
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${c.lat},${c.lon}',
    );
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    final fallbackUri = Uri.parse('geo:${c.lat},${c.lon}?q=${c.lat},${c.lon}');
    try {
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _openLiveMap() {
    final c = _coords;
    double? helperLat;
    double? helperLon;
    if (Get.isRegistered<LocationService>()) {
      final loc = Get.find<LocationService>();
      helperLat = loc.currentLatitude.value;
      helperLon = loc.currentLongitude.value;
    }
    Get.to(
      () => const LiveTrackingView(),
      arguments: {
        'jobId': _jobId,
        'jobTitle': JobDisplay.categoryName(job['category'], fallback: 'tracking_title'.tr),
        'address': job['address']?.toString() ?? '',
        'latitude': c.lat,
        'longitude': c.lon,
        'helperLat': helperLat,
        'helperLon': helperLon,
      },
    );
  }

  // ─── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = bookingStatusFromApi(_status);
    final postedBy = job['postedBy'];
    final phone = postedBy is Map ? (postedBy['phone'] ?? '').toString() : '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'job_details_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientCard(context, postedBy, status, phone),
            const SizedBox(height: 12),
            if (_dispute) _banner(context, Icons.support_agent, Colors.orange, 'job_dispute_open_msg'.tr),
            if (_finished && !_dispute)
              _banner(context, Icons.hourglass_top, Colors.deepPurple,
                  'ui_waiting_for_the_client_to_confirm_service'.tr),
            if (_finished || _dispute) const SizedBox(height: 12),
            _buildJobInfoTable(context, job),
            const SizedBox(height: 12),
            _buildMapButtons(context),
            const SizedBox(height: 16),
            _buildJobDescriptionWithPhotos(context, job),
            const SizedBox(height: 16),
            JobStatusTimeline(steps: JobTimeline.fromJobMap(job)),
            const SizedBox(height: 24),
            ..._buildActions(context, status),
          ],
        ),
      ),
    );
  }

  Widget _banner(BuildContext context, IconData icon, Color color, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppStyles.bodyMedium.copyWith(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, dynamic postedBy, BookingStatus status, String phone) {
    final name = JobDisplay.personName(postedBy, fallback: JobDisplay.safeText(job['clientName']));
    final avatar = JobDisplay.personAvatar(postedBy, fallback: JobDisplay.safeText(job['clientImage']));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          AppAvatar(url: avatar, name: name, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'ui_client'.tr : name,
                    style: AppStyles.h2Of(context).copyWith(fontSize: 17)),
                const SizedBox(height: 6),
                JobStatusBadge(status: status, waitingConfirmation: _finished),
              ],
            ),
          ),
          IconButton(
            tooltip: 'btn_chat'.tr,
            onPressed: _chatWithClient,
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
          ),
          if (phone.isNotEmpty)
            IconButton(
              tooltip: 'job_call_client'.tr,
              onPressed: () => _callClient(phone),
              icon: const Icon(Icons.call_outlined, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openLiveMap,
              icon: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
              label: Text(
                'ui_live_map'.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _openExternalDirections,
              icon: const Icon(Icons.directions, color: AppColors.primary, size: 20),
              label: Text(
                'ui_directions'.tr,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, BookingStatus status) {
    Widget primary(String label, VoidCallback onTap, {IconData? icon, Color? color}) => SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : onTap,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon ?? Icons.check, color: Colors.white, size: 20),
            label: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        );

    Widget outlined(String label, VoidCallback onTap, {Color color = AppColors.error}) => SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _busy ? null : onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        );

    final widgets = <Widget>[];
    if (_dispute || status == BookingStatus.completed || status == BookingStatus.cancelled) {
      return widgets;
    }

    if (!_finished) {
      switch (status) {
        case BookingStatus.inProgress:
          widgets.add(primary('job_start_travelling'.tr, _startTravelling,
              icon: Icons.directions_car_outlined));
          break;
        case BookingStatus.onTheWay:
          widgets.add(primary('job_i_arrived'.tr, _arrived, icon: Icons.flag_outlined));
          break;
        case BookingStatus.arrived:
          widgets.add(primary('job_work_finished'.tr, _workFinished,
              icon: Icons.task_alt, color: const Color(0xFF0D9488)));
          break;
        default:
          break;
      }
    }

    final needsSupport = status == BookingStatus.arrived || _finished;
    if (needsSupport) {
      widgets
        ..add(const SizedBox(height: 12))
        ..add(outlined('job_report_problem'.tr, _reportProblem, color: Colors.orange.shade800));
    } else {
      widgets
        ..add(const SizedBox(height: 12))
        ..add(outlined('booking_cancel_booking'.tr, _cancel))
        ..add(const SizedBox(height: 8))
        ..add(Text(
          'job_helper_cancel_warning'.tr,
          style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
          textAlign: TextAlign.center,
        ))
        ..add(Center(
          child: TextButton(onPressed: _reportProblem, child: Text('job_report_problem'.tr)),
        ));
    }
    return widgets;
  }

  static String _n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildJobInfoTable(BuildContext context, Map job) {
    final categoryName = JobDisplay.categoryName(job['category'],
        fallback: JobDisplay.safeText(job['jobType'], fallback: 'ui_service'.tr));
    final bookingDate = AppDateTime.formatDateDisplay(job['date']?.toString() ?? '');
    final preferredTime = job['startTime'] != null
        ? [
            AppDateTime.formatTime12h(job['startTime']?.toString()),
            if (job['endTime'] != null) AppDateTime.formatTime12h(job['endTime']?.toString()),
          ].where((t) => t.isNotEmpty).join(' - ')
        : JobDisplay.safeText(job['preferredTime'], fallback: '');
    final location = JobDisplay.safeLocation(job);
    final total = (job['budget'] as num?)?.toDouble();
    final isHourly = job['budgetType'] == 'hourly' && job['hours'] != null && job['hourlyRate'] != null;
    final net = (job['helperNet'] as num?)?.toDouble();
    final fee = (job['feePercentage'] as num?)?.toDouble();
    final commission = (job['commissionDeducted'] as num?)?.toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'label_job_type'.tr, categoryName),
          _buildInfoRow(context, 'label_booking_date'.tr,
              bookingDate.isEmpty ? 'ui_not_provided'.tr : bookingDate),
          _buildInfoRow(context, 'label_preferred_time'.tr,
              preferredTime.isEmpty ? 'ui_not_provided'.tr : preferredTime),
          _buildInfoRow(context, 'label_location'.tr, location),
          if (total != null)
            _buildInfoRow(
              context,
              'label_budget'.tr,
              isHourly
                  ? 'MAD ${_n(total)}\n${'post_total_preview'.trParams({
                      'hours': _n((job['hours'] as num)),
                      'rate': _n((job['hourlyRate'] as num)),
                      'total': _n(total),
                    })}'
                  : 'MAD ${_n(total)}',
            ),
          _buildInfoRow(context, 'ui_payment_method'.tr,
              _isCash ? 'offer_pay_cash'.tr : 'offer_pay_online'.tr),
          if (_isCash && commission != null && commission > 0)
            _buildInfoRow(context, 'job_commission_held'.tr, 'MAD ${_n(commission)}'),
          if (!_isCash && net != null)
            _buildInfoRow(
              context,
              'job_you_will_receive'.tr,
              'MAD ${_n(net)}${fee != null ? ' (−${_n(fee)}%)' : ''}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor)),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionWithPhotos(BuildContext context, Map job) {
    final photos = (job['images'] as List? ?? job['photos'] as List? ?? []);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_job_description'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Text('label_tasks_required'.tr,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            job['description']?.toString() ?? '',
            style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5, color: context.textSecondaryColor),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('label_photos'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(photos.length, (index) {
                  final photoList = photos.map((p) => p.toString()).toList();
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: GestureDetector(
                      onTap: () => Get.to(
                        () => ImageViewerScreen(imageUrls: photoList, initialIndex: index),
                      ),
                      child: AppNetworkImage(
                        url: photos[index].toString(),
                        width: 95,
                        height: 95,
                        radius: 12,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
