import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/utils/hive_repository.dart';
import 'package:todo/widgets/todo_pages.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/event_data.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(EventDataAdapter());
  await Hive.openBox<EventData>('monthEventBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  await Hive.openBox<EventData>('dailyEventBox', compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20;
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        primarySwatch: Colors.blue,
        fontFamily: 'Raleway',
      ),
      home: RepositoryProvider(
          create: (context) => HiveRepository(),
          child: MultiBlocProvider(providers: [
            BlocProvider<DailyMonthlyListCubit>(
              create: (_) => DailyMonthlyListCubit(context.read<HiveRepository>()),
            ),
            BlocProvider<DateCubit>(
              create: (_) => DateCubit(),
            ),
          ], child: TodoPages())),
    );
  }
}
