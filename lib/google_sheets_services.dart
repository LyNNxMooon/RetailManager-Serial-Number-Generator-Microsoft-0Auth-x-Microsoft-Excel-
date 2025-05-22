import 'dart:io';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetsService {
  static const _scopes = [SheetsApi.spreadsheetsScope];

  
  static Future<SheetsApi> getSheetsApi() async {
    final credentials = File('${Directory.current.path}/assets/credentials.json').readAsStringSync();
    final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
    final client = await clientViaServiceAccount(accountCredentials, _scopes);
    return SheetsApi(client);
  }

  Future<String?> getLastSerialNumber(
      String spreadsheetId, String sheetName) async {
    final sheetsApi = await getSheetsApi();
    final range = '$sheetName!A:A';
    final response =
        await sheetsApi.spreadsheets.values.get(spreadsheetId, range);

    if (response.values == null || response.values!.isEmpty) {
      return null;
    }

    return response.values!.last.first.toString();
  }

  Future<void> appendSerialNumber(String spreadsheetId, String sheetName,
      String serialNumber, String company, String address, String email) async {
    final sheetsApi = await getSheetsApi();
    final range = '$sheetName!A:D';

    ValueRange valueRange = ValueRange()
      ..values = [
        [serialNumber, company, address, email]
      ];

    await sheetsApi.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      range,
      valueInputOption: 'RAW',
    );

    print("Serial number added: $serialNumber");
  }
}
