import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/core/utils/error_mapper.dart';
import 'package:smart_task_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_task_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:smart_task_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_task_manager/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:smart_task_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:smart_task_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:smart_task_manager/features/auth/domain/usecases/register_usecase.dart';

// --- Data Source Provider ---
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(FirebaseAuth.instance);
});

// --- Repository Provider ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  final connectivityService = ref.read(connectivityServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    connectivityService: connectivityService,
  );
});

// --- Use Case Providers ---
final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.read(authRepositoryProvider)));
final registerUseCaseProvider = Provider((ref) => RegisterUseCase(ref.read(authRepositoryProvider)));
final logoutUseCaseProvider = Provider((ref) => LogoutUseCase(ref.read(authRepositoryProvider)));
final getCurrentUserUseCaseProvider = Provider((ref) => GetCurrentUserUseCase(ref.read(authRepositoryProvider)));

// --- Auth State ---
class AuthState extends Equatable {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({UserEntity? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [user, isLoading, error];
}

// --- Auth Notifier (Controller) ---
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(AuthState.initial()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    final result = await _getCurrentUserUseCase();
    result.fold(
      (failure) => state = state.copyWith(user: null), // Do not show error on initial check
      (user) => state = state.copyWith(user: user),
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _loginUseCase(LoginParams(email: email, password: password));
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure.message),
      (user) => state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _registerUseCase(RegisterParams(email: email, password: password));
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure.message),
      (user) => state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _logoutUseCase();
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure.message),
      (_) => state.copyWith(isLoading: false, user: null),
    );
  }
}

// --- Auth Provider ---
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    registerUseCase: ref.read(registerUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.read(getCurrentUserUseCaseProvider),
  );
});

// --- Auth State Change Stream Provider ---
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});
