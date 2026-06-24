import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class _Theme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Teal
  static const Color accentLight = Color(0xFFF0FDFA);
  static const Color bgTint = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

class CreatePrescriptionScreen extends StatefulWidget {
  final int dwUserId;
  final Map<String, dynamic> patientData;
  final List<dynamic> doctors;
  final Map<String, dynamic> vitals;

  const CreatePrescriptionScreen({
    super.key,
    required this.dwUserId,
    required this.patientData,
    required this.doctors,
    required this.vitals,
  });

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form Fields
  late DateTime _prescriptionDate;
  int? _selectedDoctorId;
  
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _headingController = TextEditingController();
  
  // Symptoms
  final List<String> _commonSymptoms = [
    'Fever', 'Cough', 'Cold', 'Headache', 'Body Pain', 
    'Weakness', 'Dizziness', 'Nausea', 'Vomiting', 
    'Sore Throat', 'Abdominal Pain', 'Shortness of Breath'
  ];
  final Set<String> _selectedSymptoms = {};
  bool _showOtherSymptomInput = false;
  final TextEditingController _otherSymptomController = TextEditingController();

  // Recommended Tests
  final List<Map<String, dynamic>> _recommendedTests = [];
  
  // Medicines
  final List<Map<String, dynamic>> _medicines = [];

  // Instructions
  final TextEditingController _medicalInstructionsController = TextEditingController();
  final TextEditingController _dietInstructionsController = TextEditingController();

  // Follow-up
  DateTime? _nextVisitDate;
  String _repeatTestsRequired = 'no';
  final TextEditingController _emergencyNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prescriptionDate = DateTime.now();
    
    // Pre-fill fields from patient & vitals
    if (widget.patientData['dob'] != null) {
      try {
        final dob = DateTime.parse(widget.patientData['dob'].toString());
        final age = DateTime.now().year - dob.year;
        _ageController.text = '$age Yrs';
      } catch (_) {}
    }
    
    _selectedGender = widget.patientData['gender'];
    if (_selectedGender != 'Male' && _selectedGender != 'Female' && _selectedGender != 'Other') {
      _selectedGender = null;
    }

    _bloodGroupController.text = widget.patientData['blood_group'] ?? widget.vitals['blood_group'] ?? '';
    _bpController.text = widget.vitals['blood_pressure'] ?? '';
    _pulseController.text = widget.vitals['heart_rate'] != null ? widget.vitals['heart_rate'].toString() : '';
    _spo2Controller.text = widget.vitals['spo'] != null ? widget.vitals['spo'].toString() : '';
    _weightController.text = widget.vitals['weight'] != null ? widget.vitals['weight'].toString() : '';

    // Auto-select doctor if only 1 doctor is available
    if (widget.doctors.length == 1) {
      _selectedDoctorId = widget.doctors[0]['id'];
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _bloodGroupController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _headingController.dispose();
    _otherSymptomController.dispose();
    _medicalInstructionsController.dispose();
    _dietInstructionsController.dispose();
    _emergencyNoteController.dispose();
    super.dispose();
  }

