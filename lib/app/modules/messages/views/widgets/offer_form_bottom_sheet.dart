import 'dart:async';

import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/simple_time_picker.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/widgets/location_map_picker.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awnneaapp/app/core/utils/image_picker_errors.dart';

class OfferFormBottomSheet extends StatefulWidget {
  final String conversationId;
  final OfferData? editOffer;
  final Function(Map<String, dynamic>) onOfferSent;

  const OfferFormBottomSheet({
    super.key,
    required this.conversationId,
    required this.onOfferSent,
    this.editOffer,
  });

  @override
  State<OfferFormBottomSheet> createState() => _OfferFormBottomSheetState();
}

class _OfferFormBottomSheetState extends State<OfferFormBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _dateController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _addressController;

  String _priceType = 'fixed';
  String _paymentMethod = 'cash';
  final List<String> _selectedImages = [];
  String? _isoDate;
  bool _isUploadingImages = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _addressDebounce;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editOffer?.title ?? '');
    _descController = TextEditingController(text: widget.editOffer?.description ?? '');
    _priceController = TextEditingController(
      text: widget.editOffer?.price.toString() ?? '',
    );
    _addressController = TextEditingController(text: widget.editOffer?.address ?? '');
    _selectedLatitude = widget.editOffer?.latitude;
    _selectedLongitude = widget.editOffer?.longitude;

    final rawDate = widget.editOffer?.date ?? '';
    final parsedDate = AppDateTime.tryParseDate(rawDate);
    if (parsedDate != null) {
      _isoDate = AppDateTime.toIsoDate(parsedDate);
      _dateController = TextEditingController(
        text: AppDateTime.formatDateDisplay(_isoDate),
      );
    } else {
      _dateController = TextEditingController(text: rawDate);
    }

    _startTimeController = TextEditingController(
      text: AppDateTime.formatTime12h(widget.editOffer?.startTime ?? ''),
    );
    _endTimeController = TextEditingController(
      text: AppDateTime.formatTime12h(widget.editOffer?.endTime ?? ''),
    );

    if (widget.editOffer != null) {
      _priceType = widget.editOffer!.priceType;
      _paymentMethod = widget.editOffer!.paymentMethod;
      _selectedImages.addAll(widget.editOffer!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _addressController.dispose();
    _addressDebounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.length < 3) {
        if (mounted) setState(() => _addressSuggestions = []);
        return;
      }
      if (!mounted) return;
      setState(() => _isSearchingAddress = true);
      try {
        final locService = Get.find<LocationService>();
        final results = await locService.searchPlaces(q);
        if (!mounted) return;
        setState(() => _addressSuggestions = results);
      } catch (_) {
        if (mounted) setState(() => _addressSuggestions = []);
      } finally {
        if (mounted) setState(() => _isSearchingAddress = false);
      }
    });
  }

  void _selectAddressSuggestion(Map<String, dynamic> suggestion) {
    final address =
        (suggestion['displayName'] ?? suggestion['address'])?.toString() ?? '';
    final lat = ((suggestion['lat'] ?? suggestion['latitude']) as num?)?.toDouble();
    final lng = ((suggestion['lon'] ?? suggestion['longitude']) as num?)?.toDouble();
    setState(() {
      _addressController.text = address;
      _selectedLatitude = lat;
      _selectedLongitude = lng;
      _addressSuggestions = [];
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (Get.isRegistered<LocationService>()) {
        final loc = Get.find<LocationService>();
        final address = await loc.getCurrentAddress();
        if (address != null && address.isNotEmpty) {
          setState(() {
            _addressController.text = address;
            _selectedLatitude = loc.currentLatitude.value;
            _selectedLongitude = loc.currentLongitude.value;
            _addressSuggestions = [];
          });
          return;
        }
      }
    } catch (_) {}
    AppFeedback.info('ui_could_not_fetch_current_location_coordinates'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  widget.editOffer != null ? 'Edit Offer' : 'Create Offer',
                  style: AppStyles.h2Of(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: context.textPrimaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.borderSubtle),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildLabel(context, 'ui_service_title'.tr),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: _buildInputDecoration(context, 'e.g., House Cleaning'),
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel(context, 'ui_description'.tr),
                  TextField(
                    controller: _descController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: _buildInputDecoration(context, 'ui_describe_your_service'.tr),
                    maxLines: 3,
                    maxLength: 2000,
                  ),
                  const SizedBox(height: 16),

                  // Price
                  _buildLabel(context, 'ui_price_mad'.tr),
                  TextField(
                    controller: _priceController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: _buildInputDecoration(context, '0'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Price Type
                  _buildLabel(context, 'ui_price_type'.tr),
                  Row(
                    children: [
                      _buildChoiceChip(context, 'ui_fixed'.tr, 'fixed', _priceType, (val) {
                        setState(() => _priceType = val);
                      }),
                      const SizedBox(width: 8),
                      _buildChoiceChip(context, 'ui_hourly'.tr, 'hourly', _priceType, (val) {
                        setState(() => _priceType = val);
                      }),
                    ],
                  ),
                  if (_priceType == 'hourly') _buildHourlyEstimate(),
                  const SizedBox(height: 16),

                  // Date
                  _buildDateField(context, 'ui_date'.tr, _dateController),
                  const SizedBox(height: 16),

                  // Time Range
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(context, 'ui_start_time'.tr, _startTimeController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeField(context, 'ui_end_time'.tr, _endTimeController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Work location (search — no GPS)
                  _buildLabel(context, 'ui_work_location'.tr),
                  _buildLocationField(context),
                  const SizedBox(height: 16),

                  // Payment Method
                  _buildLabel(context, 'ui_payment_method'.tr),
                  Row(
                    children: [
                      _buildChoiceChip(context, 'ui_cash'.tr, 'cash', _paymentMethod, (val) {
                        setState(() => _paymentMethod = val);
                      }),
                      const SizedBox(width: 8),
                      _buildChoiceChip(context, 'earning_online'.tr, 'online', _paymentMethod, (val) {
                        setState(() => _paymentMethod = val);
                      }),
                    ],
                  ),
                  if (_paymentMethod == 'cash') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ui_platform_commission_20_is_held_from_your'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Images
                  _buildLabel(context, 'ui_images_count_of_4'.trParams({'count': '${_selectedImages.length}'})),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._selectedImages.map((img) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      ApiConstants.resolveImageUrl(img) ?? img,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: context.inputFillColor,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: context.textHintColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.remove(img);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (_selectedImages.length < 4)
                          GestureDetector(
                            onTap: _isUploadingImages ? null : _addImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: context.inputFillColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.borderSubtle),
                              ),
                              child: _isUploadingImages
                                  ? const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: context.textHintColor,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploadingImages ? null : _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.editOffer != null ? 'Update Offer' : 'Send Offer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyEstimate() {
    final rate = double.tryParse(_priceController.text.trim()) ?? 0;
    final mins = AppDateTime.minutesBetween(
      _startTimeController.text,
      _endTimeController.text,
    );
    String? estimate;
    if (rate > 0 && mins != null) {
      if (mins <= 0) {
        estimate = 'time_end_after_start'.tr;
      } else {
        final hours = mins / 60.0;
        final total = (rate * hours).round();
        estimate =
            'ui_hourly_estimate_detail'.trParams({
              'hours': hours.toStringAsFixed(2),
              'rate': rate.toStringAsFixed(0),
              'total': '$total',
            });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ui_hourly_estimate'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              estimate ??
                  'ui_set_price_start_end_time_to_see'.tr,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: TextField(
            controller: _addressController,
            style: TextStyle(color: context.textPrimaryColor),
            onChanged: _onAddressChanged,
            decoration: InputDecoration(
              hintText: 'ui_search_street_city_landmark'.tr,
              hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              prefixIcon: Icon(Icons.location_on_outlined, color: context.textHintColor, size: 20),
              suffixIcon: _isSearchingAddress
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _useCurrentLocation,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'post_use_location'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await LocationMapPicker.show(
                  context,
                  initialLatitude: _selectedLatitude,
                  initialLongitude: _selectedLongitude,
                  initialAddress: _addressController.text.trim(),
                );
                if (picked != null) {
                  setState(() {
                    _addressController.text = picked.address;
                    _selectedLatitude = picked.latitude;
                    _selectedLongitude = picked.longitude;
                    _addressSuggestions = [];
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'post_choose_on_map'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_addressSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtle),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _addressSuggestions.length,
              itemBuilder: (context, index) {
                final result = _addressSuggestions[index];
                final displayName = (result['displayName'] ?? '').toString();
                return InkWell(
                  onTap: () => _selectAddressSuggestion(result),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final initial = _isoDate != null
                ? (AppDateTime.tryParseDate(_isoDate!) ?? now)
                : (AppDateTime.tryParseDate(controller.text) ?? now);
            final picked = await showDatePicker(
              context: context,
              initialDate: initial.isBefore(now)
                  ? now
                  : (initial.isAfter(now.add(const Duration(days: 365)))
                      ? now
                      : initial),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              _isoDate = AppDateTime.toIsoDate(picked);
              controller.text = AppDateTime.formatDateDisplay(_isoDate);
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: _buildInputDecoration(context, 'ui_select_date'.tr).copyWith(
                suffixIcon: Icon(Icons.calendar_today, size: 20, color: context.textHintColor),
                hintText: 'ui_select_date'.tr,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        GestureDetector(
          onTap: () async {
            final now = TimeOfDay.now();
            final picked = await showSimpleTimePicker(
              context,
              initialTime: AppDateTime.tryParseTimeOfDay(controller.text) ?? now,
            );
            if (picked != null) {
              controller.text = AppDateTime.formatTimeOfDay12h(picked);
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: _buildInputDecoration(context, 'ui_select_time'.tr).copyWith(
                suffixIcon: Icon(Icons.access_time, size: 20, color: context.textHintColor),
                hintText: 'ui_select_time'.tr,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textHintColor),
      filled: true,
      fillColor: context.inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.borderSubtle),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildChoiceChip(
    BuildContext context,
    String label,
    String value,
    String groupValue,
    Function(String) onSelected,
  ) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.inputFillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _addImage() async {
    if (_selectedImages.length >= 4) {
      AppFeedback.error('ui_maximum_4_images_allowed'.tr, title: 'ui_limit_reached_2'.tr);
      return;
    }

    final picker = ImagePicker();
    final List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (e) {
      AppFeedback.error(imagePickerErrorMessage(e));
      return;
    }
    if (picked.isEmpty) return;

    final remaining = 4 - _selectedImages.length;
    final toUpload = picked.take(remaining).toList();
    final skipped = picked.length - toUpload.length;

    if (skipped > 0) {
      AppFeedback.error(
        'ui_images_limit_skipped'.trParams({'max': '4', 'skipped': '$skipped'}),
        title: 'ui_limit_reached_2'.tr,
      );
    }

    setState(() => _isUploadingImages = true);
    var failed = 0;
    try {
      final api = Get.find<ApiClient>();
      for (final file in toUpload) {
        try {
          final formData = dio.FormData.fromMap({
            'file': await dio.MultipartFile.fromFile(file.path),
          });
          final response = await api.upload<dynamic>(
            ApiConstants.uploadImage,
            formData: formData,
          );
          if (response.success && response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final key = (data['key'] ?? data['url'])?.toString();
            if (key != null && key.isNotEmpty) {
              if (!mounted) return;
              setState(() => _selectedImages.add(key));
              continue;
            }
          }
          failed++;
        } catch (_) {
          failed++;
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }

    if (failed > 0 && mounted) {
      AppFeedback.error(
        failed == toUpload.length
            ? 'ui_failed_to_upload_images_retry'.tr
            : 'ui_failed_to_upload_some_images'.trParams({'failed': '$failed', 'total': '${toUpload.length}'}),
      );
    }
  }

  void _submitOffer() {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ui_please_enter_a_service_title'.tr)),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ui_please_enter_a_valid_price'.tr)),
      );
      return;
    }

    String? isoDate = _isoDate;
    if (isoDate == null && _dateController.text.trim().isNotEmpty) {
      final parsed = AppDateTime.tryParseDate(_dateController.text);
      if (parsed != null) isoDate = AppDateTime.toIsoDate(parsed);
    }
    if (isoDate == null || isoDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ui_please_select_a_date_for_this_job'.tr)),
      );
      return;
    }

    final timeError = AppDateTime.validateTimeRange(
      _startTimeController.text,
      _endTimeController.text,
    );
    if (timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeError)),
      );
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ui_please_select_a_work_location'.tr)),
      );
      return;
    }

    double? lat = _selectedLatitude;
    double? lon = _selectedLongitude;
    if ((lat == null || lon == null) && Get.isRegistered<LocationService>()) {
      final loc = Get.find<LocationService>();
      lat = loc.currentLatitude.value;
      lon = loc.currentLongitude.value;
    }

    widget.onOfferSent({
      'title': title,
      'description': _descController.text.trim(),
      'price': price,
      'priceType': _priceType,
      'date': isoDate,
      'startTime': AppDateTime.formatTime12h(_startTimeController.text),
      'endTime': AppDateTime.formatTime12h(_endTimeController.text),
      'address': address,
      if (lat != null) 'latitude': lat,
      if (lon != null) 'longitude': lon,
      'paymentMethod': _paymentMethod,
      'images': _selectedImages,
    });

    Navigator.pop(context);
  }
}
