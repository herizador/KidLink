import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcService {
  static final NfcService instance = NfcService._();
  NfcService._();

  Future<bool> estaDisponible() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available ||
          availability == NFCAvailability.availableWithUserNotification;
    } catch (_) {
      return false;
    }
  }

  Future<void> escribirUrl(String url) async {
    final record = NdefRecord.fromUri(Uri.parse(url));
    final message = NdefMessage([record]);

    await FlutterNfcKit.writeNDEF(message, timeout: 30);
  }
}
