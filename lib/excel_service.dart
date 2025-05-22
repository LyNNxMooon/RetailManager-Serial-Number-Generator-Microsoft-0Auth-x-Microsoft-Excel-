// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:rmsn_generator/controller.dart';

class ExcelService {
  ExcelService._();
  static final ExcelService _singleton = ExcelService._();
  factory ExcelService() => _singleton;

  Future<int> getLastUsedRow(String accessToken, String siteId) async {
    final Uri url = Uri.parse(
        "https://graph.microsoft.com/v1.0/sites/$siteId/drive/items/{fileID}/workbook/worksheets('Sheet1')/usedRange");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String address = data['address']; 

      RegExp regex = RegExp(r'[A-Z]+(\d+):[A-Z]+(\d+)');
      Match? match = regex.firstMatch(address);
      if (match != null) {
        int lastRow = int.parse(match.group(2)!);
        return lastRow + 1;
      }
    }

    throw Exception("Failed to fetch last row: ${response.body}");
  }

   Future<void> appendSerialNumber(String accessToken, String siteId,
      String serialNumber, String company, String address, String email, BuildContext context) async {
    int nextRow = await getLastUsedRow(accessToken, siteId);
    final Uri url = Uri.parse(
        "https://graph.microsoft.com/v1.0/sites/$siteId/drive/items/{fileID}/workbook/worksheets('Sheet1')/range(address='A$nextRow:D$nextRow')");

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "values": [
          [serialNumber, company, address, email]
        ]
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Serial number added at row $nextRow!");
    } else {
      controller.isLoading.value = false;
      controller.accessToken.value = "";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Check your network connection and try again!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));

      controller.newSerialNumber.value = "-";
    }
  }

    final controller = Get.put(Controller());

//

  Future<String?> getLastSerialNumber(
      String accessToken, String fileId, String siteId, BuildContext context) async {
    //final url = "https://graph.microsoft.com/v1.0/me/drive/items/$fileId/workbook/worksheets('Sheet1')/range(address='A:A')";

    final url =
        "https://graph.microsoft.com/v1.0/sites/$siteId/drive/items/{fileID}/workbook/worksheets('Sheet1')/range(address='A:A')/usedRange";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final values = data['values'];

      if (values == null || values.isEmpty) {
        return null; 
      }

      return values.last.first.toString(); 
    } else {
      controller.isLoading.value = false;
      controller.accessToken.value = "";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Invalid Token! Sign In Again!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));

      controller.newSerialNumber.value = "-";
      //print("Error fetching last serial number: ${response.body}");
      return null;
    }
  }
}
