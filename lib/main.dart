import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo/models/future_todo.dart';

import 'package:todo/utils/hive_repository.dart';
import 'package:todo/screens/splash_screen.dart';
import 'package:todo/models/event_data.dart';

// Sentry code to get emailed exceptions
// import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(EventDataAdapter());
  Hive.registerAdapter(FutureTodoAdapter());

  await Hive.openBox<EventData>('monthEventBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  await Hive.openBox<EventData>('dailyEventBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  await Hive.openBox<FutureTodo>('futureTodosBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  // Sentry code to get emailed exceptions
  // await SentryFlutter.init(
  //   (options) { options.dsn = 'https://8457a9015b0f4e978bd2078b054503cb@o4505104841965568.ingest.sentry.io/4505104845766656';
  //   options.debug = true;
  //   },

  //   appRunner: () => 
    runApp(const TodoApp()
    // Sentry code to get emailed exceptions
    // )
    );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

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
      title: '//TODOː',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        fontFamily: 'Raleway',
      ),
      home: RepositoryProvider(create: (context) => HiveRepository(), child: const SplashScreen()),
    );
  }
}
