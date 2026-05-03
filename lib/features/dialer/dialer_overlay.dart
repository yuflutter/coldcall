import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/features/dialer/dialer_vm.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Оверлей дозвонщика, должен вставляться в стек родителя, родитель должен обрабатывать PopScope.
/// Модель дозвонщика создается в модели родителя.
class DialerOverlay extends StatefulWidget {
  final DialerVm model;

  const DialerOverlay({super.key, required this.model});

  @override
  createState() => _DialerOverlayState();
}

class _DialerOverlayState extends State<DialerOverlay> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _model = widget.model;

  bool _isNumberChanged = false;

  bool _appWasInPausedState = false;

  late Animation<double> _slideAnimation;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // контроллер перенесен в модель, чтобы обеспечить плавность закрытия извне
    _model.animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this)
      ..forward();
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _model.animationController!, curve: Curves.easeInOut));

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();
    super.dispose();
  }

  // Таким образом определяем завершение звонка. Не лучшее решение, но не хочется запрашивать лишние разрешения ОС
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    Log.deb(state);

    // открылось системное приложение Телефон
    if (state == .paused) {
      _appWasInPausedState = true;
      return;
    }

    // Когда приложение возвращается в фокус после звонка
    if (state == AppLifecycleState.resumed && _appWasInPausedState) {
      _appWasInPausedState = false;
      _model.closeDialer(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha(100),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _model.closeDialer(false),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Сама панель
                GestureDetector(
                  onVerticalDragStart: (details) {
                    _dragOffset = 0.0;
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _dragOffset += details.primaryDelta!;
                      // Ограничиваем драг только вниз
                      if (_dragOffset < 0) _dragOffset = 0;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    // Свайп вниз закрывает оверлей
                    if (_dragOffset > 100 || details.primaryVelocity! > 300) {
                      _model.closeDialer(false);
                    } else {
                      // Возвращаем на место
                      setState(() => _dragOffset = 0.0);
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 400 + _dragOffset),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Ручка
                              Container(
                                margin: const EdgeInsets.only(top: 10, bottom: 25),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(100),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Padding(
                                padding: .fromLTRB(15, 0, 15, 0),
                                child: Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withAlpha(100),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: _model.phoneEditingController,
                                              autofocus: (_model.initialPhone == null),
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.phone,
                                              inputFormatters: [di<AppConfig>().phoneNumberFormatter],
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                hintText: 'Введите номер',
                                                hintStyle: TextStyle(color: Colors.grey, fontWeight: .normal),
                                              ),
                                              onChanged: (_) => setState(() => _isNumberChanged = true),
                                            ),
                                          ),
                                        ),
                                        Gap(15),
                                        (!_model.isCalling)
                                            ? FloatingActionButton(
                                                onPressed: () => _model.startCall(context),
                                                child: Icon(Icons.call),
                                              )
                                            : FloatingActionButton(onPressed: null, child: Icon(Icons.call)),
                                        // : FloatingActionButton(onPressed: () => _model.closeDialer(false), child: Icon(Icons.close)),
                                      ],
                                    ),
                                    if (_model.initialPhone?.name?.isNotEmpty == true && !_isNumberChanged) ...[
                                      Gap(10),
                                      Text('(${_model.initialPhone!.name!})', style: TextStyle(color: Colors.yellow)),
                                    ] else
                                      Gap(10),
                                  ],
                                ),
                              ),
                              Gap(23),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
