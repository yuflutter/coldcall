import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/_all_syncable_entities.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

/// Одноразовая вьюмодель дозвонщика, после окончания записывает историю и уничтожается. Для нового звонка нужно создать новую модель.
class DialerVm with SimpleChangeNotifier {
  final String? initialPhone;
  final Deal? deal;
  final void Function(bool isCallEnded) closeFromOutside;

  DialerVm({this.initialPhone, this.deal, required this.closeFromOutside});

  late final phoneEditingController = TextEditingController(
    text: di<AppConfig>().phoneNumberFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: initialPhone ?? '')).text,
  );
  String get phone => phoneEditingController.text.trim();

  DateTime? startTime;
  bool get isCalling => (startTime != null);

  // контроллер анимации перенесен в модель, чтобы обеспечить плавность закрытия оверлея извне
  AnimationController? animationController;

  @override
  void dispose() {
    phoneEditingController.dispose();
    animationController?.dispose();
    super.dispose();
  }

  Future<void> startCall(BuildContext context) async {
    if (phone.isEmpty) return;
    try {
      if (await FlutterPhoneDirectCaller.callNumber(phone) != true) return;
      notify(() => startTime = DateTime.now());
    } catch (e, s) {
      notify(() => startTime = null);
      Err.add(e, s);
    }
  }

  Future<void> closeDialer(bool isCalling) async {
    try {
      if (isCalling) saveCallInHistory();
      await animationController?.reverse();
      closeFromOutside(isCalling);
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> saveCallInHistory() async {
    if (!isCalling) return;

    final record = HistoryRecord.manually(
      deal: deal,
      startTime: startTime!,
      duration: DateTime.now().difference(startTime!),
      phoneNumber: phone,
    );

    await di<HistoryVm>().updateDeal(record.deal!);
  }
}
