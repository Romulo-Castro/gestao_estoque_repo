// lib/core/presentation/providers/user_profile_provider.dart
import 'package:flutter/material.dart';
import '../../data/datasources/api_service.dart';
import '../../data/models/user_model.dart';
import '../../../shared/utils/error_handler.dart';
import 'auth_provider.dart';

class UserProfileProvider with ChangeNotifier, ErrorHandlingMixin {
  final ApiService _apiService;
  final AuthProvider _authProvider;
  
  User? _profile;
  bool _isUpdating = false;
  
  User? get profile => _profile;
  bool get isUpdating => _isUpdating;
  
  UserProfileProvider(this._apiService, this._authProvider) {
    _loadProfile();
  }
  
  void _loadProfile() {
    _profile = _authProvider.user;
    notifyListeners();
  }
  
  Future<bool> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    return await handleAsyncOperation(() async {
      _isUpdating = true;
      notifyListeners();
      
      try {
        // Prepare update data
        final updateData = <String, dynamic>{
          'name': name.trim(),
          'email': email.trim(),
        };
        
        // Add password data if provided
        if (currentPassword != null && newPassword != null && newPassword.isNotEmpty) {
          if (newPassword.length < 6) {
            throw Exception('Nova senha deve ter pelo menos 6 caracteres');
          }
          updateData['currentPassword'] = currentPassword;
          updateData['newPassword'] = newPassword;
        }
        
        // Call API to update profile
        final response = await _apiService.updateUserProfile(updateData);
        
        if (response.containsKey('user')) {
          _profile = User.fromJson(response['user']);
          
          // Update auth provider with new user data
          await _authProvider.updateUserProfile(_profile!);
          
          return true;
        }
        
        throw Exception('Resposta inválida do servidor');
      } finally {
        _isUpdating = false;
        notifyListeners();
      }
    }, 'updateProfile') ?? false;
  }
  
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await handleAsyncOperation(() async {
      if (newPassword.length < 6) {
        throw Exception('Nova senha deve ter pelo menos 6 caracteres');
      }
      
      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return response.containsKey('message');
    }, 'changePassword') ?? false;
  }
  
  void refreshProfile() {
    _loadProfile();
  }
}
