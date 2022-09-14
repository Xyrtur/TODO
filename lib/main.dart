import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:todo/utils/hive_repository.dart';
import 'package:todo/screens/splash_screen.dart';
import 'package:todo/models/event_data.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(EventDataAdapter());
  await Hive.openBox<EventData>('monthEventBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  await Hive.openBox<EventData>('dailyEventBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'),
      ],
      title: 'TODOː',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        fontFamily: 'Raleway',
      ),
      home: RepositoryProvider(create: (context) => HiveRepository(), child: const SplashScreen()),
    );
  }
}
