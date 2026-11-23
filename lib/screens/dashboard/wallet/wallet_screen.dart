import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/session_manager.dart';

class WalletScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final VoidCallback onNavigateToBankDetails;

  const WalletScreen({
    super.key,
    required this.partnerData,
    required this.onNavigateToBankDetails,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isFetchingTransactions = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  Map<String, dynamic>? _walletData;
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _primaryBank;
  List<dynamic> _transactions = [];

  String _selectedFilter = 'all'; // all, pending, settled

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchWalletData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 40) {
      if (!_isLoadingMore && !_isFetchingTransactions && _hasMore) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> _fetchWalletData() async {
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

      final response = await ApiService.getWallet(token: token);

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _walletData = response['wallet'] != null ? Map<String, dynamic>.from(response['wallet']) : null;
          _summaryData = response['summary'] != null ? Map<String, dynamic>.from(response['summary']) : null;
          _primaryBank = response['primary_bank'] != null ? Map<String, dynamic>.from(response['primary_bank']) : null;
          _isLoading = false;
        });
        // Initial fetch of transactions for selected filter (page 1, 10 items)
        _fetchTransactions(reset: true);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Unable to load wallet data.';
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

  Future<void> _fetchTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isFetchingTransactions = true;
      });
    }

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) setState(() => _isFetchingTransactions = false);
        return;
      }

      final response = await ApiService.getWalletTransactions(
        token: token,
        page: 1,
        settlementStatus: _selectedFilter == 'all' ? null : _selectedFilter,
        perPage: 10,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> list = response['transactions'] is List ? response['transactions'] : [];
        setState(() {
          _transactions = list;
          _hasMore = list.length >= 10;
          _isFetchingTransactions = false;
        });
      } else {
        setState(() {
          _isFetchingTransactions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingTransactions = false;
        });
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Short span of time showing skeleton of row design as requested
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingMore = false);
        return;
      }

      final nextPage = _currentPage + 1;
      final response = await ApiService.getWalletTransactions(
        token: token,
        page: nextPage,
        settlementStatus: _selectedFilter == 'all' ? null : _selectedFilter,
        perPage: 10,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> list = response['transactions'] is List ? response['transactions'] : [];
        setState(() {
          _currentPage = nextPage;
          _transactions.addAll(list);
          _hasMore = list.length >= 10;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0.00';
    final double val = (amount is num) ? amount.toDouble() : (double.tryParse(amount.toString()) ?? 0.0);
    return '₹${val.toStringAsFixed(2)}';
  }

  String _formatDateTime(dynamic rawDate) {
    if (rawDate == null) return '';
    final dt = DateTime.tryParse(rawDate.toString())?.toLocal();
    if (dt == null) return '';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;

    final hourNum = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourNum.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '$day $month, $year • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchWalletData,
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
      );
    }

    final balance = _summaryData?['balance'] ?? _walletData?['balance'] ?? 0.0;
    final totalEarned = _summaryData?['total_earned'] ?? 0.0;
    final totalSettled = _summaryData?['total_settled'] != null
        ? (_summaryData!['total_settled'] as num).toDouble()
        : ((_summaryData?['total_withdrawn'] as num?)?.toDouble() ?? 0.0);
    final currency = _walletData?['currency'] ?? 'INR';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _fetchWalletData,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 12,
            bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
          ),
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 14,
                    color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Wallet Balance',
                            style: GoogleFonts.manrope(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          currency,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatAmount(balance),
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: Colors.white70, size: 12),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Secure payout wallet for consultation earnings',
                          style: GoogleFonts.manrope(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Summary Metrics Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 14),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Earned',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatAmount(totalEarned),
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF2563EB), size: 14),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Settled',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatAmount(totalSettled),
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Primary Bank Details Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _primaryBank != null ? (_primaryBank!['bank_name'] ?? 'Bank Account') : 'No Primary Bank Account',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _primaryBank != null
                              ? 'A/C: ${_primaryBank!['masked_account_no'] ?? _primaryBank!['account_no']} • ${_primaryBank!['ifsc_code'] ?? ''}'
                              : 'Add your bank details for direct payouts',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNavigateToBankDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _primaryBank != null ? 'Manage' : 'Add Bank',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Transactions Header & Dropdown Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF0284C7)),
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: Colors.white,
                      onChanged: (String? newVal) {
                        if (newVal != null && newVal != _selectedFilter) {
                          setState(() {
                            _selectedFilter = newVal;
                          });
                          _fetchTransactions(reset: true);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Transactions'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending Payouts'),
                        ),
                        DropdownMenuItem(
                          value: 'settled',
                          child: Text('Settled Payouts'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Transactions List / Skeleton Loading
            if (_isFetchingTransactions) ...[
              _buildSkeletonRow(),
              _buildSkeletonRow(),
              _buildSkeletonRow(),
            ] else if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.black26, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFilter == 'pending'
                          ? 'No Pending Payouts'
                          : _selectedFilter == 'settled'
                              ? 'No Settled Payouts'
                              : 'No Transactions Yet',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Earnings from patient consultations and video calls will appear here automatically.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ..._transactions.map((tx) {
                final isCredit = tx['transaction_type'] == 'credit';
                final amount = tx['amount'] ?? 0;
                final dateStr = _formatDateTime(tx['created_at']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isCredit ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['description'] ?? (isCredit ? 'Consultation Fee' : 'Payout Settlement'),
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'}${_formatAmount(amount)}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isCredit ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isCredit)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: tx['settlement_status'] == 'settled'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tx['settlement_status'] == 'settled' ? 'Settled' : 'Payout Pending',
                                style: GoogleFonts.manrope(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: tx['settlement_status'] == 'settled'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            )
                          else
                            Text(
                              tx['status'] ?? 'completed',
                              style: GoogleFonts.manrope(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: tx['status'] == 'completed'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Skeleton Loader while scrolling down for next 10 items
              if (_isLoadingMore) ...[
                _buildSkeletonRow(),
                _buildSkeletonRow(),
              ],

              // Reached end indicator
              if (!_hasMore && _transactions.length >= 10)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'All transactions loaded',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 85,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 55,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 48,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
