import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart';

class NfcService {
  static final NfcService instance = NfcService._();
  NfcService._();

  Future<bool> estaDisponible() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  Future<void> escribirEnlaceNfc(String url) async {
    var availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      throw Exception('El sensor NFC está apagado o no disponible en este dispositivo.');
    }

    var tag = await FlutterNfcKit.poll(
      timeout: const Duration(seconds: 20),
      iosAlertMessage: "Acerque la etiqueta KidLink al teléfono...",
    );

    if (!tag.ndefWritable!) {
      await FlutterNfcKit.finish();
      throw Exception('La etiqueta NFC detectada está bloqueada o es de solo lectura.');
    }

    List<int> urlBytes = RegExp(r'^https://').hasMatch(url)
        ? [0x03, ...url.replaceFirst('https://', '').codeUnits]
        : [0x00, ...url.codeUnits];

    NDEFRecord record = NDEFRecord(
      tnf: TypeNameFormat.nfcWellKnown,
      type: Uint8List.fromList([0x55]),
      id: Uint8List(0),
      payload: Uint8List.fromList(urlBytes),
    );

    await FlutterNfcKit.writeNDEFRecords([record]);

    await FlutterNfcKit.finish(iosAlertMessage: "¡Pulsera vinculada con éxito!");
  }
}
