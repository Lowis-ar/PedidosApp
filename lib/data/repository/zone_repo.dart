import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../utils/app_constants.dart';

class ZoneRepo {
  final ApiClient apiClient;
  ZoneRepo({required this.apiClient});

  Future<Response> getZoneList() async {
    return await apiClient.getData(AppConstants.ZONES_URI);
  }
}
