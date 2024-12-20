import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:todo/utils/centre.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/widgets/barrels/daily_widgets_barrel.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key, required this.pc});
  final PanelController pc;

  @override
  State<DailyPage> createState() => DailyPageState();
}

class DailyPageState extends State<DailyPage> with WidgetsBindingObserver {
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      DateTime onDate = context.read<DateCubit>().state;
      if (DateTime.now().isAfter(context.read<FirstDailyDateBtnCubit>().state.add(const Duration(hours: 25)))) {
        context.read<FirstDailyDateBtnCubit>().update(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day -
                (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0)));
        if (DateTime.now().isAfter(onDate)) {
          context.read<DateCubit>().setToCurrentDayOnResume();
          context.read<TodoBloc>().add(TodoDateChange(
              date: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0))));
        } else {
          // Make sure daily date buttons update
          context.read<DateCubit>().changeDay(DateTime(onDate.year, onDate.month, onDate.day));
        }

        context.read<UnfinishedListBloc>().add(const UnfinishedListResume());
        context.read<DailyMonthlyListCubit>().update();
      }
    }
  }

  Widget changeDailyDateBtns() {
    return BlocBuilder<DateCubit, DateTime>(builder: (context, state) {
      DateTime todayDate = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day -
              (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0));
      return Padding(
        padding: EdgeInsets.only(top: Centre.safeBlockVertical, bottom: Centre.safeBlockVertical),
        child: Row(
          children: [
            for (int day = 0; day < 5; day++)
              GestureDetector(
                onTap: () {
                  context.read<DateCubit>().changeDay(todayDate.addDurationWithoutDST(Duration(days: day)));
                  context
                      .read<TodoBloc>()
                      .add(TodoDateChange(date: todayDate.addDurationWithoutDST(Duration(days: day))));
                },
                child: Container(
                    height: Centre.safeBlockHorizontal * 10,
                    width: Centre.safeBlockHorizontal * 10,
                    margin: EdgeInsets.only(left: Centre.safeBlockHorizontal, right: Centre.safeBlockHorizontal * 2),
                    padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: todayDate.addDurationWithoutDST(Duration(days: day)).isAtSameMomentAs(state)
                          ? Border.all(color: Centre.primaryColor)
                          : null,
                      color: Centre.lighterBgColor,
                      boxShadow: [
                        BoxShadow(
                          color: Centre.darkerBgColor,
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('E').format(todayDate.addDurationWithoutDST(Duration(days: day)))[0],
                        style: Centre.titleDialogText.copyWith(color: Centre.primaryColor),
                      ),
                    )),
              )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    showDailyDialog() {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return GestureDetector(
              onTap: () {},
              child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: MultiBlocProvider(providers: [
                    BlocProvider<TimeRangeCubit>(
                      create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                    ),
                    BlocProvider<DailyTimeBtnsCubit>(
                      create: (_) => DailyTimeBtnsCubit(),
                    ),
                    BlocProvider<ColorCubit>(
                      create: (_) => ColorCubit(null),
                    ),
                    BlocProvider.value(value: context.read<DateCubit>()),
                    BlocProvider.value(value: context.read<TodoBloc>()),
                    BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                  ], child: AddEventDialog.daily())));
        },
      );
    }

    Widget addingEditingRow = Row(children: [
      BlocBuilder<ToggleChecklistEditingCubit, bool>(builder: (context, state) {
        return Container(
          margin: EdgeInsets.only(right: Centre.safeBlockHorizontal * 4),
          height: Centre.safeBlockVertical * 4.3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: Centre.lighterBgColor,
              boxShadow: [
                BoxShadow(
                  color: Centre.darkerBgColor,
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ToggleButtons(
              onPressed: (int index) {
                context.read<ToggleChecklistEditingCubit>().toggle();
              },
              isSelected: [!state, state], // editing, !editing
              selectedColor: Centre.lighterBgColor,
              color: Centre.primaryColor,
              fillColor: Centre.primaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(40)),
              borderWidth: Centre.safeBlockHorizontal,
              borderColor: Centre.lighterBgColor,
              selectedBorderColor: Centre.lighterBgColor,
              children: <Widget>[
                Icon(
                  Icons.checklist_rounded,
                  size: Centre.safeBlockVertical * 3,
                ),
                Icon(
                  Icons.edit,
                  size: Centre.safeBlockVertical * 3,
                ),
              ],
            ),
          ),
        );
      }),
      GestureDetector(
        onTap: () => showDailyDialog(),
        child: Container(
          margin: EdgeInsets.only(left: Centre.safeBlockHorizontal, right: Centre.safeBlockHorizontal * 4),
          padding: EdgeInsets.all(Centre.safeBlockHorizontal),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Centre.lighterBgColor,
            boxShadow: [
              BoxShadow(
                color: Centre.darkerBgColor,
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: Centre.primaryColor,
            size: Centre.safeBlockHorizontal * 8,
          ),
        ),
      ),
    ]);

    Widget dailyDateColumn = BlocBuilder<DateCubit, DateTime>(builder: (unUsedContext, state) {
      return Column(
        children: [
          SizedBox(
            child: Align(
              alignment: Alignment.topLeft,

              child: GestureDetector(
                onTap: () {
                  showAlignedDialog(
                      barrierColor: Centre.colors[3].withOpacity(0.2),
                      followerAnchor: Alignment.topLeft,
                      targetAnchor: Alignment.topLeft,
                      offset: Offset(Centre.safeBlockHorizontal * 7, Centre.safeBlockVertical * 9),
                      avoidOverflow: true,
                      context: context,
                      builder: (BuildContext unUsedContext) {
                        return MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: context.read<ImportExportBloc>()),
                            BlocProvider.value(value: context.read<DateCubit>()),
                            BlocProvider.value(value: context.read<TodoBloc>()),
                            BlocProvider.value(value: context.read<UnfinishedListBloc>())
                          ],
                          child: const SettingsDialog(),
                        );
                      });
                },
                child: SizedBox(
                  height: Centre.safeBlockHorizontal * 9,
                  width: Centre.safeBlockHorizontal * 9,
                  child: Icon(
                    Icons.settings_rounded,
                    color: Centre.secondaryColor,
                    size: Centre.safeBlockHorizontal * 7,
                  ),
                ),
              ),
              // )
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 2),
            child: Text(DateFormat('E').format(state), style: Centre.todoSemiTitle),
          ),
          Padding(
            padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 2),
            child: Text(DateFormat('d, MMM.').format(state), style: Centre.smallerDialogText),
          ),
        ],
      );
    });

    Widget dailyPageHeader = Row(children: [
      Expanded(
        child: BlocListener<TodoBloc, TodoState>(
          listener: (context, state) {
            if (state.dateChanged) {
              context.read<DailyMonthlyListCubit>().update();
            }
          },
          child: dailyDateColumn,
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          changeDailyDateBtns(),
          // importExportRow,
          addingEditingRow,
        ],
      ),
    ]);

    Widget centerTicks = Center(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: Centre.scheduleBlock * 0.167),
            decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.symmetric(horizontal: BorderSide(color: Centre.primaryColor))),
            height: Centre.scheduleBlock * 0.167,
            width: Centre.safeBlockHorizontal * 2.5,
          ),
          for (int i = 0; i < 17; i++)
            Container(
              margin: EdgeInsets.only(top: Centre.scheduleBlock * 0.333),
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.symmetric(horizontal: BorderSide(color: Centre.primaryColor))),
              height: Centre.scheduleBlock * 0.167,
              width: Centre.safeBlockHorizontal * 2.5,
            ),
        ],
      ),
    );
    GlobalKey key = GlobalKey();
    Widget dottedBorders = Row(
      key: key,
      children: [
        Expanded(
            child: Container(
                padding: const EdgeInsets.only(right: 8),
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
                        child: Stack(
                          children: [
                            Text(
                              i.toString(),
                              style: Centre.todoText,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: Centre.scheduleBlock / 2 -
                                        0.5), // Offset here helps alignment with schedule blocks
                                DottedLine(
                                  dashColor: Centre.lighterDialogColor,
                                )
                              ],
                            )
                          ],
                        ),
                      )
                  ],
                ))),
        Expanded(
            child: Container(
                padding: const EdgeInsets.only(left: 8),
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
                        child: Stack(
                          children: [
                            Text(
                              (i % 24).toString(),
                              style: Centre.todoText,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: Centre.scheduleBlock / 2 -
                                        0.5), // Offset here helps alignment with schedule blocks
                                DottedLine(
                                  dashColor: Centre.lighterDialogColor,
                                )
                              ],
                            )
                          ],
                        ),
                      )
                  ],
                )))
      ],
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Centre.bgColor,
        body: SlidingUpPanel(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          color: Centre.bgColor,
          backdropColor: Centre.colors[1],
          backdropOpacity: 0.3,
          backdropEnabled: true,
          minHeight: 0,
          maxHeight: Centre.safeBlockVertical * 54,
          controller: widget.pc,
          panel: DailyPanel(),
          body: Padding(
            padding: EdgeInsets.fromLTRB(
                Centre.safeBlockHorizontal, 0, Centre.safeBlockHorizontal, Centre.safeBlockVertical),
            child: Column(
              children: [
                dailyPageHeader,
                Expanded(
                  flex: 14,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
                    child: Stack(
                      children: [
                        dottedBorders,
                        BlocProvider(
                            create: (_) => DraggingSplitBlockCubit(),
                            child: TodoTable(
                              dottedOutlineKey: key,
                            )),
                        centerTicks
                      ],
                    ),
                  ),
                  // )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
