// ignore_for_file: avoid_print



import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rmsn_generator/controller.dart';
import 'package:rmsn_generator/generator_window.dart';
import 'package:rmsn_generator/hive_constant.dart';
import 'package:rmsn_generator/hive_dao.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<String>(kHiveBoxForToken);
  await Hive.openBox<String>(kHiveBoxForSiteID);
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(450, 590),
    minimumSize: Size(450, 590),
    maximumSize: Size(450, 590),
    center: true,
    title: "Serial Number Generator",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.setPreventClose(false);
    await windowManager.setMaximizable(false);
  });

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = Get.put(Controller());

  final HiveDao _hiveDao = HiveDao();

  @override
  void initState() {
    //_hiveDao.saveSiteID("");
    //_hiveDao.saveUserToken("");
    controller.accessToken.value = _hiveDao.getUserToken;
    controller.siteID.value = _hiveDao.getSiteID;

    super.initState();
  }

 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Lexend",
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromRGBO(15, 138, 190, 1)),
        useMaterial3: true,
      ),
      home: const GeneratorWindow(),
    );
  }
}
