import 'package:get/get.dart';
import '../../utils/app_constants.dart';
import '../api/api_client.dart';

class BranchRepo extends GetxService {
  final ApiClient apiClient;
  BranchRepo({required this.apiClient});

  Future<Response> getBranchList() async {
    return await apiClient.getData(AppConstants.BRANCHES_URI, handleError: false);
  }
}
