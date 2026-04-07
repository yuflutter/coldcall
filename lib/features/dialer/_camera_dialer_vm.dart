import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/show_toastification.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:coldcall/features/dialer/dialer_vm.dart';
import 'package:coldcall/features/dialer/phone_detector_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraDialerVm with SimpleChangeNotifier {
  CameraController? cameraController;

  List<DetectedPhoneNumber> detectedPhones = [];
  DetectedPhoneNumber? selectedPhone;
  String? frozenFramePath; // Путь к замороженному кадру
  BuildContext? _context; // нужен для получения размера экрана (используется для работы прицела)

  final _phoneDetector = PhoneDetectorService();
  Timer? _videoProcessingTimer;
  var _isVideoProcessing = false;

  // диалер
  DialerVm? dialerOverlayModel;
  bool get isDialerShown => (dialerOverlayModel != null);

  @override
  void dispose() {
    dialerOverlayModel?.dispose();
    _videoProcessingTimer?.cancel();
    _phoneDetector.dispose();
    cameraController?.dispose();

    // Удаляем замороженный кадр при выходе
    if (frozenFramePath != null) {
      try {
        File(frozenFramePath!).deleteSync();
      } catch (e) {
        print('Error deleting frozen frame on dispose: $e');
      }
    }
    super.dispose();
  }

  Future<void> init(BuildContext context) async {
    _context = context;

    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      throw 'Нет разрешения на использование камеры';
    } else {
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw 'Камера не найдена на устройстве';
        } else {
          cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
          await cameraController!.initialize();
          _startVideoProcessing();
        }
      } catch (e) {
        throw 'Ошибка инициализации камеры: $e';
      }
    }
  }

  void _startVideoProcessing() {
    _stopVideoProcessing();
    _videoProcessingTimer = Timer.periodic(di<AppConfig>().frameProcessingRate, (_) => _processFrame());
  }

  void _stopVideoProcessing() {
    _videoProcessingTimer?.cancel();
  }

  Future<void> _processFrame() async {
    if (_isVideoProcessing || cameraController == null || !cameraController!.value.isInitialized) return;

    _isVideoProcessing = true;
    String? tempFramePath;

    try {
      final XFile image = await cameraController!.takePicture();
      tempFramePath = image.path;
      final InputImage inputImage = InputImage.fromFilePath(image.path);

      final phones = await _phoneDetector.detectPhones(inputImage);
      notify(() => detectedPhones = phones);

      await _selectPhone(phones, image.path);
    } catch (e) {
      print('Error processing frame: $e');
    }

    // Удаляем временный файл, если он не используется для отображения
    if (tempFramePath != null && tempFramePath != frozenFramePath) {
      File(tempFramePath).delete().then((v) => v, onError: (e, _) => print('Error deleting temp frame: $e'));
    }
    _isVideoProcessing = false;
  }

  Future<void> _selectPhone(List<DetectedPhoneNumber> phones, String framePath) async {
    if (phones.isEmpty) return notify(() => selectedPhone = null);

    // Если номер только один - выбираем автоматически
    if (phones.length == 1) {
      final phone = phones.first;
      if (selectedPhone?.cleanNumber != phone.cleanNumber) {
        showDialer(phone: phone, framePath: framePath);
      }

      // Если номеров несколько - выбираем тот, что попадает в прицел
    } else {
      final phone = _getPhoneInCrosshair(phones);
      if (phone != null && selectedPhone?.cleanNumber != phone.cleanNumber) {
        showDialer(phone: phone, framePath: framePath);

        // Ни один номер не попал в прицел
      } else {
        if (!isDialerShown) notify(() => selectedPhone = null);
      }
    }
  }

  DetectedPhoneNumber? _getPhoneInCrosshair(List<DetectedPhoneNumber> phones) {
    if (cameraController == null || !cameraController!.value.isInitialized || _context?.mounted != true) return null;

    final cameraSize = cameraController!.value.previewSize!;
    final size = MediaQuery.of(_context!).size;
    final double scaleX = size.width / cameraSize.height;
    final double scaleY = size.height / cameraSize.width;

    // Координаты центра прицела
    final double crosshairX = size.width / 2;
    final double crosshairY = size.height / 3;
    final Offset crosshairCenter = Offset(crosshairX, crosshairY);

    // Проверяем, какой номер попадает в прицел
    for (var phone in phones) {
      final Rect scaledRect = Rect.fromLTRB(
        phone.boundingBox.left * scaleX,
        phone.boundingBox.top * scaleY,
        phone.boundingBox.right * scaleX,
        phone.boundingBox.bottom * scaleY,
      );

      if (scaledRect.contains(crosshairCenter)) {
        return phone;
      }
    }
    return null;
  }

  void showDialer({DetectedPhoneNumber? phone, String? framePath}) async {
    _stopVideoProcessing();

    // Удаляем старый замороженный кадр, если он есть
    if (frozenFramePath != null && frozenFramePath != framePath) {
      File(frozenFramePath!).delete().then((v) => v, onError: (e, _) => print('Error deleting frozen frame: $e'));
    }

    notify(() {
      selectedPhone = phone;
      frozenFramePath = framePath;
      dialerOverlayModel = DialerVm(initialPhone: phone?.cleanNumber, closeFromOutside: _closeDialer);
    });

    HapticFeedback.lightImpact();
  }

  void _closeDialer(bool isCallEnded) async {
    _startVideoProcessing();

    // Удаляем замороженный кадр
    if (frozenFramePath != null) {
      File(frozenFramePath!).delete().then((v) => v, onError: (e, _) => print('Error deleting frozen frame: $e'));
    }

    notify(() {
      frozenFramePath = null;
      selectedPhone = null;
      detectedPhones.clear();
      dialerOverlayModel = null;
    });

    if (_context!.mounted && isCallEnded) showToastification(_context!, 'Звонок сохранен в историю');
  }
}
