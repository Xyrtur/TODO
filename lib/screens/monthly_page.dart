import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/import_export_bloc.dart';
import 'package:todo/blocs/monthly_todo_bloc.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:todo/widgets/month_calen.dart';
import 'package:todo/widgets/dialogs/month_year_picker.dart';
import 'package:todo/widgets/panels/monthly_panel.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/centre.dart';

class MonthlyPage extends StatelessWidget {
  const MonthlyPage({super.key, required this.controller, required this.pc});
  final PanelController pc;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    Centre().init(context);
    return SafeArea(
        child: Scaffold(
      backgroundColor: Centre.darkerBgColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<MonthlyTodoBloc, MonthlyTodoState>(listener: (context, state) {
            if (state.changedDailyList) context.read<DailyMonthlyListCubit>().update();
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
        child: SlidingUpPanel(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          color: Centre.bgColor,
          backdropColor: Centre.colors[9],
          backdropOpacity: 0.3,
          backdropEnabled: true,
          minHeight: 0,
          controller: pc,
          maxHeight: Centre.safeBlockVertical * 54,
          panel: const MonthlyPanel(),
          body: Scaffold(
            floatingActionButton: Padding(
              padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 3, right: Centre.safeBlockHorizontal),
              child: FloatingActionButton(
                onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext tcontext) => Scaffold(
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
                            BlocProvider.value(value: context.read<MonthDateCubit>())
                          ], child: AddEventDialog.monthly(monthOrDayDate: context.read<MonthDateCubit>().state)),
                        )),
                backgroundColor: Centre.primaryColor,
                child: Icon(
                  Icons.add_rounded,
                  color: Centre.bgColor,
                  size: 40,
                ),
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
                      builder: (BuildContext ycontext) {
                        return MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (_) => YearTrackingCubit(context.read<MonthDateCubit>().state.year),
                            ),
                            BlocProvider.value(value: context.read<MonthDateCubit>())
                          ],
                          child: MonthYearPicker(),
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
              ),
              Expanded(
                flex: 14,
                child: MonthCalendar(),
              )
            ]),
          ),
        ),
      ),
    ));
  }
}
