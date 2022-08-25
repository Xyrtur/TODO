import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:swipe/swipe.dart';
import 'package:r_dotted_line_border/r_dotted_line_border.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/daily_todo_bloc.dart';
import 'package:todo/blocs/unfinished_bloc.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/utils/hive_repository.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:todo/widgets/panels/daily_panel.dart';
import 'package:todo/widgets/todo_table.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:todo/widgets/svg_button.dart';
import 'package:intl/intl.dart';
import '../utils/datetime_ext.dart';

class DailyPage extends StatelessWidget {
  DailyPage({super.key, required this.controller});
  final PanelController pc = PanelController();
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Centre.bgColor,
        body: SlidingUpPanel(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          color: Centre.bgColor,
          backdropColor: Centre.colors[9],
          backdropOpacity: 0.3,
          backdropEnabled: true,
          minHeight: 0,
          maxHeight: Centre.safeBlockVertical * 54,
          controller: pc,
          panel: BlocProvider(
            create: (BuildContext context) => UnfinishedListBloc(context.read<HiveRepository>()),
            child: DailyPanel(),
          ),
          body: Padding(
            padding: EdgeInsets.all(Centre.safeBlockVertical),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(
                    children: [
                      (context.read<DateCubit>().state.isSameDate(other: DateTime.now(), daily: true))
                          ? SizedBox(
                              width: Centre.safeBlockHorizontal * 11.5,
                            )
                          : IconButton(
                              onPressed: () {
                                context.read<DateCubit>().prevDay();
                                context.read<TodoBloc>().add(TodoDateChange(date: context.read<DateCubit>().state));
                                context.read<DailyMonthlyListCubit>().update();
                              },
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: Centre.colors[9],
                                size: 35,
                              )),
                      BlocBuilder<DateCubit, DateTime>(builder: (context, state) {
                        return Column(
                          children: [
                            Text(DateFormat('E').format(state), style: Centre.todoSemiTitle),
                            Text(DateFormat('d, MMM.').format(state), style: Centre.smallerDialogText),
                          ],
                        );
                      }),
                      (context
                              .read<DateCubit>()
                              .state
                              .isSameDate(other: DateTime.now().add(const Duration(days: 5)), daily: true))
                          ? SizedBox(
                              width: Centre.safeBlockHorizontal * 11.5,
                            )
                          : IconButton(
                              onPressed: () {
                                context.read<DateCubit>().nextDay();
                                context.read<TodoBloc>().add(TodoDateChange(date: context.read<DateCubit>().state));
                                context.read<DailyMonthlyListCubit>().update();
                              },
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: Centre.colors[9],
                                size: 35,
                              ))
                    ],
                  ),
                  Column(
                    children: [
                      Row(children: [
                        svgButton(
                          name: "import",
                          color: Centre.yellow,
                          height: 5,
                          width: 5,
                          padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                        ),
                        svgButton(
                          name: "export",
                          color: Centre.colors[4],
                          height: 5,
                          width: 5,
                          padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                        ),
                      ]),
                      Row(children: [
                        BlocBuilder<ToggleEditingCubit, bool>(builder: (context, state) {
                          return Container(
                            margin: EdgeInsets.only(right: Centre.safeBlockHorizontal * 2),
                            height: Centre.safeBlockVertical * 4,
                            child: ToggleButtons(
                              onPressed: (int index) {
                                context.read<ToggleEditingCubit>().toggle();
                              },
                              isSelected: [state, !state], // editing, !editing
                              selectedColor: Centre.bgColor,
                              fillColor: Centre.colors[2],
                              borderRadius: const BorderRadius.all(Radius.circular(40)),
                              children: <Widget>[
                                Icon(
                                  Icons.checklist_rounded,
                                  color: Centre.bgColor,
                                  size: Centre.safeBlockVertical * 3,
                                ),
                                SvgPicture.asset(
                                  "assets/icons/edit.svg",
                                  color: Centre.colors[2],
                                  height: Centre.safeBlockVertical * 3.5,
                                  width: Centre.safeBlockVertical * 4,
                                ),
                              ],
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) => MultiBlocProvider(
                                      providers: [
                                        BlocProvider<TimeRangeCubit>(
                                          create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                                        ),
                                        BlocProvider<ColorCubit>(
                                          create: (_) => ColorCubit(null),
                                        ),
                                      ],
                                      child: AddEventDialog.daily(
                                        monthOrDayDate: context.read<DateCubit>().state,
                                        dailyTableMap: context.read<TodoBloc>().state.dailyTableMap,
                                        orderedDailyKeyList: context.read<TodoBloc>().state.orderedDailyKeyList,
                                      ))),
                          child: svgButton(
                            name: "add",
                            color: Centre.colors[3],
                            height: 5,
                            width: 6,
                            margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ]),
                Expanded(
                    flex: 14,
                    child: Swipe(
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
                      onSwipeLeft: () {
                        controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.decelerate);
                      },
                      verticalMaxWidthThreshold: 300,
                      verticalMinDisplacement: 10,
                      verticalMinVelocity: 50,
                      horizontalMaxHeightThreshold: 300,
                      horizontalMinDisplacement: 10,
                      horizontalMinVelocity: 50,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
                        child: Stack(
                          children: [
                            dayLayout(),
                            TodoTable(currentDate: context.read<DateCubit>().state),
                            centerTicks()
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget centerTicks() {
  return Center(
    child: Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: Centre.scheduleBlock * 0.167),
          decoration: BoxDecoration(
              color: Colors.transparent, border: Border.symmetric(horizontal: BorderSide(color: Centre.colors[4]))),
          height: Centre.scheduleBlock * 0.167,
          width: Centre.safeBlockHorizontal * 2.5,
        ),
        for (int i = 0; i < 17; i++)
          Container(
            margin: EdgeInsets.only(top: Centre.scheduleBlock * 0.333),
            decoration: BoxDecoration(
                color: Colors.transparent, border: Border.symmetric(horizontal: BorderSide(color: Centre.colors[4]))),
            height: Centre.scheduleBlock * 0.167,
            width: Centre.safeBlockHorizontal * 2.5,
          ),
      ],
    ),
  );
}

Widget dayLayout() {
  return Row(
    children: [
      Expanded(
          child: Container(
              padding: EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 7; i <= 15; i++)
                    Container(
                      height: Centre.scheduleBlock,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: RDottedLineBorder(
                          top: const BorderSide(
                            width: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.toString(),
                            style: Centre.todoText,
                          ),
                          SizedBox(height: Centre.safeBlockVertical * 2.6),
                          DottedLine(
                            dashColor: Centre.lighterDialogColor,
                          )
                        ],
                      ),
                    )
                ],
              ))),
      Expanded(
          child: Container(
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 16; i <= 24; i++)
                    Container(
                      height: Centre.scheduleBlock,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: RDottedLineBorder(
                          top: BorderSide(
                            width: 1,
                            color: Centre.textColor,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (i % 24).toString(),
                            style: Centre.todoText,
                          ),
                          SizedBox(height: Centre.safeBlockVertical * 2.6),
                          DottedLine(
                            dashColor: Centre.lighterDialogColor,
                          )
                        ],
                      ),
                    )
                ],
              )))
    ],
  );
}
