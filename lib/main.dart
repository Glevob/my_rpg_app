import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 1. Импорт локализаций
import 'screens/home_screen.dart';
import 'utils/task_utils.dart';

void main() async {
  // 1. Обязательно для работы с асинхронными методами до runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Загружаем настройки опыта из памяти
  await loadXpSettings();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      
      // 2. Настройка локализации для всего приложения
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'), // Принудительно ставим русский
      
      home: const HomeScreen(),
    );
  }
}