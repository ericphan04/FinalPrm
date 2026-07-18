// ignore_for_file: subtype_of_sealed_class
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalprm/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:finalprm/features/auth/domain/models/app_user.dart';
import 'package:finalprm/features/auth/domain/models/app_user_role.dart';
import 'package:finalprm/core/result/result.dart';

// Mock definitions
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockIdTokenResult extends Mock implements firebase_auth.IdTokenResult {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockIdTokenResult mockIdTokenResult;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockSnapshot;
  late FirebaseAuthRepository repository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockIdTokenResult = MockIdTokenResult();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    repository = FirebaseAuthRepository(
      firebaseAuth: mockFirebaseAuth,
      firestore: mockFirestore,
    );

    // Common stubs for mockUser
    when(() => mockUser.uid).thenReturn('test-uid');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('Test User');
    when(() => mockUser.photoURL).thenReturn('https://example.com/avatar.png');
    when(
      () => mockUser.getIdTokenResult(any()),
    ).thenAnswer((_) async => mockIdTokenResult);
    when(
      () => mockUser.getIdTokenResult(),
    ).thenAnswer((_) async => mockIdTokenResult);
    when(() => mockIdTokenResult.claims).thenReturn({'role': 'user'});

    // Firestore stubs
    registerFallbackValue(<String, dynamic>{});
    when(
      () => mockFirestore.collection(any()),
    ).thenReturn(mockCollectionReference);
    when(
      () => mockCollectionReference.doc(any()),
    ).thenReturn(mockDocumentReference);
    when(() => mockDocumentReference.set(any())).thenAnswer((_) async {});
    when(
      () => mockDocumentReference.get(),
    ).thenAnswer((_) async => mockSnapshot);
    when(() => mockSnapshot.exists).thenReturn(true);
    when(() => mockSnapshot.data()).thenReturn({'role': 'user'});
  });

  group('FirebaseAuthRepository - signInWithEmailAndPassword', () {
    test('returns Success<AppUser> when firebase sign in succeeds', () async {
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);

      final result = await repository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, isA<Success<AppUser>>());
      final appUser = (result as Success<AppUser>).data;
      expect(appUser.uid, 'test-uid');
      expect(appUser.email, 'test@example.com');
      expect(appUser.role, AppUserRole.user);
    });

    test('returns Failure when firebase throws error', () async {
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        ),
      ).thenThrow(
        firebase_auth.FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password',
        ),
      );

      final result = await repository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, isA<Failure<AppUser>>());
      final failure = (result as Failure<AppUser>).failure;
      expect(failure.code, 'wrong-password');
      expect(failure.message, contains('Mật khẩu'));
    });
  });

  group('FirebaseAuthRepository - signUpWithEmailAndPassword', () {
    test('registers user, updates profile and writes to firestore', () async {
      when(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'register@example.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      final result = await repository.signUpWithEmailAndPassword(
        email: 'register@example.com',
        password: 'password',
        displayName: 'Test User',
      );

      expect(result, isA<Success<AppUser>>());
      verify(() => mockUser.updateDisplayName('Test User')).called(1);
      verify(() => mockFirestore.collection('users')).called(2);
    });
  });

  group('FirebaseAuthRepository - signOut', () {
    test('succeeds when firebase sign out succeeds', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, isA<Success<void>>());
      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });

  group('FirebaseAuthRepository - sendPasswordResetEmail', () {
    test('succeeds when firebase sends reset email', () async {
      when(
        () =>
            mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com'),
      ).thenAnswer((_) async {});

      final result = await repository.sendPasswordResetEmail(
        email: 'test@example.com',
      );

      expect(result, isA<Success<void>>());
      verify(
        () =>
            mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com'),
      ).called(1);
    });
  });
}
