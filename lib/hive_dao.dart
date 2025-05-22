import 'package:hive/hive.dart';
import 'package:rmsn_generator/hive_constant.dart';

class HiveDao {
  HiveDao._();
  static final HiveDao _singleton = HiveDao._();
  factory HiveDao() => _singleton;

  Box<String> userTokenBox() => Hive.box<String>(kHiveBoxForToken);

  void saveUserToken(String token) {
    userTokenBox().put(kHiveKeyForToken, token);
  }

  String get getUserToken => userTokenBox().get(kHiveKeyForToken) ?? "";

  Box<String> siteIDBox() => Hive.box<String>(kHiveBoxForSiteID);

  void saveSiteID(String id) {
    siteIDBox().put(kHiveKeyForSiteID, id);
  }

  String get getSiteID => siteIDBox().get(kHiveKeyForSiteID) ?? "";
}
