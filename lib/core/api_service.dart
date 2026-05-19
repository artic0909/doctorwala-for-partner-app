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
we