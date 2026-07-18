import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finalprm/core/result/result.dart';
import 'package:finalprm/features/commerce/domain/models/cart_item.dart';
import 'package:finalprm/features/commerce/data/repositories/cart_repository.dart';
import 'package:finalprm/features/commerce/presentation/controllers/cart_controller.dart';

class MockCartRepository extends Mock implements CartRepository {}

void main() {
  late MockCartRepository mockCartRepository;
  late CartController controller;

  setUp(() {
    mockCartRepository = MockCartRepository();
    // Default mock setup for initialization
    when(() => mockCartRepository.getCartItems(any()))
        .thenAnswer((_) async => const Success([]));
    controller = CartController(mockCartRepository, 'user_123');
  });

  group('CartController - Merge Guest Cart', () {
    test('mergeCart calls mergeGuestCart on repository when uid is not null', () async {
      when(() => mockCartRepository.mergeGuestCart('user_123'))
          .thenAnswer((_) async => const Success(null));
      when(() => mockCartRepository.getCartItems('user_123'))
          .thenAnswer((_) async => const Success([]));

      await controller.mergeCart();

      verify(() => mockCartRepository.mergeGuestCart('user_123')).called(1);
    });
  });
}
