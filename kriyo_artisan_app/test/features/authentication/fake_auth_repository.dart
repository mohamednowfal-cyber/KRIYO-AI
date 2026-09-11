import 'package:kriyo_artisan_app/features/authentication/data/models/otp_response_models.dart';
import 'package:kriyo_artisan_app/features/authentication/domain/entities/artisan_user.dart';
import 'package:kriyo_artisan_app/features/authentication/domain/repositories/auth_repository.dart';

/// Test double for AuthRepository in Flutter widget & unit tests.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<OtpSendResponseModel> requestOtp({
    String? phone,
    String? email,
    required String role,
  }) async {
    return const OtpSendResponseModel(
      success: true,
      message: 'OTP sent successfully',
      requestId: 'mock_request_id_123',
    );
  }

  @override
  Future<OtpVerifyResponseModel> confirmOtp({
    String? phone,
    String? phoneNumber,
    String? email,
    String? fullName,
    required String otp,
    required String requestId,
    required String role,
  }) async {
    return const OtpVerifyResponseModel(
      success: true,
      accessToken: 'mock_jwt_access_token',
      refreshToken: 'mock_jwt_refresh_token',
      isNewUser: false,
      userData: {
        'id': 'usr_customer_123',
        'name': 'Priya Sharma',
        'profile_completed': true,
      },
    );
  }

  @override
  Future<OtpSendResponseModel> resendOtp({
    String? phone,
    String? email,
    required String role,
  }) async {
    return const OtpSendResponseModel(
      success: true,
      message: 'OTP resent successfully',
      requestId: 'mock_request_id_resend_123',
    );
  }

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<ArtisanUser> verifyOtp(String phone, String otp) async {
    return const ArtisanUser(
      id: 'test_artisan_id',
      name: 'Test Artisan',
      phone: '+919876543210',
      craftCategory: 'Pottery',
    );
  }

  @override
  Future<ArtisanUser> register(Map<String, dynamic> userData) async {
    return const ArtisanUser(
      id: 'test_artisan_id',
      name: 'Test Artisan',
      phone: '+919876543210',
      craftCategory: 'Pottery',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<ArtisanUser?> getCurrentUser() async => null;
}
