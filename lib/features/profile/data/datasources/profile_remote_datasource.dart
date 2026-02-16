import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfile> getUserProfile(String userId);
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> updateTheme(String userId, bool isDarkMode);
  Stream<UserProfile> userProfileStream(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDataSourceImpl(this._firestore);

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw const ServerException('User profile not found');
      }
      return UserProfile.fromMap(doc.data()!, doc.id);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).set(profile.toMap());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateTheme(String userId, bool isDarkMode) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isDarkMode': isDarkMode,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<UserProfile> userProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        // Handle case where document doesn't exist yet, return empty or throw?
        // Returning a default profile might be safer for stream
        return UserProfile(
          id: userId,
          email: '',
          name: '',
          createdAt: DateTime.now(),
        );
      }
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
  }
}
