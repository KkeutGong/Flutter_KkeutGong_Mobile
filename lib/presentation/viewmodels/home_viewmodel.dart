import 'package:get/get.dart';

class HomeViewModel extends GetxController {
  final RxInt counter = 0.obs;

  void increment() {
    counter.value++;
  }

  void decrement() {
    counter.value--;
  }

  void reset() {
    counter.value = 0;
  }
}
