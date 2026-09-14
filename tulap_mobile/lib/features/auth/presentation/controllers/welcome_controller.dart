import 'package:flutter/foundation.dart';
import '../../../../core/network/network_info.dart';

class WelcomeState {
  final bool isOnline;

  const WelcomeState({this.isOnline = true});

  WelcomeState copyWith({bool? isOnline}) {
    return WelcomeState(isOnline: isOnline ?? this.isOnline);
  }
}

/// WelcomeController
/// ----------------------------------------------------------------------
/// Layar Welcome (sebelum form Login) - status "Online" NYATA (bukan
/// hiasan, lihat NetworkInfo).
/// ----------------------------------------------------------------------
class WelcomeController extends ChangeNotifier {
  final NetworkInfo _networkInfo;

  WelcomeState _state = const WelcomeState();
  WelcomeState get state => _state;

  WelcomeController({required NetworkInfo networkInfo})
    : _networkInfo = networkInfo {
    _load();
  }

  void _update(WelcomeState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _load() async {
    final isOnline = await _networkInfo.isConnected;
    _update(_state.copyWith(isOnline: isOnline));
  }
}
