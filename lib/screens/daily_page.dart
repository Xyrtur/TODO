import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:todo/utils/centre.dart';
import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/hive_repository.dart';
import 'package:todo/widgets/barrels/daily_widgets_barrel.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key, required this.pc});
  final PanelController pc;

  @override
  State<DailyPage> createState() => DailyPageState();
}

class DailyPageState extends State<DailyPage> with WidgetsBindingObserver {
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
      context.read<DateCubit>().setToCurrentDayOnResume();
      context.read<TodoBloc>().add(TodoDateChange(
          date: DateTime.utc(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day -
                  (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59 ? 1 : 0))));
      context.read<HiveRepository>().cacheInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    showDailyDialog() {
      showDialog(
          context: context,
          builder: (BuildContext notUsedContext) => Scaffold(
                backgroundColor: Colors.transparent,
                body: MultiBlocProvider(
                    providers: [
                      BlocProvider<TimeRangeCubit>(
                        create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                      ),
                      BlocProvider<ColorCubit>(
                        create: (_) => ColorCubit(null),
                      ),
                      BlocProvider.value(value: context.read<DateCubit>()),
                      BlocProvider.value(value: context.read<TodoBloc>()),
                      BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                    ],
                    child: AddEventDialog.daily(
                      addingFutureTodo: false,
                    )),
              ));
    }

    Widget importExportRow = Row(children: [
      BlocListener<ImportExportBloc, ImportExportState>(
        listener: (context, state) {
          if (state is ImportFinished) {
            context.read<TodoBloc>().add(TodoDateChange(date: context.read<DateCubit>().state));
            context.read<UnfinishedListBloc>().add(const UnfinishedListUpdate());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Centre.dialogBgColor,
              content: Text(
                'Import Success!',
                style: Centre.dialogText,
              ),
              duration: const Duration(seconds: 2),
            ));
          } else if (state is ExportFinished) {
            if (state.path != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Centre.dialogBgColor,
                content: Text(
                  "Export Success! Saved to ${state.path}",
                  style: Centre.dialogText,
                ),
                duration: const Duration(seconds: 5),
              ));
            }
          }
        },
        child: GestureDetector(
          onTap: () async {
            if (Theme.of(context).platform == TargetPlatform.iOS) {
              context.read<ImportExportBloc>().add(const ImportClicked(false));
            } else if (Theme.of(context).platform == TargetPlatform.android) {
              context.read<ImportExportBloc>().add(const ImportClicked(true));
            }
          },
          child: svgButton(
            name: "import",
            color: Centre.yellow,
            height: 5,
            width: 5,
            padding: EdgeInsets.all(Centre.safeBlockHorizontal),
          ),
        ),
      ),
      GestureDetector(
        onTap: () {
          if (Theme.of(context).platform == TargetPlatform.iOS) {
            context.read<ImportExportBloc>().add(const ExportClicked(false));
          } else if (Theme.of(context).platform == TargetPlatform.android) {
            context.read<ImportExportBloc>().add(const ExportClicked(true));
          }
        },
        child: svgButton(
          name: "export",
          color: Centre.colors[4],
          height: 5,
          width: 5,
          padding: EdgeInsets.all(Centre.safeBlockHorizontal),
        ),
      ),
      IconButton(
          iconSize: 25,
          onPressed: () {
            showLicensePage(context: context, applicationName: "//TODO:");
          },
          icon: Icon(
            Icons.info_outline,
            color: Centre.primaryColor,
          )),
    ]);

    Widget addingEditingRow = Row(children: [
      BlocBuilder<ToggleChecklistEditingCubit, bool>(builder: (context, state) {
        return Container(
          margin: EdgeInsets.only(right: Centre.safeBlockHorizontal * 2),
          height: Centre.safeBlockVertical * 4,
          child: ToggleButtons(
            onPressed: (int index) {
              context.read<ToggleChecklistEditingCubit>().toggle();
            },
            isSelected: [!state, state], // editing, !editing
            selectedColor: Centre.bgColor,
            color: Centre.primaryColor,
            fillColor: Centre.primaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            children: <Widget>[
              Icon(
                Icons.checklist_rounded,
                size: Centre.safeBlockVertical * 3,
              ),
              Icon(
                Icons.edit,
                color: state ? Centre.bgColor : Centre.primaryColor,
                size: 25,
              ),
            ],
          ),
        );
      }),
      GestureDetector(
        onTap: () => showDailyDialog(),
        child: Padding(
          padding: EdgeInsets.only(left: Centre.safeBlockHorizontal, right: Centre.safeBlockHorizontal * 2),
          child: Icon(
            Icons.add_circle_rounded,
            color: Centre.primaryColor,
            size: 45,
          ),
        ),
      ),
    ]);

    Widget dailyDateRow = BlocBuilder<DateCubit, DateTime>(builder: (context, state) {
      return Row(
        children: [
          (state.isSameDate(
                  other: DateTime.utc(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day -
                          (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59
                              ? 1
                              : 0)),
                  daily: false))
              ? SizedBox(
                  width: Centre.safeBlockHorizontal * 11.5,
                )
              : IconButton(
                  onPressed: () {
                    context.read<DateCubit>().prevDay();
                    context.read<TodoBloc>().add(TodoDateChange(date: state.subtract(const Duration(days: 1))));
                  },
                  icon: Icon(
                    Icons.chevron_left_sharp,
                    color: Centre.primaryColor,
                    size: 40,
                  )),
          Column(
            children: [
              Text(DateFormat('E').format(state), style: Centre.todoSemiTitle),
              Text(DateFormat('d, MMM.').format(state), style: Centre.smallerDialogText),
            ],
          ),
          (state.isSameDate(
                  other: DateTime.utc(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day -
                              (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59
                                  ? 1
                                  : 0))
                      .add(const Duration(days: 4)),
                  daily: false))
              ? const SizedBox()
              : IconButton(
                  onPressed: () {
                    context.read<DateCubit>().nextDay();
                    context.read<TodoBloc>().add(TodoDateChange(date: state.add(const Duration(days: 1))));
                  },
                  icon: Icon(
                    Icons.chevron_right_sharp,
                    color: Centre.primaryColor,
                    size: 40,
                  ))
        ],
      );
    });

    Widget dailyPageHeader = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      BlocListener<TodoBloc, TodoState>(
        listener: (context, state) {
          if (state.dateChanged) context.read<DailyMonthlyListCubit>().update();
        },
        child: dailyDateRow,
      ),
      Column(
        children: [
          importExportRow,
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

    Widget dottedBorders = Row(
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Centre.bgColor,
        body: SlidingUpPanel(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          color: Centre.bgColor,
          backdropColor: Centre.colors[9],
          backdropOpacity: 0.3,
          backdropEnabled: true,
          minHeight: 0,
          maxHeight: Centre.safeBlockVertical * 54,
          controller: widget.pc,
          panel: DailyPanel(
              // thisPc: widget.pc
              ),
          body: Padding(
            padding: EdgeInsets.all(Centre.safeBlockVertical),
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
                        BlocProvider(create: (_) => DraggingSplitBlockCubit(), child: const TodoTable()),
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
