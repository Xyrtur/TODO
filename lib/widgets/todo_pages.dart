import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/daily_todo_bloc.dart';
import 'package:todo/screens/daily_page.dart';
import 'package:todo/screens/monthly_page.dart';
import 'package:todo/utils/hive_repository.dart';
import '../blocs/monthly_todo_bloc.dart';
import '../utils/centre.dart';

class TodoPages extends StatefulWidget {
  TodoPages({super.key});

  @override
  State<TodoPages> createState() => _TodoPagesState();
}

class _TodoPagesState extends State<TodoPages> {
  PageController controller = PageController(
    initialPage: 0,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);
    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: Material(
        child: PageView(
          controller: controller,
          children: [
            MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ToggleEditingCubit()),
                BlocProvider<TodoBloc>(create: (BuildContext context) => TodoBloc(context.read<HiveRepository>())),
              ],
              child: DailyPage(
                controller: controller,
              ),
            ),
            MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => MonthDateCubit()),
                BlocProvider<MonthlyTodoBloc>(
                  create: (BuildContext context) => MonthlyTodoBloc(context.read<HiveRepository>()),
                )
              ],
              child: MonthlyPage(controller: controller),
            )
          ],
        ),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
