import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:swipe/swipe.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/screens/daily_page.dart';
import 'package:todo/screens/monthly_page.dart';
import 'package:todo/screens/unordered_page.dart';
import 'package:todo/utils/hive_repository.dart';
import '../utils/centre.dart';

class TodoPages extends StatefulWidget {
  TodoPages({super.key});
  final PanelController dailyPc = PanelController();
  final PanelController monthlyPc = PanelController();

  @override
  State<TodoPages> createState() => _TodoPagesState();
}

class _TodoPagesState extends State<TodoPages> {
  PageController controller = PageController(
    initialPage: 0,
  );
  double _visible = 1;
  bool finishedAnimating = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Wait 100ms before fading out
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _visible = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: Material(
        child: Scaffold(
          backgroundColor: Centre.darkerBgColor,
          body: Stack(
            children: [
              Swipe(
                // Depending on current pageview, open their respective panel
                onSwipeUp: () {
                  if (controller.page == 0) {
                    if (widget.dailyPc.isPanelClosed) {
                      widget.dailyPc.open();
                    }
                  } else if (controller.page == 1) {
                    if (widget.monthlyPc.isPanelClosed) {
                      widget.monthlyPc.open();
                    }
                  }
                },
                onSwipeDown: () {
                  if (controller.page == 0) {
                    if (widget.dailyPc.isPanelOpen) {
                      widget.dailyPc.close();
                    }
                  } else {
                    if (widget.monthlyPc.isPanelOpen) {
                      widget.monthlyPc.close();
                    }
                  }
                },
                verticalMaxWidthThreshold: 300,
                verticalMinDisplacement: 10,
                verticalMinVelocity: 50,
                horizontalMaxHeightThreshold: 300,
                horizontalMinDisplacement: 10,
                horizontalMinVelocity: 50,
                child: PageView(
                  controller: controller,
                  children: [
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<TodoBloc>(
                            create: (BuildContext context) => TodoBloc(context.read<HiveRepository>())),
                        BlocProvider(
                            create: (BuildContext context) => UnfinishedListBloc(context.read<HiveRepository>())),
                      ],
                      child: DailyPage(pc: widget.dailyPc),
                    ),
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<MonthlyTodoBloc>(
                          create: (BuildContext context) => MonthlyTodoBloc(context.read<HiveRepository>()),
                        )
                      ],
                      child: MonthlyPage(pc: widget.monthlyPc),
                    ),
                    MultiBlocProvider(
                        providers: [
                          BlocProvider<FutureTodoBloc>(
                            create: (BuildContext context) => FutureTodoBloc(context.read<HiveRepository>()),
                          ),
                          BlocProvider<MonthlyTodoBloc>(
                            create: (BuildContext context) => MonthlyTodoBloc(context.read<HiveRepository>()),
                          ),
                          BlocProvider<TodoBloc>(
                              create: (BuildContext context) => TodoBloc(context.read<HiveRepository>())),
                        ],
                        child: UnorderedPage(
                          pageController: controller,
                        )),
                  ],
                ),
              ),
              !finishedAnimating
                  ? AnimatedOpacity(
                      onEnd: () {
                        setState(() {
                          finishedAnimating = true;
                        });
                      },
                      opacity: _visible,
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        color: Centre.bgColor,
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                                child: Text(
                              '// TODO:',
                              style: TextStyle(
                                fontSize: 32.0,
                                fontFamily: 'Droid Sans',
                                color: Centre.primaryColor,
                              ),
                            )),
                            SizedBox(
                              height: Centre.safeBlockVertical * 5.5,
                            )
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
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
