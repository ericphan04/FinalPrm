import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalprm/main.dart';
import 'package:finalprm/features/auth/domain/models/app_user.dart';
import 'package:finalprm/core/router/app_router.dart';
import 'package:finalprm/features/auth/presentation/providers/auth_providers.dart';
import 'package:finalprm/features/auth/data/repositories/auth_repository.dart';
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
  setUpAll(() {
    HttpOverrides.global = HttpOverridesMock();
  });

  testWidgets('Clicking register navigates correctly', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final mockRepo = MockAuthRepository();
    final mockCatalogRepo = MockCatalogRepository();
    final mockCartRepo = MockCartRepository();
    final mockOrderRepo = MockOrderRepository();
    final mockSharedPrefs = MockSharedPreferences();

    final authStream = StreamController<AppUser>.broadcast();

    when(() => mockRepo.authStateChanges).thenAnswer((_) => authStream.stream);
    when(
      () => mockCatalogRepo.getCategories(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockCatalogRepo.getProducts(categoryId: any(named: 'categoryId')),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockCatalogRepo.getProducts(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockCartRepo.getCartItems(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockOrderRepo.watchUserOrders(any()),
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
          sharedPrefsProvider.overrideWithValue(mockSharedPrefs),
        ],
        child: const MyApp(),
      ),
    );

    // Default start should go to ShowroomScreen
    authStream.add(AppUser.guest());
    await tester.pumpAndSettle();

    print('Initial Route: /');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyApp)),
    );
    final router = container.read(routerProvider);

    // Now we are at ShowroomScreen. Let's go to /login
    router.go('/login');
    await tester.pumpAndSettle();

    print('Current route before click: ${router.state.uri.path}');

    final registerButton = find.text('Đăng ký ngay');
    if (registerButton.evaluate().isNotEmpty) {
      print('Found Đăng ký ngay, tapping...');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      print('After tap, route: ${router.state.uri.path}');
    } else {
      print('Could not find Đăng ký ngay');
    }

    authStream.close();
  });
}
