import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nino_tag.dart';

class QrScreen extends StatefulWidget {
  final NinoTag nino;
  final String webUrgenciaUrl;

  const QrScreen({
    super.key,
    required this.nino,
    required this.webUrgenciaUrl,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _reporKey = GlobalKey();
  double _tamano = 200;
  bool _exportando = false;

  String get _url => '${widget.webUrgenciaUrl}nino/${widget.nino.idTag}';

  Future<void> _exportarQr() async {
    setState(() => _exportando = true);
    try {
      final boundary = _reporKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('No se pudo generar la imagen');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_${widget.nino.idTag}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR KidLink - ${widget.nino.nombreNino}',
        text:
            'En caso de emergencia, escanee este código o acerque el celular para leer el chip NFC',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR de ${widget.nino.nombreNino}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            RepaintBoundary(
              key: _reporKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: _url,
                      version: QrVersions.auto,
                      size: _tamano,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                    'En caso de emergencia, escanee este código\n'
                    'o acerque el celular para leer el chip NFC',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_tamano.round()}×${_tamano.round()} px',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Slider(
                value: _tamano,
                min: 100,
                max: 300,
                divisions: 40,
                label: '${_tamano.round()} px',
                onChanged: (v) => setState(() => _tamano = v),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _exportando ? null : _exportarQr,
                  icon: _exportando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share),
                  label: const Text(
                    'Imprimir / Compartir QR',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
