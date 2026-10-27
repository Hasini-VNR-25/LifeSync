import '../models/profile.dart';

abstract class IAuthRepository {
  Future<Profile?> getCurrentProfile();
  Future<Profile> signIn({required String email, required String password});
  Future<Profile> signUp({required String email, required String password, required String displayName});
  Future<void> signOut();
  Future<void> updateProfile(Profile profile);
  Future<void> deleteAccountAndData(String userId);
}
