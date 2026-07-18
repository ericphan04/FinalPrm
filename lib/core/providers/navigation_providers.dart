import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider lưu trữ index của tab hiện tại trên MainScreen
final mainTabIndexProvider = StateProvider<int>((ref) => 0);
