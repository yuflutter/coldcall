import 'dart:async';

import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/dart_mappable_settings.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/error_presenters.dart';
import 'package:coldcall/core/simple_future_listenable_builders.dart';
import 'package:coldcall/features/recorder/_recorder_recognizer_screen.dart';
import 'package:coldcall/features/recorder/_recorder_recognizer_vm.dart';
import 'package:coldcall/features/user_session/user_session_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/dialer/_camera_dialer_screen.dart';
import 'features/history/_history_screen.dart';
import 'features/user_session/user_session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Устанавливаем только портретную ориентацию
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Регистрируем мапперы сериализатора
  registerJsonMappers();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _initFuture = initApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColdCall',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Включаем темный режим здесь
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          primary: Colors.green, // Основной цвет для кнопок и ссылок
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green, // Явно задаем цвет иконки
          unselectedItemColor: Colors.grey,
        ),
        appBarTheme: AppBarTheme(titleTextStyle: TextStyle(fontSize: 20)),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          sizeConstraints: const BoxConstraints.tightFor(width: 60, height: 60),
          iconSize: 40,
          shape: const CircleBorder(),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: SimpleFutureBuilder(
        future: _initFuture,
        builder: (context, _) {
          return MainScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Экраны пересоздаются все, а модели по разному. Часть моделей лежит в глобальном DI, а часть создается по месту.
  final _screens = [() => CameraDialerScreen(), () => RecorderRecognizerScreen(), () => HistoryScreen(), () => UserSessionScreen()];
  var _currentIndex = 0;
  late var _currentScreen = _screens[_currentIndex]();
  late final StreamSubscription _errSubs;

  @override
  void dispose() {
    _errSubs.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _errSubs = di<Err>().errStream.listen((e) {
      if (context.mounted) showErrorPresenterPopup(context, e);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListenableBuilder(
      listenable: di<UserSessionVm>(),
      builder: (context, session, _) {
        final deal = session.turnToRecordForDeal;
        if (deal != null) {
          _currentIndex = 1;
          _currentScreen = RecorderRecognizerScreen(deal: deal, startImmediately: true);
        }
        return Scaffold(
          body: _currentScreen,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index != _currentIndex) {
                setState(() {
                  _currentIndex = index;
                  _currentScreen = _screens[index]();
                });
              }
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Позвонить'),
              BottomNavigationBarItem(
                icon: SimpleListenableBuilder(
                  listenable: di<RecorderRecognizerVm>(), // ищем по суперклассу
                  builder: (context, model, _) {
                    return Badge(isLabelVisible: model.isSessionActive, child: Icon(Icons.mic));
                  },
                ),
                label: 'Записать',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
            ],
          ),
        );
      },
    );
  }
}
