import 'dart:async';

import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/simple_time_picker.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
                  _buildLabel(context, 'Service Title'),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: _buildInputDecoration(context, 'e.g., House Cleaning'),
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel(context, 'Description'),
                  TextField(
                    controller: _descController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: _buildInputDecoration(context, 'Describe your service'),
                    maxLines: 3,
                    maxLength: 2000,
                  ),
                  const SizedBox(height: 16),

                  // Price
                  _buildLabel(context, 'Price (MAD)'),
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
                  _buildLabel(context, 'Price Type'),
                  Row(
                    children: [
                      _buildChoiceChip(context, 'Fixed', 'fixed', _priceType, (val) {
                        setState(() => _priceType = val);
                      }),
                      const SizedBox(width: 8),
                      _buildChoiceChip(context, 'Hourly', 'hourly', _priceType, (val) {
                        setState(() => _priceType = val);
                      }),
                    ],
                  ),
                  if (_priceType == 'hourly') _buildHourlyEstimate(),
                  const SizedBox(height: 16),

                  // Date
                  _buildDateField(context, 'Date *', _dateController),
                  const SizedBox(height: 16),

                  // Time Range
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(context, 'Start Time', _startTimeController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeField(context, 'End Time', _endTimeController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Work location (search — no GPS)
                  _buildLabel(context, 'Work location *'),
                  _buildLocationField(context),
                  const SizedBox(height: 16),

                  // Payment Method
                  _buildLabel(context, 'Payment Method'),
                  Row(
                    children: [
                      _buildChoiceChip(context, 'Cash', 'cash', _paymentMethod, (val) {
                        setState(() => _paymentMethod = val);
                      }),
                      const SizedBox(width: 8),
                      _buildChoiceChip(context, 'Online', 'online', _paymentMethod, (val) {
                        setState(() => _paymentMethod = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Images
                  _buildLabel(context, 'Images (${_selectedImages.length}/4)'),
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
    final start = AppDateTime.tryParseTimeOfDay(_startTimeController.text);
    final end = AppDateTime.tryParseTimeOfDay(_endTimeController.text);
    String? estimate;
    if (rate > 0 && start != null && end != null) {
      var startMins = start.hour * 60 + start.minute;
      var endMins = end.hour * 60 + end.minute;
      var mins = endMins - startMins;
      if (mins <= 0) mins += 24 * 60;
      if (mins > 0) {
        final hours = mins / 60.0;
        final total = (rate * hours).round();
        estimate =
            '${hours.toStringAsFixed(2)} h × ${rate.toStringAsFixed(0)} MAD/h\n'
            'Client pays: $total MAD (rounded)';
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
              'Hourly estimate',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              estimate ??
                  'Set price + start/end time to see the rounded total.',
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
              hintText: 'Search street, city, landmark…',
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
              decoration: _buildInputDecoration(context, 'Select date').copyWith(
                suffixIcon: Icon(Icons.calendar_today, size: 20, color: context.textHintColor),
                hintText: 'Select date',
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
              decoration: _buildInputDecoration(context, 'Select time').copyWith(
                suffixIcon: Icon(Icons.access_time, size: 20, color: context.textHintColor),
                hintText: 'Select time',
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
      AppFeedback.error('Maximum 4 images allowed', title: 'Limit reached');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked.isEmpty) return;

    final remaining = 4 - _selectedImages.length;
    final toUpload = picked.take(remaining).toList();
    final skipped = picked.length - toUpload.length;

    if (skipped > 0) {
      AppFeedback.error(
        'Only 4 images allowed. $skipped image(s) were not added.',
        title: 'Limit reached',
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
            ? 'Failed to upload images. Please try again.'
            : 'Failed to upload $failed of ${toUpload.length} image(s).',
      );
    }
  }

  void _submitOffer() {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a service title')),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
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
        const SnackBar(content: Text('Please select a date for this job')),
      );
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a work location')),
      );
      return;
    }
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a location from the search results'),
        ),
      );
      return;
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
      if (_selectedLatitude != null) 'latitude': _selectedLatitude,
      if (_selectedLongitude != null) 'longitude': _selectedLongitude,
      'paymentMethod': _paymentMethod,
      'images': _selectedImages,
    });

    Navigator.pop(context);
  }
}
