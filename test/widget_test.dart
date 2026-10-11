import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_asad_traders/app.dart';
import 'package:al_asad_traders/features/auth/models/user_model.dart';
import 'package:al_asad_traders/features/auth/providers/auth_provider.dart';
import 'package:al_asad_traders/features/auth/services/firebase_auth_service.dart';

class MockFirebaseAuthService implements FirebaseAuthService {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel?> getUserProfile(String uid) async => null;

  @override
  Future<void> saveUserProfile(UserModel user) async {}

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('App renders LoginScreen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(MockFirebaseAuthService()),
          authStateStreamProvider.overrideWith((ref) => Stream.value(null)),
          currentUserModelProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const AlAsadTradersApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Al Asad Traders'), findsOneWidget);
    expect(find.text('Sign In to Account'), findsOneWidget);
  });
}
