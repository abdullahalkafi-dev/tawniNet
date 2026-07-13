import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
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
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  String _priceType = 'fixed';
  String _paymentMethod = 'cash';
  final List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editOffer?.title ?? '');
    _descController = TextEditingController(text: widget.editOffer?.description ?? '');
    _priceController = TextEditingController(
      text: widget.editOffer?.price.toString() ?? '',
    );
    _startTimeController = TextEditingController(text: widget.editOffer?.startTime ?? '');
    _endTimeController = TextEditingController(text: widget.editOffer?.endTime ?? '');

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
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildLabel('Service Title'),
                  TextField(
                    controller: _titleController,
                    decoration: _buildInputDecoration('e.g., House Cleaning'),
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel('Description'),
                  TextField(
                    controller: _descController,
                    decoration: _buildInputDecoration('Describe your service'),
                    maxLines: 3,
                    maxLength: 2000,
                  ),
                  const SizedBox(height: 16),

                  // Price
                  _buildLabel('Price (MAD)'),
                  TextField(
                    controller: _priceController,
                    decoration: _buildInputDecoration('0'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Price Type
                  _buildLabel('Price Type'),
                  Row(
                    children: [
                      _buildChoiceChip('Fixed', 'fixed', _priceType, (val) {
                        setState(() => _priceType = val);
                      }),
                      const SizedBox(width: 8),
                      _buildChoiceChip('Hourly', 'hourly', _priceType, (val) {
                        setState(() => _priceType = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time Range
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Start Time'),
                            TextField(
                              controller: _startTimeController,
                              decoration: _buildInputDecoration('09:00'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('End Time'),
                            TextField(
                              controller: _endTimeController,
                              decoration: _buildInputDecoration('17:00'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  _buildLabel('Payment Method'),
                  Row(
                    children: [
                      _buildChoiceChip('Cash', 'cash', _paymentMethod, (val) {
                        setState(() => _paymentMethod = val);
                      }),
                      const SizedBox(width: 8),
                      _buildChoiceChip('Online', 'online', _paymentMethod, (val) {
                        setState(() => _paymentMethod = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Images
                  _buildLabel('Images (max 4)'),
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
                                      img,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
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
                            onTap: _addImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.grey,
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
              color: Colors.white,
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
                onPressed: _submitOffer,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildChoiceChip(
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
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _addImage() async {
    if (_selectedImages.length >= 4) {
      Get.snackbar('Error', 'Maximum 4 images allowed',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    try {
      final api = Get.find<ApiClient>();
      final formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(pickedFile.path),
      });

      final response = await api.upload<dynamic>(
        ApiConstants.uploadImage,
        formData: formData,
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['key'] != null) {
          setState(() {
            _selectedImages.add(data['key']);
          });
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image',
          snackPosition: SnackPosition.BOTTOM);
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

    widget.onOfferSent({
      'title': title,
      'description': _descController.text.trim(),
      'price': price,
      'priceType': _priceType,
      'startTime': _startTimeController.text.trim(),
      'endTime': _endTimeController.text.trim(),
      'paymentMethod': _paymentMethod,
      'images': _selectedImages,
    });

    Navigator.pop(context);
  }
}
