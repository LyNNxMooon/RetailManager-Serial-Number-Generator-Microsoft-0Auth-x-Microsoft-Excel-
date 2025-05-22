import 'package:get/get.dart';

class Controller extends GetxController {
  RxBool isLoading = false.obs;

  RxString accessToken = "".obs;

  RxString siteID = "".obs;

  RxString lastSerialNumber = "Loading...".obs;
  RxString newSerialNumber = "-".obs;

  RxBool isPortSwitched = false.obs;
}
