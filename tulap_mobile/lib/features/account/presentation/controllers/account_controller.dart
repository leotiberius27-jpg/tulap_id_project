import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../auth/domain/usecases/logout.dart';

class AccountState {
  final AuthUserEntity? user;
  final bool isLoggingOut;

  const AccountState({this.user, this.isLoggingOut = false});

  AccountState copyWith({AuthUserEntity? user, bool? isLoggingOut}) {
    return AccountState(
      user: user ?? this.user,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }
}

class AccountController extends ChangeNotifier {
  final GetCurrentSession _getCurrentSession;
  final Logout _logout;

  AccountState _state = const AccountState();
  AccountState get state => _state;

  AccountController({
    required GetCurrentSession getCurrentSession,
    required Logout logout,
  })  : _getCurrentSession = getCurrentSession,
        _logout = logout {
    _load();
  }

  void _update(AccountState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _load() async {
    final user = await _getCurrentSession();
    _update(_state.copyWith(user: user));
  }

  Future<void> signOut() async {
    _update(_state.copyWith(isLoggingOut: true));
    await _logout();
    _update(_state.copyWith(isLoggingOut: false));
  }
}
