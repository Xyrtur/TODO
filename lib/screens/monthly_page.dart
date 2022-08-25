import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:swipe/swipe.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/monthly_todo_bloc.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:todo/widgets/month_calen.dart';
import 'package:todo/widgets/dialogs/month_year_picker.dart';
import 'package:todo/widgets/panels/monthly_panel.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/centre.dart';

class MonthlyPage extends StatelessWidget {
  MonthlyPage({super.key, required this.controller});
  final PanelController pc = PanelController();
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    Centre().init(context);
    return SafeArea(
        child: Scaffold(
      backgroundColor: Centre.bgColor,
      body: BlocListener<MonthlyTodoBloc, MonthlyTodoState>(
        listener: (context, state) {
          if (state.changedDailyList) context.read<DailyMonthlyListCubit>().update();
        },
        child: SlidingUpPanel(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          color: Centre.bgColor,
          backdropColor: Centre.colors[9],
          backdropOpacity: 0.3,
          backdropEnabled: true,
          minHeight: 0,
          controller: pc,
          maxHeight: Centre.safeBlockVertical * 54,
          panel: MonthlyPanel(),
          body: Swipe(
              onSwipeUp: () {
                if (pc.isPanelClosed) {
                  pc.open();
                }
              },
              onSwipeDown: () {
                if (pc.isPanelOpen) {
                  pc.close();
                }
              },
              onSwipeRight: () {
                controller.previousPage(duration: Duration(milliseconds: 300), curve: Curves.decelerate);
              },
              verticalMaxWidthThreshold: 300,
              verticalMinDisplacement: 10,
              verticalMinVelocity: 50,
              horizontalMaxHeightThreshold: 100,
              horizontalMinDisplacement: 20,
              horizontalMinVelocity: 50,
              child: Scaffold(
                floatingActionButton: Padding(
                  padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 3, right: Centre.safeBlockHorizontal),
                  child: FloatingActionButton(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (BuildContext context) => MultiBlocProvider(providers: [
                              BlocProvider<TimeRangeCubit>(
                                create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                              ),
                              BlocProvider<ColorCubit>(
                                create: (_) => ColorCubit(null),
                              ),
                              BlocProvider<CalendarTypeCubit>(
                                create: (_) => CalendarTypeCubit(null),
                              ),
                              BlocProvider<DialogDatesCubit>(create: (_) => DialogDatesCubit(null)),
                              BlocProvider(create: (_) => CheckboxCubit())
                            ], child: AddEventDialog.monthly(monthOrDayDate: context.read<MonthDateCubit>().state))),
                    backgroundColor: Centre.colors[4],
                    child: Icon(Icons.add),
                  ),
                ),
                backgroundColor: Centre.bgColor,
                body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  GestureDetector(
                    onTap: () async {
                      await showAlignedDialog(
                          followerAnchor: Alignment.topLeft,
                          targetAnchor: Alignment.topLeft,
                          offset: Offset(Centre.safeBlockHorizontal * 5, Centre.safeBlockVertical * 8),
                          avoidOverflow: true,
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider(
                                create: (_) => YearTrackingCubit(context.read<MonthDateCubit>().state.year),
                                child: MonthYearPicker());
                          });
                    },
                    child: Container(
                      color: Colors.transparent,
                      height: Centre.safeBlockVertical * 5,
                      child: BlocBuilder<MonthDateCubit, DateTime>(
                        builder: (context, state) => Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  left: Centre.safeBlockHorizontal * 9,
                                  right: Centre.safeBlockHorizontal * 2,
                                  top: Centre.safeBlockVertical),
                              child: Text(DateFormat("MMM").format(state), style: Centre.todoSemiTitle),
                            ),
                            Text(DateFormat("y").format(state), style: Centre.smallerDialogText),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 14,
                    child: MonthCalendar(),
                  )
                ]),
              )),
        ),
      ),
    ));
  }
}
