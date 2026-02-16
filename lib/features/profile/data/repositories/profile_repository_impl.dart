import 'package:fpdart/fpdart.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/core/utils/error_mapper.dart';
import 'package:smart_task_manager/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);
  Future<Either<Failure, void>> saveUserProfile(UserProfile profile);
  Future<Either<Failure, void>> updateTheme(String userId, bool isDarkMode);
  Stream<UserProfile> userProfileStream(String userId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    if (!await connectivityService.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserProfile(UserProfile profile) async {
    if (!await connectivityService.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.saveUserProfile(profile);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateTheme(String userId, bool isDarkMode) async {
    // Theme update can happen optimistically or wait. 
    // We check connectivity but maybe we should allow local logic. 
    // For now, consistent with requirements "No internet connection" check.
    if (!await connectivityService.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.updateTheme(userId, isDarkMode);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<UserProfile> userProfileStream(String userId) {
    return remoteDataSource.userProfileStream(userId);
  }
}
