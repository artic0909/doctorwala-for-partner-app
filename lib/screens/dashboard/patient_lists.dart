import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import 'patient_profile_view.dart';
import '../../widgets/partner_skeleton_loader.dart';

class _Theme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Turquoise/Teal
  static const Color bgTint = Color(0xFFF8FAFC); // Slate background
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium slate
}

class PatientListsTab extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const PatientListsTab({
    super.key,
    required this.partnerData,
  });

  @override
  State<PatientListsTab> createState() => _PatientListsTabState();
}

class _PatientListsTabState extends State<PatientListsTab> {
  bool _isFetching = true;
  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRequests = _requests;
      } else {
        _filteredRequests = _requests.where((req) {
          final patient = req['patient'] ?? {};
          final name = (patient['user_name'] ?? '').toString().toLowerCase();
          final card = (patient['medical_card_no'] ?? '').toString().toLowerCase();
          final doctor = req['doctor'] ?? {};
          final docName = (doctor['doctor_name'] ?? '').toString().toLowerCase();
          return name.contains(query) || card.contains(query) || docName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isFetching = false);
        return;
      }

      final response = await ApiService.getMedicalCardAccessRequests(token: token);
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _requests = response['data'] ?? [];
          _filteredRequests = _requests;
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to load access requests.',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(
          context,
          'An unexpected error occurred while fetching requests.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  void _navigateToProfile(String encryptedId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfileViewScreen(
          encryptedId: encryptedId,
          partnerData: widget.partnerData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Theme.bgTint,
      body: Column(
        children: [
          // Search Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.blueGrey.withAlpha(20),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Access Logs',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _Theme.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Requests: ${_requests.length}',
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _Theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _fetchRequests,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _Theme.accent.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: _Theme.accent,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search Bar
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Theme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      hintText: 'Search patient, card no. or doctor...',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: _Theme.accent,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: _isFetching
                ? const PartnerPatientInquiriesSkeleton()
                : RefreshIndicator(
                    onRefresh: _fetchRequests,
                    color: _Theme.accent,
                    child: _filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 14,
                              bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
                            ),
                            itemCount: _filteredRequests.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final req = _filteredRequests[index] as Map<String, dynamic>;
                              return FadeInUp(
                                duration: const Duration(milliseconds: 300),
                                child: _buildRequestCard(req),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = _searchController.text.trim();
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _Theme.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: _Theme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? 'No Requests Logged' : 'No Results Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _Theme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'There are no digital card access request entries recorded.'
                  : 'We couldn\'t find any matches for "$query". Try searching something else.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _Theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final patient = req['patient'] ?? {};
    final doctor = req['doctor'] ?? {};

    final patientName = patient['user_name'] ?? 'N/A';
    final cardNo = patient['medical_card_no'] ?? 'N/A';
    final doctorName = doctor['doctor_name'] ?? 'N/A';
    final reqStatus = req['req_status'] ?? 'pending'; // pending, accepted, rejected
    final accessStatus = req['access_status'] ?? 'off'; // on, off
    final encryptedId = patient['encrypted_id']?.toString() ?? '';

    // Color definitions based on status
    Color statusColor;
    String statusLabel = reqStatus.toUpperCase();
    if (reqStatus == 'accepted') {
      statusColor = _Theme.accent;
    } else if (reqStatus == 'rejected') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent;
      statusLabel = 'PENDING';
    }

    final hasActiveAccess = reqStatus == 'accepted' && accessStatus == 'on' && encryptedId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: hasActiveAccess ? () => _navigateToProfile(encryptedId) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with status tags
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withAlpha(40), width: 0.9),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (reqStatus == 'accepted')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (accessStatus == 'on' ? _Theme.accent : const Color(0xFF64748B)).withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (accessStatus == 'on' ? _Theme.accent : const Color(0xFF64748B)).withAlpha(40),
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          accessStatus == 'on' ? 'ACCESS: ACTIVE' : 'ACCESS: REVOKED',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accessStatus == 'on' ? _Theme.accent : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Patient details with avatar
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _Theme.accent.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _Theme.accent.withAlpha(30), width: 1.0),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: _Theme.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _Theme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Card: ',
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _Theme.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cardNo,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Seating doctor requested for
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REQUESTED FOR DOCTOR',
                            style: GoogleFonts.manrope(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctorName,
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _Theme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasActiveAccess)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _Theme.accent.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _Theme.accent.withAlpha(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Profile',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _Theme.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: _Theme.accent,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
