import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:todo/utils/centre.dart';
import 'package:todo/utils/hive_repository.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/screens/todo_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedSplashScreen.withScreenFunction(
          backgroundColor: Centre.bgColor,
          pageTransitionType: PageTransitionType.fade,
          splashTransition: SplashTransition.sizeTransition,
          animationDuration: const Duration(milliseconds: 1),
          duration: 1100,
          splash: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                '// TODO:',
                textStyle: TextStyle(
                  fontSize: 32.0,
                  fontFamily: 'Droid Sans',
                  color: Centre.primaryColor,
                ),
                speed: const Duration(milliseconds: 200),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          screenFunction: () async {
            try {
             
  context.read<HiveRepository>().cacheInitialData();
            context.read<HiveRepository>().futureTodosHive.clear();

            return RepositoryProvider.value(
              value: context.read<HiveRepository>(),
              child: MultiBlocProvider(providers: [
                BlocProvider<DailyMonthlyListCubit>(
                  create: (_) => DailyMonthlyListCubit(context.read<HiveRepository>()),
                ),
                BlocProvider<DateCubit>(
                  create: (_) => DateCubit(),
                ),
                BlocProvider<FirstDailyDateBtnCubit>(
                  create: (_) => FirstDailyDateBtnCubit(),
                ),
                BlocProvider<ImportExportBloc>(
                  create: (context) => ImportExportBloc(context.read<HiveRepository>()),
                ),
                BlocProvider(create: (_) => ToggleChecklistEditingCubit()),
                BlocProvider(create: (_) => MonthDateCubit()),
                BlocProvider<MonthlyTodoBloc>(
                  create: (BuildContext context) => MonthlyTodoBloc(context.read<HiveRepository>()),
                ),
                BlocProvider<TodoBloc>(
                    create: (BuildContext context) => TodoBloc(context.read<HiveRepository>())),
                BlocProvider<UnfinishedListBloc>(
                    create: (BuildContext context) => UnfinishedListBloc(context.read<HiveRepository>())),
              ], child: TodoPages()),
            );
          
} catch (exception, stackTrace) {
  await Sentry.captureException(
    exception,
    stackTrace: stackTrace,
  );
  return const SizedBox();
}
})
            
    );
  }
}