  Future<void> _selectPrescriptionDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _prescriptionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _prescriptionDate = picked;
      });
    }
  }

  Future<void> _selectNextVisitDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _nextVisitDate = picked;
      });
    }
  }

  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _Theme.accent,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: _Theme.primary,
        ),
      ),
      child: child!,
    );
  }

  void _addTestRow() {
    setState(() {
      _recommendedTests.add({
        'name': '',
        'priority': 'Normal',
        'notes': '',
      });
    });
  }

  void _removeTestRow(int index) {
    setState(() {
      _recommendedTests.removeAt(index);
    });
  }

  void _addMedicineRow() {
    setState(() {
      _medicines.add({
        'name': '',
        'timing': <String>[], // frequency
        'eating': <String>[], // meal relation
        'days': '',
      });
    });
  }

  void _removeMedicineRow(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  void _showMultiSelectDialog({
    required String title,
    required List<String> options,
    required List<String> selectedItems,
    required Function(List<String>) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedItems);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                title,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: _Theme.primary, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: options.map((option) {
                    final isChecked = tempSelected.contains(option);
                    return CheckboxListTile(
                      title: Text(
                        option,
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: _Theme.primary),
                      ),
                      value: isChecked,
                      activeColor: _Theme.accent,
                      onChanged: (bool? val) {
                        setDialogState(() {
                          if (val == true) {
                            tempSelected.add(option);
                          } else {
                            tempSelected.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(color: _Theme.textSecondary, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onConfirm(tempSelected);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'OK',
                    style: GoogleFonts.manrope(color: _Theme.accent, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDocDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}";
  }

  String _formatDbDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) {
      CustomAlerts.showError(context, 'Please fill in all required fields.');
      return;
    }

    if (_selectedDoctorId == null) {
      CustomAlerts.showError(context, 'Please select an OPD doctor.');
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

      // Collect symptoms
      List<String> symptomsPayload = _selectedSymptoms.toList();
      if (_showOtherSymptomInput && _otherSymptomController.text.trim().isNotEmpty) {
        symptomsPayload.add(_otherSymptomController.text.trim());
      }

      final payload = {
        'dw_user_id': widget.dwUserId,
        'opd_doctor_id': _selectedDoctorId,
        'prescription_date': _formatDbDate(_prescriptionDate),
        'user_age': _ageController.text.trim(),
        'user_gender': _selectedGender,
        'blood_group': _bloodGroupController.text.trim(),
        'bp': _bpController.text.trim(),
        'pulse': _pulseController.text.trim(),
        'spo2': _spo2Controller.text.trim(),
        'temperature': _tempController.text.trim(),
        'weight': _weightController.text.trim(),
        'heading': _headingController.text.trim(),
        'symptoms': symptomsPayload,
        'tests': _recommendedTests,
        'medicines': _medicines.map((m) => {
          'name': m['name'],
          'timing': m['timing'],
          'eating': m['eating'],
          'days': m['days'],
        }).toList(),
        'medical_instructions': _medicalInstructionsController.text.trim(),
        'diet_instructions': _dietInstructionsController.text.trim(),
        'next_visit_date': _nextVisitDate != null ? _formatDbDate(_nextVisitDate!) : null,
        'repeat_tests_required': _repeatTestsRequired,
        'emergency_note': _emergencyNoteController.text.trim(),
      };

      final response = await ApiService.createPrescription(payload: payload, token: token);
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      if (response['success'] == true) {
        CustomAlerts.showSuccess(context, 'Digital prescription saved successfully!');
        Navigator.pop(context, true); // Return success to reload
      } else {
        CustomAlerts.showError(context, response['message'] ?? 'Failed to save digital prescription.');
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
          'Create Prescription',
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
                  // Basic Details Card
                  _buildSectionCard(
                    title: 'Prescription Metadata',
                    icon: Icons.assignment_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerField(
                              label: 'Prescription Date *',
                              value: _formatDocDate(_prescriptionDate),
                              onTap: _selectPrescriptionDate,
                            ),
                          ),
                        ],
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
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: _Theme.primary),
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
                    ],
                  ),

                  // Patient Health Parameters Card
                  _buildSectionCard(
                    title: 'Health Parameters / Vitals',
                    icon: Icons.heart_broken_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Age',
                              controller: _ageController,
                              placeholder: 'e.g. 25 Yrs',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Gender',
                              value: _selectedGender,
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedGender = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Blood Group',
                              controller: _bloodGroupController,
                              placeholder: 'O+',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              label: 'BP (mmHg)',
                              controller: _bpController,
                              placeholder: '120/80',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Pulse (bpm)',
                              controller: _pulseController,
                              placeholder: '72',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              label: 'SpO2 (%)',
                              controller: _spo2Controller,
                              placeholder: '98',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Temp (°F)',
                              controller: _tempController,
                              placeholder: '98.6',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              label: 'Weight (kg)',
                              controller: _weightController,
                              placeholder: '70',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Heading
                  _buildSectionCard(
                    title: 'Diagnosis Heading',
                    icon: Icons.title_rounded,
                    children: [
                      _buildTextField(
                        label: 'Heading / Title *',
                        controller: _headingController,
                        placeholder: 'e.g. Follow-up for Thyroid / Fever Checkup',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Heading is required' : null,
                      ),
                    ],
                  ),

                  // Symptoms Card
                  _buildSectionCard(
                    title: 'Symptoms / Complaints',
                    icon: Icons.sick_rounded,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonSymptoms.map((symptom) {
                          final isSelected = _selectedSymptoms.contains(symptom);
                          return FilterChip(
                            label: Text(symptom),
                            selected: isSelected,
                            selectedColor: _Theme.accentLight,
                            checkmarkColor: _Theme.accent,
                            labelStyle: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? _Theme.accent : _Theme.primary,
                            ),
                            side: BorderSide(
                              color: isSelected ? _Theme.accent : _Theme.border,
                              width: 1,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSymptoms.add(symptom);
                                } else {
                                  _selectedSymptoms.remove(symptom);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _showOtherSymptomInput,
                            activeColor: _Theme.accent,
                            onChanged: (val) {
                              setState(() {
                                _showOtherSymptomInput = val ?? false;
                              });
                            },
                          ),
                          Text(
                            'Other symptoms...',
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: _Theme.primary),
                          ),
                        ],
                      ),
                      if (_showOtherSymptomInput) ...[
                        const SizedBox(height: 8),
                        _buildTextField(
                          label: 'Specify Other Symptoms',
                          controller: _otherSymptomController,
                          placeholder: 'Type other symptoms here...',
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),

                  // Recommended Tests Card
                  _buildSectionCard(
                    title: 'Recommended Tests',
                    icon: Icons.science_outlined,
                    children: [
                      if (_recommendedTests.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'No tests added yet.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: _Theme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recommendedTests.length,
                          itemBuilder: (context, index) {
                            final test = _recommendedTests[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _Theme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Test #${index + 1}',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: _Theme.accent,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => _removeTestRow(index),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: _inputDecoration('Test Name *'),
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Test Name is required' : null,
                                    onChanged: (val) => test['name'] = val,
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: test['priority'],
                                    decoration: _inputDecoration('Priority'),
                                    items: const [
                                      DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                                      DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                                      DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                                    ],
                                    onChanged: (val) => setState(() => test['priority'] = val),
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: _Theme.primary),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    decoration: _inputDecoration('Notes / Instructions'),
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary),
                                    onChanged: (val) => test['notes'] = val,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: _addTestRow,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'Add Test',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _Theme.accent,
                          side: const BorderSide(color: _Theme.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),

                  // Medicines Card
                  _buildSectionCard(
                    title: 'Medicines / Rx',
                    icon: Icons.medication_liquid_rounded,
                    children: [
                      if (_medicines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'No medicines added yet.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: _Theme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _medicines.length,
                          itemBuilder: (context, index) {
                            final med = _medicines[index];
                            final List<String> timing = med['timing'] as List<String>? ?? [];
                            final List<String> eating = med['eating'] as List<String>? ?? [];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _Theme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Medicine #${index + 1}',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: _Theme.accent,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => _removeMedicineRow(index),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: _inputDecoration('Medicine Name *'),
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Medicine Name is required' : null,
                                    onChanged: (val) => med['name'] = val,
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Frequency Selection
                                  InkWell(
                                    onTap: () {
                                      _showMultiSelectDialog(
                                        title: 'Frequency (Times a Day)',
                                        options: const [
                                          'OD / OD / QD (Omni Die / Quaque Die): Once a day',
                                          'BD / BID (Bis in Die): Twice a day',
                                          'TDS / TID (Ter in Die): Three times a day',
                                          'QID (Quater in Die): Four times a day',
                                          'Q4H / Q6H / Q8H: Every 4/6/8 hours',
                                          'Tw: Three times a week',
                                        ],
                                        selectedItems: timing,
                                        onConfirm: (list) {
                                          setState(() {
                                            med['timing'] = list;
                                          });
                                        },
                                      );
                                    },
                                    child: InputDecorator(
                                      decoration: _inputDecoration('Frequency'),
                                      child: Text(
                                        timing.isEmpty ? 'Select Frequency' : timing.join(', '),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: timing.isEmpty ? _Theme.textSecondary.withValues(alpha: 0.6) : _Theme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Relation to meals
                                  InkWell(
                                    onTap: () {
                                      _showMultiSelectDialog(
                                        title: 'Time & Relation to Meals',
                                        options: const [
                                          'AC / PC: Before or after meals',
                                          'HS / BT: At bedtime',
                                          'QAM / QPM: Morning or evening',
                                          'Stat / SOS / PRN: Immediately or as needed',
                                        ],
                                        selectedItems: eating,
                                        onConfirm: (list) {
                                          setState(() {
                                            med['eating'] = list;
                                          });
                                        },
                                      );
                                    },
                                    child: InputDecorator(
                                      decoration: _inputDecoration('Relation to Meals'),
                                      child: Text(
                                        eating.isEmpty ? 'Select Relation' : eating.join(', '),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: eating.isEmpty ? _Theme.textSecondary.withValues(alpha: 0.6) : _Theme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  TextFormField(
                                    decoration: _inputDecoration('Duration (Days)'),
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _Theme.primary),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => med['days'] = val,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: _addMedicineRow,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'Add Medicine',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _Theme.accent,
                          side: const BorderSide(color: _Theme.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),

                  // Advice & Instructions Card
                  _buildSectionCard(
                    title: 'Advice & Diet Instructions',
                    icon: Icons.chat_bubble_outline_rounded,
                    children: [
                      _buildTextField(
                        label: 'Medical Instructions',
                        controller: _medicalInstructionsController,
                        placeholder: 'e.g. Complete bed rest, Drink warm water...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        label: 'Diet Instructions',
                        controller: _dietInstructionsController,
                        placeholder: 'e.g. Avoid oily foods, Eat high fiber diet...',
                        maxLines: 3,
                      ),
                    ],
                  ),

                  // Follow Up Card
                  _buildSectionCard(
                    title: 'Follow Up details',
                    icon: Icons.calendar_today_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerField(
                              label: 'Next Visit Date',
                              value: _nextVisitDate == null ? 'Not Scheduled' : _formatDocDate(_nextVisitDate!),
                              onTap: _selectNextVisitDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repeat Tests Required?',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _Theme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          RadioGroup<String>(
                            groupValue: _repeatTestsRequired,
                            onChanged: (val) {
                              setState(() {
                                _repeatTestsRequired = val!;
                              });
                            },
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'yes',
                                  activeColor: _Theme.accent,
                                ),
                                Text(
                                  'Yes',
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: _Theme.primary),
                                ),
                                const SizedBox(width: 20),
                                Radio<String>(
                                  value: 'no',
                                  activeColor: _Theme.accent,
                                ),
                                Text(
                                  'No',
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: _Theme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Emergency Note',
                        controller: _emergencyNoteController,
                        placeholder: 'e.g. If temperature exceeds 103 F, visit emergency.',
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // Save Button
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitPrescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'SAVE PRESCRIPTION',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
