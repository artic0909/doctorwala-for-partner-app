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
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
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
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionCard(
                    title: 'Prescription Info',
                    icon: Icons.edit_note_rounded,
                    children: [
                      _buildDatePickerField(
                        label: 'Date of Report *',
                        value: _formatDocDate(_reportDate),
                        onTap: _selectReportDate,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        label: 'Clinic Name (Readonly)',
                        value: clinicName,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField<int>(
                        label: 'OPD Doctor *',
                        value: _selectedDoctorId,
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
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Heading / Title *',
                        controller: _headingController,
                        placeholder: 'e.g. Prescription - Dr. Sharma',
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Heading is required' : null,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Attachments',
                    icon: Icons.image_outlined,
                    children: [
                      Text(
                        'Upload Scanned Images *',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _Theme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded, size: 16),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _Theme.bgTint,
                                foregroundColor: _Theme.accent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: _Theme.border),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded, size: 16),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _Theme.bgTint,
                                foregroundColor: _Theme.accent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: _Theme.border),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImagePaths.isNotEmpty) ...[
                        Text(
                          'Selected Images (${_selectedImagePaths.length}):',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _Theme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
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
                                        color: Colors.black.withValues(alpha: 0.6),
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
                          height: 100,
                          decoration: BoxDecoration(
                            color: _Theme.bgTint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _Theme.border, style: BorderStyle.solid),
                          ),
                          child: Center(
                            child: Text(
                              'No images selected',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: _Theme.textSecondary.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Accepted: JPG, PNG, WEBP — max 5MB each',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _Theme.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Theme.accent,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Save Record',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _Theme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Theme.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
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
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _Theme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Light grey fill for read only
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Theme.border, width: 1.0),
          ),
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _Theme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _Theme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _inputDecoration(placeholder),
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _Theme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          isExpanded: true,
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: _inputDecoration('Select Option'),
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: _Theme.primary),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _Theme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _inputDecoration('Select Date'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary),
                ),
                const Icon(Icons.calendar_month_rounded, color: _Theme.accent, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 12.5,
        color: _Theme.textSecondary.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _Theme.bgTint,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Theme.border, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Theme.border, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Theme.accent, width: 1.2),
      ),
    );
  }
}
