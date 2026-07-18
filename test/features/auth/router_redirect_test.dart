import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalprm/core/router/app_router.dart';
import 'package:finalprm/features/auth/data/repositories/auth_repository.dart';
import 'package:finalprm/features/auth/domain/models/app_user.dart';
import 'package:finalprm/features/auth/domain/models/app_user_role.dart';
import 'package:finalprm/features/auth/presentation/providers/auth_providers.dart';
import 'package:finalprm/features/commerce/data/repositories/catalog_repository.dart';
import 'package:finalprm/features/commerce/data/repositories/cart_repository.dart';
import 'package:finalprm/features/commerce/data/repositories/order_repository.dart';
import 'package:finalprm/features/commerce/presentation/providers/commerce_providers.dart';
import 'package:finalprm/core/result/result.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockCartRepository extends Mock implements CartRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class HttpOverridesMock extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _HttpClientMock();
  }
}

class _HttpClientMock extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _HttpClientRequestMock();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _HttpClientRequestMock();
}

class _HttpClientRequestMock extends Mock implements HttpClientRequest {
  @override
  HttpHeaders get headers => _HttpClientHttpHeadersMock();

  @override
  Future<HttpClientResponse> close() async => _HttpClientResponseMock();
}

class _HttpClientHttpHeadersMock extends Mock implements HttpHeaders {}

class _HttpClientResponseMock extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final List<int> _transparentImage = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockCatalogRepository mockCatalogRepository;
  late MockCartRepository mockCartRepository;
  late MockOrderRepository mockOrderRepository;
  late MockSharedPreferences mockSharedPreferences;
  late StreamController<AppUser> authStateController;

  setUp(() {
    HttpOverrides.global = HttpOverridesMock();
    SharedPreferences.setMockInitialValues({});

    mockAuthRepository = MockAuthRepository();
    mockCatalogRepository = MockCatalogRepository();
    mockCartRepository = MockCartRepository();
    mockOrderRepository = MockOrderRepository();
    mockSharedPreferences = MockSharedPreferences();

    authStateController = StreamController<AppUser>.broadcast();

    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => mockCatalogRepository.getCategories(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockCatalogRepository.getProducts(
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockCatalogRepository.getProducts(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockCartRepository.getCartItems(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockOrderRepository.watchUserOrders(any()),
    ).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    authStateController.close();
  });

  Widget buildTestApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  testWidgets('Guest trying to access /profile is redirected to /login', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepository),
        cartRepositoryProvider.overrideWithValue(mockCartRepository),
        orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        sharedPrefsProvider.overrideWithValue(mockSharedPreferences),
      ],
    );
    addTearDown(container.dispose);

    // Initial state is guest
    authStateController.add(AppUser.guest());

    await tester.pumpWidget(buildTestApp(container));
    await tester.pump();

    final router = container.read(routerProvider);
    router.go('/profile');
    await tester.pump();

    expect(router.state.uri.path, '/login');
  });

  testWidgets(
    'Authenticated user trying to access /login is redirected to home (/)',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          catalogRepositoryProvider.overrideWithValue(mockCatalogRepository),
          cartRepositoryProvider.overrideWithValue(mockCartRepository),
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          sharedPrefsProvider.overrideWithValue(mockSharedPreferences),
        ],
      );
      addTearDown(container.dispose);

      final appUser = AppUser(
        uid: 'uid-1',
        email: 'user@example.com',
        displayName: 'Shoe User',
        photoUrl: '',
        role: AppUserRole.user,
      );

      await tester.pumpWidget(buildTestApp(container));

      // Emit authenticated user and let state fully propagate
      authStateController.add(appUser);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Trigger navigation to login
      final router = container.read(routerProvider);
      router.go('/login');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should redirect back to home
      expect(router.state.uri.path, '/');
    },
  );
}
