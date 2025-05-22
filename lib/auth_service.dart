// ignore_for_file: body_might_complete_normally_nullable, unnecessary_import, avoid_print, use_build_context_synchronously, no_leading_underscores_for_local_identifiers, unused_catch_clause, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:http/http.dart' as http;

import 'package:rmsn_generator/controller.dart';
import 'package:rmsn_generator/excel_service.dart';
import 'package:rmsn_generator/hive_dao.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  AuthService._();
  static final AuthService _singleton = AuthService._();
  factory AuthService() => _singleton;

  final controller = Get.put(Controller());

  final HiveDao _hiveDao = HiveDao();

  final ExcelService excelService = ExcelService();

  String generateAuthState() {
    var random = Random.secure();
    var values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }


  String generateCodeVerifier() {
    return base64Url
        .encode(List<int>.generate(64, (_) => Random.secure().nextInt(256)))
        .replaceAll('=', '');
  }

  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }


  Future<String?> listenForRedirect({int port = 5000}) async {
    HttpServer server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print("Listening on http://localhost:$port");

    try {
      final request = await server.first;
      final uri = request.uri;
      final code = uri.queryParameters['code'];

      // Optional: Return a silent/empty or auto-close response
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('''
        <html>
          <head>
            <title>Redirecting...</title>
            <script>
              window.close();
            </script>
          </head>
          <body>
          </body>
        </html>
      ''');
      await request.response.close();

      return code;
    } catch (e) {
      print("Redirect listener error: $e");
      return null;
    } finally {
      await server.close(force: true);
      print("Server on port $port closed");
    }
  }

  Future<void> authenticateUser(BuildContext context) async {
    const clientId = '';
    const tenantId = '';
    const redirectUri = 'http://localhost:5000';
    const tokenUrl =
        'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token';
    const authUrl =
        'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize';
    const scopes = 'Files.ReadWrite Files.ReadWrite.All Sites.ReadWrite.All';

    try {
      controller.isLoading.value = true;

      final state = generateAuthState();
      final codeVerifier = generateCodeVerifier();
      final codeChallenge = generateCodeChallenge(codeVerifier);

      final url = Uri.parse('$authUrl?client_id=$clientId'
          '&response_type=code'
          '&redirect_uri=$redirectUri'
          '&response_mode=query'
          '&scope=${Uri.encodeComponent(scopes)}'
          '&state=$state'
          '&code_challenge=$codeChallenge'
          '&code_challenge_method=S256');

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open browser for authentication.');
      }

      final authCode = await listenForRedirect();
      if (authCode == null) throw Exception("No authorization code received.");

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'scope': scopes,
          'code': authCode,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body);
        final accessToken = token['access_token'];

        if (accessToken != null && accessToken.isNotEmpty) {
          controller.accessToken.value = accessToken;
          _hiveDao.saveUserToken(accessToken);
          await fetchSiteAndDriveId(accessToken);
          fetchLastSerialNumber(context);
        } else {
          throw Exception("Access token is empty.");
        }
      } else {
        throw Exception("Token request failed: ${response.body}");
      }
    } catch (e) {
      controller.accessToken.value = "";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Authentication failed: $e',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
      controller.newSerialNumber.value = "-";
    } finally {
      controller.isLoading.value = false;
    }
  }

  Future<void> fetchSiteAndDriveId(String accessToken) async {
    String siteName = "";
    String domain = "";

    final siteUrl =
        "https://graph.microsoft.com/v1.0/sites/$domain:/sites/$siteName";

    final siteResponse = await http.get(
      Uri.parse(siteUrl),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Accept": "application/json",
      },
    );

    if (siteResponse.statusCode == 200) {
      final siteData = json.decode(siteResponse.body);
      String siteId = siteData["id"];
      //print("Site ID: $siteId");

      controller.siteID.value = siteId;
      _hiveDao.saveSiteID(siteId);
    } else {
      print("Error fetching Site ID: ${siteResponse.body}");
    }
  }

  final String excelId = "";

  void fetchLastSerialNumber(BuildContext context) async {
    print("triggered fetching");
    controller.isLoading.value = true;
    controller.newSerialNumber.value = "Loading...";
    try {
      String? lastSerial = await excelService.getLastSerialNumber(
          controller.accessToken.value,
          excelId,
          controller.siteID.value,
          context);
      if (lastSerial != null) {
        controller.lastSerialNumber.value = lastSerial;
        controller.newSerialNumber.value = generateSerialNumber(lastSerial);
      } else {
        controller.lastSerialNumber.value = "-";
        controller.newSerialNumber.value = "-";
      }

      controller.isLoading.value = false;
    } on Exception catch (error) {
      controller.isLoading.value = false;
      controller.accessToken.value = "";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '$error',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));

      controller.newSerialNumber.value = "-";
    }
  }

  String generateSerialNumber(String lastFullSerial) {

    String baseSerial = lastFullSerial.substring(0, 6);
    int nextBaseNumber = int.parse(baseSerial) + 1;
    String newBaseSerial = nextBaseNumber.toString().padLeft(6, '0');


    int calculateChecksum(String number) {
      int sum = 0;

      for (int i = 0; i < 6; i++) {
        int value = int.parse(number[i]);
        int addOne = 0;

        if ((i % 2) == 0) {
  
          if (value > 4) addOne = 1;
          sum += (2 * value) + addOne;
        } else {
 
          sum += value;
        }
      }

      int checksum = (10 - (sum % 10)) % 10;
      return checksum;
    }

    int checksum = calculateChecksum(newBaseSerial);

    return newBaseSerial + checksum.toString();
  }

  void generateAndSaveSerialNumber(
      TextEditingController companyController,
      TextEditingController addressController,
      TextEditingController emailController,
      BuildContext context) async {
    controller.isLoading.value = true;
    try {
      await excelService.appendSerialNumber(
          controller.accessToken.value,
          controller.siteID.value,
          controller.newSerialNumber.value,
          companyController.text.isEmpty ? "Default" : companyController.text,
          addressController.text.isEmpty ? "Default" : addressController.text,
          emailController.text.isEmpty ? "Default" : emailController.text,
          context);
      companyController.clear();
      addressController.clear();
      emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Serial number added: ${controller.newSerialNumber.value}")));
      fetchLastSerialNumber(context);
    } on Exception catch (error) {
      controller.isLoading.value = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '$error',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));
    }
  }
}
