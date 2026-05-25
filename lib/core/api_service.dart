import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://www.doctorwala.info/api/partner';

  /// Maps the Flutter client registration categories to the database enum strings
  static List<String> mapCategoryToDbValues(String clientCategory) {
    switch (clientCategory) {
      case 'clinic':
        return ['OPD'];
      case 'lab':
        return ['Pathology'];
      case 'doctor':
        return ['Doctor'];
      case 'both':
        return ['OPD', 'Pathology'];
      default:
        return ['OPD'];
    }
  }

  /// Handles Partner Register requests (URL Encoded Form POST)
  static Future<Map<String, dynamic>> register({
    required String clinicName,
    required String contactPerson,
    required String mobileNumber,
    required String email,
    required String state,
    required String city,
    required String pincode,
    required String landmark,
    required String address,
    required String password,
    required String clientCategory,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    
    // Map category selection to standard JSON array values expected by Laravel backend
    final List<String> dbCategories = mapCategoryToDbValues(clientCategory);

    final Map<String, String> body = {
      'partner_clinic_name': clinicName,
      'partner_contact_person_name': contactPerson,
      'partner_mobile_number': mobileNumber,
      'partner_email': email,
      'partner_state': state,
      'partner_city': city,
      'partner_pincode': pincode,
      'partner_landmark': landmark,
      'partner_address': address,
      'partner_password': password,
    };

    // Encode PHP-compliant arrays for form url-encoded format
    for (int i = 0; i < dbCategories.length; i++) {
      body['registration_type[$i]'] = dbCategories[i];
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 201 || response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Handles Partner Login requests (supports both Email and Mobile Number, URL Encoded Form POST)
  static Future<Map<String, dynamic>> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final Map<String, String> body = {
      'partner_email': emailOrMobile,
      'partner_password': password,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Sends an OTP to the partner's registered email address (URL Encoded Form POST)
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/send-otp');
    final Map<String, String> body = {
      'partner_email': email,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Verifies an OTP and logs in the partner (URL Encoded Form POST)
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/verify-otp');
    final Map<String, String> body = {
      'partner_email': email,
      'otp': otp,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves coupon information from the backend database (Sanctum protected, URL Encoded Form POST)
  static Future<Map<String, dynamic>> getCouponDetails({
    required String couponCode,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/get-coupon-details');
    final Map<String, String> body = {
      'coupon_code': couponCode,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify coupon. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Registers / adds the verified coupon association to the partner's account (Sanctum protected, URL Encoded Form POST)
  static Future<Map<String, dynamic>> addPartnerCoupon({
    required String partnerId,
    required String couponCode,
    required String amount,
    required String startDate,
    required String endDate,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/add-partner-coupon');
    final Map<String, String> body = {
      'currently_loggedin_partner_id': partnerId,
      'coupon_code': couponCode,
      'coupon_amount': amount,
      'coupon_start_date': startDate,
      'coupon_end_date': endDate,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to activate coupon. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }
  /// Sends an OTP to the partner's registered email address for password reset (URL Encoded Form POST)
  static Future<Map<String, dynamic>> forgotPasswordSendOtp({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/forgot-password/send-otp');
    final Map<String, String> body = {
      'partner_email': email,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Verifies an OTP and resets password (URL Encoded Form POST)
  static Future<Map<String, dynamic>> forgotPasswordReset({
    required String email,
    required String otp,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/forgot-password/reset');
    final Map<String, String> body = {
      'partner_email': email,
      'otp': otp,
      'partner_password': password,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Gets the Clinic Profile (OPD or Pathology) details (Sanctum protected, GET)
  static Future<Map<String, dynamic>> getClinicProfile({
    required String type, // 'opd' or 'pathology'
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/clinic-profile/$type');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve clinic profile. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Stores or updates the Clinic Profile (OPD, Pathology or Doctor) details (Sanctum protected, supports Multipart for file upload)
  static Future<Map<String, dynamic>> storeClinicProfile({
    required String type, // 'opd', 'pathology' or 'doctor'
    required Map<String, String> body,
    required String token,
    String? imageKey,
    String? imagePath,
  }) async {
    final url = Uri.parse('$baseUrl/clinic-profile/$type');

    try {
      if (imagePath != null && imageKey != null) {
        final request = http.MultipartRequest('POST', url);
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        // Add text fields
        request.fields.addAll(body);

        // Add file field
        final file = await http.MultipartFile.fromPath(imageKey, imagePath);
        request.files.add(file);

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'statusCode': response.statusCode,
          'success': response.statusCode == 200,
          ...responseData,
        };
      } else {
        final response = await http.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'statusCode': response.statusCode,
          'success': response.statusCode == 200,
          ...responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to save clinic profile. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves all OPD doctors for the authenticated partner (Sanctum protected, GET)
  static Future<Map<String, dynamic>> getDoctors({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/doctors');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve doctors. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Adds a new OPD doctor details (Sanctum protected, POST)
  static Future<Map<String, dynamic>> addDoctor({
    required String token,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse('$baseUrl/doctors');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add doctor. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Updates an existing OPD doctor details (Sanctum protected, POST)
  static Future<Map<String, dynamic>> updateDoctor({
    required String token,
    required String id,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse('$baseUrl/doctors/$id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update doctor. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Deletes an OPD doctor (Sanctum protected, DELETE)
  static Future<Map<String, dynamic>> deleteDoctor({
    required String token,
    required String id,
  }) async {
    final url = Uri.parse('$baseUrl/doctors/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete doctor. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves all pathology tests for the authenticated partner (Sanctum protected, GET)
  static Future<Map<String, dynamic>> getTests({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/tests');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve tests. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Adds a new pathology test details (Sanctum protected, POST)
  static Future<Map<String, dynamic>> addTest({
    required String token,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse('$baseUrl/tests');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add test. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Updates an existing pathology test details (Sanctum protected, POST)
  static Future<Map<String, dynamic>> updateTest({
    required String token,
    required String id,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse('$baseUrl/tests/$id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update test. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Deletes a pathology test (Sanctum protected, DELETE)
  static Future<Map<String, dynamic>> deleteTest({
    required String token,
    required String id,
  }) async {
    final url = Uri.parse('$baseUrl/tests/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete test. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves appointments for the authenticated partner (Sanctum protected, GET)
  static Future<Map<String, dynamic>> getAppointments({
    required String token,
    String? status,
  }) async {
    final statusQuery = status != null ? '?status=$status' : '';
    final url = Uri.parse('$baseUrl/appointments$statusQuery');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve appointments. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves appointment stats for the dashboard (Sanctum protected, GET)
  static Future<Map<String, dynamic>> getAppointmentsStats({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/appointments/stats');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve appointment statistics.',
        'error': e.toString(),
      };
    }
  }

  /// Updates the status of an appointment (Sanctum protected, POST)
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String token,
    required String id,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/appointments/$id/status');
    final Map<String, String> body = {
      'status': status,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update appointment status. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Updates the partner profile details (Sanctum protected, POST)
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String clinicName,
    required String contactPerson,
    required String mobileNumber,
    required String email,
    required String state,
    required String city,
    required String pincode,
    required String landmark,
    required String address,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/profile/update');
    final Map<String, String> body = {
      'partner_clinic_name': clinicName,
      'partner_contact_person_name': contactPerson,
      'partner_mobile_number': mobileNumber,
      'partner_email': email,
      'partner_state': state,
      'partner_city': city,
      'partner_pincode': pincode,
      'partner_landmark': landmark,
      'partner_address': address,
    };
    if (password != null && password.isNotEmpty) {
      body['partner_password'] = password;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves the Super About Us details from the database (Public, GET)
  static Future<Map<String, dynamic>> getAboutUs() async {
    final url = Uri.parse('$baseUrl/about-us');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to retrieve help details. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves initial metadata (banners and doctor dropdown) for medical card access
  static Future<Map<String, dynamic>> getMedicalCardAccessMeta({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/meta');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Looks up a patient by their Medical Card No and Member ID
  static Future<Map<String, dynamic>> lookupPatient({
    required String medicalId,
    required String memberId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/lookup');
    final Map<String, String> body = {
      'dw_medical_id': medicalId,
      'dw_member_id': memberId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Sends a patient profile access request
  static Future<Map<String, dynamic>> sendMedicalCardAccessRequest({
    required int dwUserId,
    required int doctorId,
    required String medicalId,
    required String memberId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/request');
    final Map<String, String> body = {
      'dw_user_id': dwUserId.toString(),
      'doctor_id': doctorId.toString(),
      'dw_medical_id': medicalId,
      'dw_member_id': memberId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 201 || response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves all medical card access requests sent by the partner
  static Future<Map<String, dynamic>> getMedicalCardAccessRequests({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/requests');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves the profile details of a patient
  static Future<Map<String, dynamic>> getPatientProfile({
    required String encryptedId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/patient/$encryptedId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves the medical history of a patient
  static Future<Map<String, dynamic>> getPatientMedicalHistory({
    required String encryptedId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/patient/$encryptedId/history');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }

  /// Retrieves details of a specific medical report
  static Future<Map<String, dynamic>> getPatientReportDetails({
    required String encryptedId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/medical-card-access/report/$encryptedId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        ...responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server. Please check your internet connection.',
        'error': e.toString(),
      };
    }
  }
}
