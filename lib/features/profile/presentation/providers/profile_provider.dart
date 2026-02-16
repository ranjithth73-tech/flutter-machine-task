import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_task_manager/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:smart_task_manager/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(FirebaseFirestore.instance);
});

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  final remoteDataSource = ref.read(profileRemoteDataSourceProvider);
  final connectivityService = ref.read(connectivityServiceProvider);
  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
    connectivityService: connectivityService,
  );
});

final userProfileStreamProvider = StreamProvider.autoDispose<UserProfile>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  
  if (user != null) {
    final repository = ref.read(profileRepositoryProvider);
    return repository.userProfileStream(user.id);
  }
  return const Stream.empty();
});

// Use StateNotifier for updates
class ProfileUpdateNotifier extends StateNotifier<bool> {
  final Ref ref;

  ProfileUpdateNotifier(this.ref) : super(false);

  Future<void> updateProfile(UserProfile profile) async {
    state = true;
    final repository = ref.read(profileRepositoryProvider);
    await repository.saveUserProfile(profile);
    state = false;
  }
}

final profileUpdateProvider = StateNotifierProvider<ProfileUpdateNotifier, bool>((ref) {
  return ProfileUpdateNotifier(ref);
});

// Theme Notifier
class ThemeNotifier extends StateNotifier<bool> {
  final Ref ref;

  ThemeNotifier(this.ref) : super(false) {
    ref.listen(userProfileStreamProvider, (previous, next) {
      next.whenData((profile) {
        state = profile.isDarkMode;
      });
    });
  }

  Future<void> toggleTheme() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final newMode = !state;
    state = newMode; // Optimistic update
    
    final repository = ref.read(profileRepositoryProvider);
    await repository.updateTheme(user.id, newMode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier(ref);
});
