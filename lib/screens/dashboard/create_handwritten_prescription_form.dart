import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class _Theme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Teal
  static const Color bgTint = Color(0xFFF8FAFC);
}

class CreateHandwrittenPrescriptionScreen extends StatefulWidget {
  final int dwUserId;
  final Map<String, dynamic> patientData;
  final List<dynamic> doctors;
  final Map<String, dynamic> partnerData;

  const CreateHandwrittenPrescriptionScreen({
    super.key,
    required this.dwUserId,
    required this.patientData,
    required this.doctors,
    required this.partnerData,
  });

  @override
  State<CreateHandwrittenPrescriptionScreen> createState() => _CreateHandwrittenPrescriptionScreenState();
}

class _CreateHandwrittenPrescriptionScreenState extends State<CreateHandwrittenPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form Fields
  late DateTime _reportDate;
  int? _selectedDoctorId;
  final TextEditingController _headingController = TextEditingController();
  final List<String> _selectedImagePaths = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _reportDate = DateTime.now();

    // Auto-select doctor if only 1 doctor is available
    if (widget.doctors.length == 1) {
      _selectedDoctorId = widget.doctors[0]['id'];
    }
  }

  @override
  void dispose() {
    _headingController.dispose();
    super.dispose();
  }

  Future<void> _selectReportDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _Theme.accent,
            onPrimary: Colors.white,
            onSurface: _Theme.primary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: _Theme.accent,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _reportDate = picked;
      });
    }
  }

  String _formatDocDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDbDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? file = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1920,
        );
        if (file != null) {
          setState(() {
            _selectedImagePaths.add(file.path);
          });
        }
      } else {
        final List<XFile> files = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1920,
        );
        if (files.isNotEmpty) {
          setState(() {
            _selectedImagePaths.addAll(files.map((file) => file.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomAlerts.showError(context, 'Failed to pick image: ${e.toString()}');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImagePaths.isEmpty) {
      CustomAlerts.showError(context, 'Please attach at least one image of the prescription.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (!mounted) return;
      if (token == null) {
        setState(() {
          _isSubmitting = false;
        });
        CustomAlerts.showError(context, 'Authentication token missing.');
        return;
      }

      final response = await ApiService.createHandwrittenPrescription(
        dwUserId: widget.dwUserId,
        dateOfReport: _formatDbDate(_reportDate),
        heading: _headingController.text.trim(),
        opdDoctorId: _selectedDoctorId,
        imagePaths: _selectedImagePaths,
        token: token,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      if (response['success'] == true) {
        CustomAlerts.showSuccess(context, 'Handwritten prescription saved successfully!');
        Navigator.pop(context, true); // Return success to reload
      } else {
        CustomAlerts.showError(context, response['message'] ?? 'Failed to save prescription.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      CustomAlerts.showError(context, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicName = widget.partnerData['partner_clinic_name'] ?? 'N/A';

    return Scaffold(
      backgroundColor: _Theme.bgTint,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _Theme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Handwritten Prescription',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            color: _Theme.primary,
            fontSize: 17,
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(color: _Theme.accent),
            )
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                children: [
                  _buildSectionCard(
                    title: 'Prescription Info',
                    icon: Icons.edit_note_rounded,
                    children: [
                      _buildDatePickerField(
                        label: 'Date of Report',
                        value: _formatDocDate(_reportDate),
                        onTap: _selectReportDate,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _buildReadOnlyField(
                        label: 'Clinic Name',
                        value: clinicName,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField<int>(
                        label: 'OPD Doctor',
                        value: _selectedDoctorId,
                        isRequired: true,
                        items: widget.doctors.map<DropdownMenuItem<int>>((doc) {
                          return DropdownMenuItem<int>(
                            value: doc['id'],
                            child: Text(
                              '${doc['doctor_name']} - ${doc['doctor_specialist']}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _Theme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDoctorId = val;
                          });
                        },
                        validator: (value) => value == null ? 'Doctor is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Heading / Title',
                        controller: _headingController,
                        placeholder: 'e.g. Prescription - Dr. Sharma',
                        isRequired: true,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Heading is required' : null,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Attachments',
                    icon: Icons.image_outlined,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Upload Scanned Images',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: _Theme.accent),
                                label: Text(
                                  'Camera',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _Theme.accent,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _Theme.accent.withAlpha(10),
                                  side: BorderSide(color: _Theme.accent.withAlpha(60)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 16, color: _Theme.accent),
                                label: Text(
                                  'Gallery',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _Theme.accent,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _Theme.accent.withAlpha(10),
                                  side: BorderSide(color: _Theme.accent.withAlpha(60)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImagePaths.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Selected Images (${_selectedImagePaths.length}):',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _Theme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _selectedImagePaths.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_selectedImagePaths[index]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(160),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ] else
                        Container(
                          height: 85,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  'No images selected',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Accepted: JPG, PNG, WEBP — max 5MB each',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.blueGrey.withAlpha(20))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSubmitting ? 'Saving...' : 'Save Record',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Theme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withAlpha(22), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Theme.accent.withAlpha(15),
                  border: Border.all(color: _Theme.accent.withAlpha(30), width: 1.0),
                ),
                child: Icon(icon, color: _Theme.accent, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _Theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4.5),
        Container(
          width: double.infinity,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.apartment_rounded, color: Color(0xFF64748B), size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _Theme.primary,
                  ),
                ),
              ),
              const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4.5),
        SizedBox(
          height: maxLines == 1 ? 42 : null,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: _inputDecoration(placeholder, prefixIcon: Icons.title_rounded),
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Theme.primary,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    bool isRequired = false,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4.5),
        SizedBox(
          height: 42,
          child: DropdownButtonFormField<T>(
            isExpanded: true,
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: _inputDecoration('Select Option', prefixIcon: Icons.medical_services_outlined),
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Theme.primary,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4.5),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Theme.primary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 12.5,
        color: const Color(0xFF94A3B8),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 17)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Theme.accent, width: 1.4),
      ),
    );
  }
}
