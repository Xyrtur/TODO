import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/hive_repository.dart';
import 'package:todo/widgets/barrels/monthly_widgets_barrel.dart';
import 'package:todo/utils/centre.dart';

class MonthlyPage extends StatefulWidget {
  const MonthlyPage({super.key});

  @override
  State<MonthlyPage> createState() => MonthlyPageState();
}

class MonthlyPageState extends State<MonthlyPage> with WidgetsBindingObserver {
  late final PageController calendarController;
  @override
  void initState() {
    super.initState();
    calendarController = PageController(
        initialPage: (context.read<MonthDateCubit>().state.year - 2020) * 12 +
            context.read<MonthDateCubit>().state.month -
            1); //Only let events fro
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    calendarController.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour,
              DateTime.now().minute)
          .isAfter(context.read<DateCubit>().state.add(const Duration(hours: 25)))) {
        context.read<DateCubit>().setToCurrentDayOnResume();
        context.read<TodoBloc>().add(TodoDateChange(
            date: DateTime.utc(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day -
                    (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0
                        ? 1
                        : 0))));
        context.read<DailyMonthlyListCubit>().update();
        context.read<UnfinishedListBloc>().add(const UnfinishedListResume());
      }

      if (!DateTime.utc(DateTime.now().year, DateTime.now().month)
          .isAtSameMomentAs(context.read<MonthDateCubit>().state)) {
        context.read<MonthDateCubit>().update(DateTime.utc(DateTime.now().year, DateTime.now().month));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    Widget fab = Padding(
      padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 3, right: Centre.safeBlockHorizontal),
      child: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: MultiBlocProvider(providers: [
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
                      BlocProvider(create: (_) => CheckboxCubit(false)),
                      BlocProvider.value(value: context.read<MonthlyTodoBloc>()),
                      BlocProvider.value(value: context.read<DateCubit>()),
                    ], child: AddEventDialog.monthly(monthOrDayDate: context.read<MonthDateCubit>().state))));
          },
        ),
        backgroundColor: Centre.primaryColor,
        child: Icon(
          Icons.add_rounded,
          color: Centre.bgColor,
          size: 40,
        ),
      ),
    );

    Widget yearMonthDate = GestureDetector(
      onTap: () {
        showAlignedDialog(
            followerAnchor: Alignment.topLeft,
            targetAnchor: Alignment.topLeft,
            offset: Offset(Centre.safeBlockHorizontal * 5, Centre.safeBlockVertical * 8),
            avoidOverflow: true,
            context: context,
            builder: (BuildContext ycontext) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => YearTrackingCubit(context.read<MonthDateCubit>().state.year),
                  ),
                  BlocProvider.value(value: context.read<MonthDateCubit>())
                ],
                child: const MonthYearPicker(),
              );
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
    );

    return SafeArea(
        child: Scaffold(
      backgroundColor: Centre.darkerBgColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<MonthDateCubit, DateTime>(listener: ((context, state) {
            calendarController.jumpToPage((state.year - 2020) * 12 + state.month - 1);
            // context
            //     .read<MonthlyTodoBloc>()
            //     .add(MonthlyTodoDateChange(date: state));
          })),
          BlocListener<MonthlyTodoBloc, MonthlyTodoState>(listener: (context, state) {
            if (state.changedDailyList) {
              context.read<DailyMonthlyListCubit>().update();
            }
          }),
          BlocListener<ImportExportBloc, ImportExportState>(
            listener: (context, state) {
              if (state is ImportFinished) {
                context
                    .read<MonthlyTodoBloc>()
                    .add(MonthlyTodoDateChange(date: context.read<MonthDateCubit>().state));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Import Success!',
                    style: Centre.dialogText,
                  ),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
          )
        ],
        child:

            // SlidingUpPanel(
            //   borderRadius: const BorderRadius.only(
            //       topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            //   color: Centre.bgColor,
            //   backdropColor: Centre.colors[9],
            //   backdropOpacity: 0.3,
            //   backdropEnabled: true,
            //   minHeight: 0,
            //   controller: widget.pc,
            //   maxHeight: Centre.safeBlockVertical * 54,
            //   panel: const MonthlyPanel(),
            //   body:

            Scaffold(
          floatingActionButton: fab,
          backgroundColor: Centre.bgColor,
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            yearMonthDate,
            Expanded(
                flex: 14,
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: calendarController,
                  onPageChanged: (value) {
                    context
                        .read<MonthDateCubit>()
                        .update(DateTime.utc(2020 + (value / 12).floor(), value % 12 + 1));
                  },
                  itemBuilder: (context, index) {
                    context
                        .read<HiveRepository>()
                        .getMonthlyEvents(date: DateTime.utc(2020 + (index / 12).floor(), index % 12 + 1));

                    // context.read<MonthlyTodoBloc>().add(MonthlyTodoDateChange(
                    //     date: DateTime.utc(
                    //         2020 + (index / 12).floor(), index % 12 + 1)));
                    return MonthCalendar(
                      date: DateTime.utc(2020 + (index / 12).floor(), index % 12 + 1),
                      monthList: context.read<HiveRepository>().thisMonthEventsMaps,
                    );
                  },
                ))
          ]),
        ),
        // ),
      ),
    ));
  }
}
