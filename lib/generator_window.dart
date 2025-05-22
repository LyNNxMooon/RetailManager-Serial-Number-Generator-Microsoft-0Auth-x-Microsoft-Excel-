// ignore_for_file: use_build_context_synchronously, avoid_print, duplicate_ignore

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:rmsn_generator/auth_service.dart';

import 'package:rmsn_generator/controller.dart';
import 'package:rmsn_generator/excel_service.dart';
//import 'package:rmsn_generator/google_sheets_services.dart';

class GeneratorWindow extends StatefulWidget {
  const GeneratorWindow({super.key});

  @override
  State<GeneratorWindow> createState() => _GeneratorWindowState();
}

class _GeneratorWindowState extends State<GeneratorWindow> {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  String connection = "online";

  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  final ExcelService excelSheetService = ExcelService();

  String? accessToken;

  final String sheetName = "Sheet1";

  final controller = Get.put(Controller());

  final AuthService authService = AuthService();

  @override
  void initState() {
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    super.initState();

    if (connection == "online") {
      if (controller.accessToken.value.isNotEmpty) {
        //authService.authenticateUser();
        authService.fetchLastSerialNumber(context);
      }
    }
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;

    result = await _connectivity.checkConnectivity();
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
      if (_connectionStatus[0] == ConnectivityResult.none) {
        connection = "offline";
      } else {
        connection = "online";
        //authService.fetchLastSerialNumber(context);
      }
    });

    print('Connectivity changed: $_connectionStatus');
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _companyController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: connection == "online"
          ? Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Image.asset(
                      "assets/images/aaapos.png",
                      width: 70,
                      height: 30,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const Gap(20),
                Center(
                  child: Image.asset(
                    "assets/images/rmlogo.png",
                    width: 160,
                    height: 40,
                    fit: BoxFit.fill,
                  ),
                ),
                Divider(
                  thickness: 0.5,
                  height: 50,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Company Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ),
                const Gap(5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    height: 40,
                    child: formfield("Enter Company Name", "Company Name", 1,
                        _companyController),
                  ),
                ),
                const Gap(10),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Address",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ),
                const Gap(5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                      height: 40,
                      child: formfield(
                          "Enter Address", "Address", 1, _addressController)),
                ),
                const Gap(10),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Email",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ),
                const Gap(5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                      height: 40,
                      child: formfield(
                          "Enter Email", "Email", 1, _emailController)),
                ),
                Divider(
                  thickness: 0.5,
                  height: 40,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Serial Number",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ),
                const Gap(5),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Row(
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                    text: controller.newSerialNumber.value))
                                .then(
                              (value) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Copied to Clipboard!")));
                              },
                            );
                          },
                          child: Container(
                            width: 110,
                            height: 38,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    width: 1.5,
                                    color: Color.fromARGB(66, 61, 60, 60))),
                            child: Center(
                              child: Text(controller.newSerialNumber.value),
                            ),
                          ),
                        ),
                      ),
                      const Gap(20),
                      Obx(
                        () => controller.isLoading.value
                            ? Container(
                                width: 110,
                                height: 38,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Color.fromRGBO(15, 138, 190, 1)),
                                child: Center(
                                    child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                )),
                              )
                            : controller.accessToken.value.isEmpty
                                ? GestureDetector(
                                    onTap: () async {
                                      await authService
                                          .authenticateUser(context);
                                    },
                                    child: Container(
                                      width: 110,
                                      height: 38,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color:
                                              Color.fromRGBO(15, 138, 190, 1)),
                                      child: Center(
                                        child: Text(
                                          "Login",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      authService.generateAndSaveSerialNumber(
                                          _companyController,
                                          _addressController,
                                          _emailController,
                                          context);
                                    },
                                    child: Container(
                                      width: 110,
                                      height: 38,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color:
                                              Color.fromRGBO(15, 138, 190, 1)),
                                      child: Center(
                                        child: Text(
                                          "Append",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                      const Gap(20),
                      GestureDetector(
                        onTap: () {
                          authService.fetchLastSerialNumber(context);
                        },
                        child: Container(
                          width: 110,
                          height: 38,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  width: 1,
                                  color: Color.fromRGBO(15, 138, 190, 1))),
                          child: Center(
                            child: Text(
                              "Refresh",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(15, 138, 190, 1)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(55),
                Center(
                  child: Text(
                    "Copyright 2025 - AAAPOS",
                    style: TextStyle(
                        fontSize: 10, color: Color.fromRGBO(15, 138, 190, 1)),
                  ),
                )
              ],
            )
          : Center(
              child: Icon(
                Icons.signal_wifi_statusbar_connected_no_internet_4,
                size: 80,
                color: Colors.black54,
              ),
            ),
    );
  }

  Widget formfield(String hintText, String label, int? maxLines,
      TextEditingController controller) {
    return TextField(
        style: TextStyle(fontSize: 14),
        // autovalidateMode: AutovalidateMode.onUserInteraction,
        maxLines: maxLines,
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black45),
          //labelText: label,
          // labelStyle: const TextStyle(color: Colors.black),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: const BorderSide(width: 1, color: Colors.black),
          // ),
          border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color.fromARGB(66, 56, 55, 55),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                  width: 1.5, color: Color.fromARGB(66, 61, 60, 60)),
              borderRadius: BorderRadius.circular(10)),
        ));
  }
}
