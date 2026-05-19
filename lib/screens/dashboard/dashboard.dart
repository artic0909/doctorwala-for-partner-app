import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import '../login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> partnerData;

  const DashboardScreen({super.key, required this.partnerData});

  @override
  Widget build(BuildContext context) {
    // Read raw partner profile variables
    final clinicName = partnerData['partner_clinic_name'] ?? 'N/A';
    final contactPerson = partnerData['partner_contact_person_name'] ?? 'N/A';
    final partnerId = partnerData['partner_id'] ?? 'N/A';
    final email = partnerData['partner_email'] ?? 'N/A';
    final mobile = partnerData['partner_mobile_number'] ?? 'N/A';
    final status = partnerData['status'] ?? 'N/A';
    
    // Address fields
    final state = partnerData['partner_state'] ?? 'N/A';
    final city = partnerData['partner_city'] ?? 'N/A';
    final pincode = partnerData['partner_pincode'] ?? 'N/A';
    final landmark = partnerData['partner_landmark'] ?? 'N/A';
    final address = partnerData['partner_address'] ?? 'N/A';

    // Category
    final regType = partnerData['registration_type']?.toString() ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await SessionManager.clearSession();
              if (!context.mounted) return;
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Welcome, $clinicName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact: $contactPerson',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 32),

            // Raw Profile Parameters List
            const Text(
              'PROFILE DETAILS:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlainDetailRow('Partner ID', partnerId),
            _buildPlainDetailRow('Email Address', email),
            _buildPlainDetailRow('Mobile Number', mobile),
            _buildPlainDetailRow('Account Status', status),
            _buildPlainDetailRow('Category Type', regType),
            
            const SizedBox(height: 24),
            const Text(
              'ADDRESS:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlainDetailRow('State', state),
            _buildPlainDetailRow('City', city),
            _buildPlainDetailRow('Pincode', pincode),
            _buildPlainDetailRow('Landmark', landmark),
            _buildPlainDetailRow('Street Address', address),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
