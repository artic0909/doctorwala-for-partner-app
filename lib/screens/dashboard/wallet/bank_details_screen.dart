import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/session_manager.dart';

class BankDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const BankDetailsScreen({
    super.key,
    required this.partnerData,
  });

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  Future<void> _fetchBankDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.getBankDetails(token: token);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _bankAccounts = response['bank_accounts'] is List ? response['bank_accounts'] : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Unable to load bank accounts.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBankDetail(int bankId, String bankName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Delete Account?', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove $bankName? Payouts can no longer be processed to this account.',
          style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final res = await ApiService.deleteBankDetail(token: token, bankId: bankId);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account deleted successfully')),
        );
        _fetchBankDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to delete bank account')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _setPrimaryBank(int bankId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final res = await ApiService.setPrimaryBankDetail(token: token, bankId: bankId);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primary bank account updated')),
        );
        _fetchBankDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to set primary bank')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _openBankFormSheet({Map<String, dynamic>? initialData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BankFormBottomSheet(
        partnerData: widget.partnerData,
        initialData: initialData,
        onSaved: () {
          Navigator.pop(ctx);
          _fetchBankDetails();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchBankDetails,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _fetchBankDetails,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                    children: [
                      // Header action card
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Linked Accounts',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_bankAccounts.length} account${_bankAccounts.length == 1 ? '' : 's'} registered for payouts',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openBankFormSheet(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Bank'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_bankAccounts.isEmpty)
                        _buildEmptyState()
                      else
                        ..._bankAccounts.map((bank) => _buildBankCard(bank)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_outlined, size: 36, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          Text(
            'No Bank Accounts Linked',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your verified bank account details so that consultation fees and earnings can be settled directly to your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => _openBankFormSheet(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Bank Account Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank) {
    final isPrimary = bank['is_primary'] == true;
    final bankId = bank['id'] as int;
    final bankName = bank['bank_name'] ?? 'Bank Account';
    final accountNo = bank['masked_account_no'] ?? bank['account_no'] ?? '';
    final ifsc = bank['ifsc_code'] ?? '';
    final holder = bank['account_holder_name'] ?? '';
    final branch = bank['branch_name'] ?? 'Main Branch';
    final upiId = bank['upi_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPrimary ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? const Color(0xFF0284C7).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Color(0xFF16A34A), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankName,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          branch,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'PRIMARY',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Details box inside card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                _buildInfoRow('Account Number', accountNo, isMonospace: true),
                const SizedBox(height: 8),
                _buildInfoRow('IFSC Code', ifsc, isMonospace: true, isHighlight: true),
                if (holder.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Account Holder', holder),
                ],
                if (upiId != null && upiId.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('UPI ID', upiId.toString()),
                ],
              ],
            ),
          ),

          // Action buttons footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isPrimary)
                  OutlinedButton.icon(
                    onPressed: () => _setPrimaryBank(bankId),
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('Make Primary'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  )
                else
                  Text(
                    'Default payout account',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _openBankFormSheet(initialData: bank),
                      icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 24),
                      tooltip: 'Edit details',
                    ),
                    IconButton(
                      onPressed: () => _deleteBankDetail(bankId, bankName),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFF0284C7) : AppColors.textPrimary,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _BankFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final Map<String, dynamic>? initialData;
  final VoidCallback onSaved;

  const _BankFormBottomSheet({
    required this.partnerData,
    this.initialData,
    required this.onSaved,
  });

  @override
  State<_BankFormBottomSheet> createState() => _BankFormBottomSheetState();
}

class _BankFormBottomSheetState extends State<_BankFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNoCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _holderCtrl;
  late TextEditingController _upiCtrl;

  bool _isPrimary = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialData;
    _bankNameCtrl = TextEditingController(text: init?['bank_name'] ?? '');
    _accountNoCtrl = TextEditingController(text: init?['account_no'] ?? '');
    _ifscCtrl = TextEditingController(text: init?['ifsc_code'] ?? '');
    _branchCtrl = TextEditingController(text: init?['branch_name'] ?? '');
    _holderCtrl = TextEditingController(
      text: init?['account_holder_name'] ?? widget.partnerData['partner_contact_person_name'] ?? '',
    );
    _upiCtrl = TextEditingController(text: init?['upi_id'] ?? '');
    _isPrimary = init?['is_primary'] == true;
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _holderCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final payload = {
        'bank_name': _bankNameCtrl.text.trim(),
        'account_no': _accountNoCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim().toUpperCase(),
        'branch_name': _branchCtrl.text.trim(),
        'account_holder_name': _holderCtrl.text.trim(),
        'upi_id': _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
        'is_primary': _isPrimary,
      };

      final isEdit = widget.initialData != null;
      final Map<String, dynamic> res;

      if (isEdit) {
        final bankId = widget.initialData!['id'] as int;
        res = await ApiService.updateBankDetail(token: token, bankId: bankId, data: payload);
      } else {
        res = await ApiService.addBankDetail(token: token, data: payload);
      }

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save bank details')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = MediaQuery.of(context).viewPadding.bottom;
    final safeBottom = navBarPadding > 0 ? navBarPadding : MediaQuery.of(context).padding.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Drag handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Bank Account' : 'Add Bank Account',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.black54),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Form Fields
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank Name
                      TextFormField(
                        controller: _bankNameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Bank Name *', 'e.g. State Bank of India, HDFC'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Bank name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Account Number
                      TextFormField(
                        controller: _accountNoCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Account Number *', 'Enter complete account number'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Account number is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // IFSC & Branch
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ifscCtrl,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('IFSC Code *', 'e.g. SBIN0001234'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'IFSC required';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _branchCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('Branch Name', 'e.g. Salt Lake'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Account Holder
                      TextFormField(
                        controller: _holderCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Account Holder Name', 'Name as on passbook'),
                      ),
                      const SizedBox(height: 14),

                      // UPI ID
                      TextFormField(
                        controller: _upiCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration('UPI ID (Optional)', 'e.g. name@okhdfcbank'),
                      ),
                      const SizedBox(height: 12),

                      // Primary checkbox without ListTile to prevent ink splash warnings
                      InkWell(
                        onTap: () => setState(() => _isPrimary = !_isPrimary),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _isPrimary,
                                  onChanged: (val) => setState(() => _isPrimary = val ?? false),
                                  activeColor: const Color(0xFF0284C7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Set as primary payout account',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed bottom button above keyboard and safe area
            Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, safeBottom > 0 ? 12 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEdit ? 'Save Changes' : 'Save Bank Account',
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
      hintStyle: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    );
  }
}
