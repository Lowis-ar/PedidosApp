import 'package:get/get.dart';
import '../data/repository/zone_repo.dart';
import '../models/zone_model.dart';

class ZoneController extends GetxController implements GetxService {
  final ZoneRepo zoneRepo;
  ZoneController({required this.zoneRepo});

  List<ZoneModel> _zoneList = [];
  List<ZoneModel> get zoneList => _zoneList;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  int _selectedZoneId = -1;
  int get selectedZoneId => _selectedZoneId;

  Future<void> getZoneList() async {
    Response response = await zoneRepo.getZoneList();
    if (response.statusCode == 200) {
      _zoneList = [];
      final body = response.body;
      var zones = body['data'];
      if (zones != null && zones is List) {
        for (var z in zones) {
          _zoneList.add(ZoneModel.fromJson(z));
        }
      }
      if (_zoneList.isNotEmpty) {
        _selectedZoneId = _zoneList[0].id;
      }
      _isLoaded = true;
      update();
    }
  }

  void setZoneId(int id) {
    _selectedZoneId = id;
    update();
  }
}
