import 'dart:io';
import 'package:coldcall/core/simple_future_listenable_builders.dart';
import 'package:coldcall/features/dialer/_camera_dialer_vm.dart';
import 'package:coldcall/features/dialer/dialer_overlay.dart';
import 'package:coldcall/features/dialer/phone_crosshair_overlay.dart';
import 'package:coldcall/features/dialer/phone_painter_overlay.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraDialerScreen extends StatefulWidget {
  @override
  createState() => _CameraDialerScreenState();
}

class _CameraDialerScreenState extends State<CameraDialerScreen> with SingleTickerProviderStateMixin {
  late final _model = CameraDialerVm();
  late final _initFuture = _model.init(context);

  final _cameraPreviewKey = GlobalKey();
  Size? _cameraPreviewSize;

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        return PopScope(
          canPop: !_model.isDialerShown,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _model.dialerOverlayModel?.closeDialer(false);
          },
          child: Scaffold(
            body: SafeArea(
              child: SimpleFutureBuilder(
                future: _initFuture,
                // это не фатальная ошибка, можно вручную номер набрать
                errorBuilder: (e, _) => Stack(
                  children: [
                    Center(child: Text(e.toString())),

                    // Набор номера вручную
                    if (!_model.isDialerShown)
                      Positioned(
                        bottom: 35,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton(onPressed: _model.showDialer, child: Icon(Icons.call)),
                        ),
                      ),

                    // Панель набора номера с полноэкранным оверлеем
                    if (_model.isDialerShown) DialerOverlay(model: _model.dialerOverlayModel!),
                  ],
                ),
                builder: (context, _) {
                  final screenSize = MediaQuery.of(context).size;
                  final cameraSize = _model.cameraController!.value.previewSize!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final box = _cameraPreviewKey.currentContext?.findRenderObject() as RenderBox;
                    _cameraPreviewSize = box.size;
                  });
                  return Stack(
                    children: [
                      // Превью камеры
                      Center(
                        child: Stack(
                          key: _cameraPreviewKey,
                          children: [
                            CameraPreview(_model.cameraController!),

                            // Прицел (для выбора телефона из нескольких)
                            const Positioned.fill(child: PhoneCrosshairOverlay()),

                            // Замороженный кадр (если открыт диалер)
                            if (_model.frozenFramePath != null) Image.file(File(_model.frozenFramePath!)),

                            // Overlay с рамками вокруг телефонов
                            if (_model.detectedPhones.isNotEmpty)
                              CustomPaint(
                                painter: PhonePainterOverlay(
                                  detectedPhones: _model.detectedPhones,
                                  selectedPhone: _model.selectedPhone,
                                  imageSize: Size(cameraSize.height, cameraSize.width),
                                  screenSize: _cameraPreviewSize ?? screenSize,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Счетчик найденных номеров
                      if (_model.detectedPhones.isNotEmpty)
                        Positioned(
                          top: 35,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                              child: Column(
                                mainAxisSize: .min,
                                children: [
                                  Text(
                                    'Найдено номеров: ${_model.detectedPhones.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  if (_model.selectedPhones.isNotEmpty)
                                    Text(
                                      'кадров: ${_model.selectedPhones.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      Positioned(bottom: 110, left: 0, right: 0, child: Center(child: Text('Наведите камеру на номер'))),

                      // Набор номера вручную
                      if (!_model.isDialerShown)
                        Positioned(
                          bottom: 35,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FloatingActionButton(onPressed: _model.showDialer, child: Icon(Icons.call)),
                          ),
                        ),

                      // Панель набора номера с полноэкранным оверлеем
                      if (_model.isDialerShown) DialerOverlay(model: _model.dialerOverlayModel!),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
