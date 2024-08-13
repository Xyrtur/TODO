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
        height: Centre.safeBlockVertical * 5.5,
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
                context.read<MonthlyTodoBloc>().add(MonthlyTodoDateChange(date: context.read<MonthDateCubit>().state));
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
        child: Scaffold(
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
                    context.read<MonthDateCubit>().update(DateTime(2020 + (value / 12).floor(), value % 12 + 1));
                  },
                  itemBuilder: (context, index) {
                    context
                        .read<HiveRepository>()
                        .getMonthlyEvents(date: DateTime(2020 + (index / 12).floor(), index % 12 + 1));

                    return MonthCalendar(
                      date: DateTime(2020 + (index / 12).floor(), index % 12 + 1),
                      monthList: context.read<HiveRepository>().thisMonthEventsMaps,
                    );
                  },
                ))
          ]),
        ),
      ),
    ));
  }
}
