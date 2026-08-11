// Smoke test: app should boot to the Login screen when no session is
// stored, without needing the real database/secure-storage plugins.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/auth/domain/entities/auth_user_entity.dart';
import 'package:tulap_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/get_current_session.dart';
import 'package:tulap_mobile/features/auth/domain/usecases/login.dart';
import 'package:tulap_mobile/main.dart';

class _NoSessionAuthRepository implements AuthRepository {
  @override
  Future<AuthUserEntity?> getStoredUser() async => null;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  setUp(() {
    final fakeRepository = _NoSessionAuthRepository();
    sl.registerLazySingleton<GetCurrentSession>(
      () => GetCurrentSession(fakeRepository),
    );
    sl.registerLazySingleton<Login>(() => Login(fakeRepository));
  });

  tearDown(() => sl.reset());

  testWidgets('shows Login screen when no session is stored', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TulapApp());
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsOneWidget);
  });
}
