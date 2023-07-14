import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:core';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/widgets/event_text_field.dart';
import 'package:todo/widgets/svg_button.dart';
import 'package:todo/widgets/dialogs/delete_confirmation_dialog.dart';

import 'custom_time_picker.dart' as custom_time_picker;

class AddEventDialog extends StatelessWidget {
  // Whether adding an event to the daily page or the monthly page
  final bool daily;

  // If adding to daily page, this date represents the date currently shown
  // If adding to monthly page, this date represents the currently chosen first day of month
  late DateTime monthOrDayDate;

  // If editing an event, this will be set
  final EventData? event;

  final bool fromDailyMonthlyList;
  final bool fromUnfinishedList;

  // Value notifiers to send events to their respective blocs when needed since shouldn't call context in async gaps
  final ValueNotifier<List<DateTime?>?> dateResults =
      ValueNotifier<List<DateTime?>?>(null);
  final ValueNotifier<TimeRangeState> timeRangeChosen =
      ValueNotifier<TimeRangeState>(TimeRangeState(null, null));
  final ValueNotifier<bool?> deleting = ValueNotifier<bool?>(false);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController controller;
  bool editedTimes = false;

  AddEventDialog.daily(
      {super.key,
      this.daily = true,
      this.event,
      this.fromUnfinishedList = false,
      this.fromDailyMonthlyList = false});
  AddEventDialog.monthly(
      {super.key,
      this.daily = false,
      this.event,
      this.fromUnfinishedList = false,
      required this.monthOrDayDate,
      this.fromDailyMonthlyList = false});

  @override
  Widget build(BuildContext context) {
    if (context.read<TimeRangeCubit>().state.endResult != null &&
        !fromDailyMonthlyList &&
        !fromUnfinishedList) {
      editedTimes = true;
    }
    // Only if adding to monthly or from unordered page does the user set dates for the event
    if (!daily) {
      dateResults.addListener(() {
        context.read<DialogDatesCubit>().update(dateResults.value);
      });
    } else {
      // Adding to daily page so set this date to the current date shown on the daily page
      monthOrDayDate = context.read<DateCubit>().state;
    }

    timeRangeChosen.addListener(() {
      context.read<TimeRangeCubit>().update(
          timeRangeChosen.value.startResult, timeRangeChosen.value.endResult);
    });

    deleting.addListener(() {
      if (deleting.value ?? false) Navigator.pop(context);
    });

    controller = TextEditingController(text: event?.text ?? "");

    // Title and cancel/delete button
    Widget dialogHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 4),
          child: Text(
            event == null ? "New Event" : "Edit Event",
            style: Centre.todoSemiTitle,
          ),
        ),
        // Show a trash can or a cancel button depending on whether or not user is editing an event
        event != null && !fromDailyMonthlyList
            ? GestureDetector(
                onTap: () async {
                  deleting.value = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext tcontext) {
                        return MultiBlocProvider(
                          providers: daily
                              ? [
                                  BlocProvider.value(
                                      value: context.read<TodoBloc>())
                                ]
                              : [
                                  BlocProvider.value(
                                      value: context.read<MonthlyTodoBloc>()),
                                  BlocProvider.value(
                                      value: context.read<DateCubit>())
                                ],
                          child: DeleteConfirmationDialog(
                            type: daily
                                ? DeletingFrom.todoTable
                                : DeletingFrom.monthCalen,
                            event: event!,
                            currentMonth: monthOrDayDate,
                          ),
                        );
                      });
                },
                child: Container(
                  height: Centre.safeBlockVertical * 3.5,
                  width: Centre.safeBlockVertical * 3.5,
                  margin:
                      EdgeInsets.only(right: Centre.safeBlockHorizontal * 4),
                  child: Icon(Icons.delete_rounded,
                      color: Color(event!.color),
                      size: Centre.safeBlockHorizontal * 8),
                ),
              )
            : GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin:
                      EdgeInsets.only(right: Centre.safeBlockHorizontal * 2),
                  padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Centre.editButtonColor,
                    boxShadow: [
                      BoxShadow(
                        color: Centre.darkerDialogBgColor,
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Centre.red,
                    size: Centre.safeBlockHorizontal * 6,
                  ),
                )),
      ],
    );

    // Select the colour that the event will be
    Widget colourBtn(int i) {
      return GestureDetector(
        onTap: () {
          context.read<ColorCubit>().update(i);
        },
        child: Container(
          width: Centre.safeBlockHorizontal * 6,
          height: Centre.safeBlockHorizontal * 6,
          decoration: BoxDecoration(
              color: Centre.colors[i],
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: const BorderRadius.all(Radius.circular(40))),
          child: context.read<ColorCubit>().state == i
              ? Icon(
                  Icons.check,
                  size: Centre.safeBlockHorizontal * 5,
                  color: Centre.bgColor,
                )
              : null,
        ),
      );
    }

    Widget firstColorRow = Padding(
      padding: EdgeInsets.symmetric(vertical: Centre.safeBlockVertical * 1),
      child: BlocBuilder<ColorCubit, int>(
        builder: (context, state) => Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [for (int i = 0; i < 5; i++) colourBtn(i)],
        ),
      ),
    );

    Widget secondColourRow = BlocBuilder<ColorCubit, int>(
      builder: (context, state) => Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [for (int i = 5; i < 10; i++) colourBtn(i)],
      ),
    );

    Widget calendarTypeBtn(CalendarType state, CalendarType type, String name) {
      return GestureDetector(
        onTap: () {
          context.read<CalendarTypeCubit>().pressed(type);
          context.read<DialogDatesCubit>().update(null);
        },
        child: svgButton(
            name: name,
            color: (state == type ? Centre.colors[8] : Centre.colors[3]),
            height: 7,
            width: 7,
            padding: EdgeInsets.all(Centre.safeBlockHorizontal),
            borderColor: event == null && state == type
                ? Centre.colors[8]
                : Colors.transparent),
      );
    }

    // Column of three buttons to toggle between the type of event it will be
    Widget calendarTypeToggleBtns = Container(
      margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 3),
      height: Centre.safeBlockVertical * 22,
      width: Centre.safeBlockHorizontal * 15,
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Centre.darkerDialogBgColor,
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
          color: Color.fromARGB(255, 77, 77, 77),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: BlocBuilder<CalendarTypeCubit, CalendarType>(
        builder: (context, state) => Column(
          children: [
            SizedBox(
              height: Centre.safeBlockVertical * 0.25,
            ),
            calendarTypeBtn(state, CalendarType.single, "single_date"),
            calendarTypeBtn(state, CalendarType.ranged, "range_date"),
            calendarTypeBtn(state, CalendarType.multi, "multi_date"),
          ],
        ),
      ),
    );

    // Button to select the dates and the text widgets that show the chosen dates
    List<Widget> calendarPickerRow = [
      !daily
          ? GestureDetector(
              onTap: () async {
                List<DateTime?>? results = await showCalendarDatePicker2Dialog(
                  dialogBackgroundColor: Centre.dialogBgColor,
                  barrierColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(40),
                  context: context,
                  config: CalendarDatePicker2WithActionButtonsConfig(
                    weekdayLabelTextStyle:
                        Centre.todoText.copyWith(color: Centre.yellow),
                    controlsTextStyle: Centre.dialogText,
                    gapBetweenCalendarAndButtons: 0,
                    closeDialogOnCancelTapped: true,
                    cancelButtonTextStyle: Centre.dialogText,
                    okButton: Container(
                      margin: EdgeInsets.only(
                          right: Centre.safeBlockHorizontal * 3),
                      child: Text(
                        "OK",
                        style: Centre.dialogText,
                      ),
                    ),
                    dayTextStyle: Centre.todoText,
                    calendarType: context.read<CalendarTypeCubit>().state ==
                            CalendarType.single
                        ? CalendarDatePicker2Type.single
                        : context.read<CalendarTypeCubit>().state ==
                                CalendarType.ranged
                            ? CalendarDatePicker2Type.range
                            : CalendarDatePicker2Type.multi,
                    firstDate: DateTime.utc(monthOrDayDate.year - 1),
                    lastDate: DateTime.utc(monthOrDayDate.year + 2, 12, 31),
                    currentDate: DateTime.now(),
                    selectedDayHighlightColor: Centre.secondaryColor,
                  ),
                  dialogSize: Size(Centre.safeBlockHorizontal * 85,
                      Centre.safeBlockVertical * 53),
                  value: context.read<DialogDatesCubit>().state ??
                      (monthOrDayDate.year == DateTime.now().year &&
                              monthOrDayDate.month == DateTime.now().month
                          ? [
                              DateTime(DateTime.now().year,
                                  DateTime.now().month, DateTime.now().day)
                            ]
                          : [monthOrDayDate]),
                );
                if (context.read<CalendarTypeCubit>().state ==
                        CalendarType.ranged
                    ? (results != null && results.length == 2)
                    : results != null) {
                  for (int i = 0; i < results.length; i++) {
                    // Convert the local date to UTC but we will still want times at 00 00 00
                    if (!results[i]!.isUtc) {
                      results[i] = results[i]!.toUtc().add(DateTime(
                              results[i]!.year,
                              results[i]!.month,
                              results[i]!.day,
                              7,
                              0)
                          .timeZoneOffset);
                    }
                  }
                  dateResults.value = results;
                }
              },
              child: Builder(
                builder: (context) {
                  CalendarType state = context.watch<CalendarTypeCubit>().state;
                  return svgButton(
                    name: state == CalendarType.single
                        ? "single_date"
                        : state == CalendarType.ranged
                            ? "range_date"
                            : "multi_date",
                    color: Centre.yellow,
                    height: 7,
                    width: 7,
                    margin: EdgeInsets.symmetric(
                        horizontal: Centre.safeBlockHorizontal * 2,
                        vertical: state == CalendarType.ranged
                            ? Centre.safeBlockVertical * 3.5
                            : 0),
                    padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                  );
                },
              ),
            )
          : const SizedBox(),
      !daily
          ? Builder(builder: (context) {
              CalendarType calendarState =
                  context.watch<CalendarTypeCubit>().state;
              final dateResultsState = context.watch<DialogDatesCubit>().state;

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: calendarState != CalendarType.ranged
                      ? [
                          SizedBox(
                              width: Centre.safeBlockHorizontal * 30,
                              child: Text(
                                calendarState == CalendarType.single
                                    ? (dateResultsState?[0] != null
                                        ? DateFormat('MMM d')
                                            .format(dateResultsState![0]!)
                                        : "")
                                    : (dateResultsState?[0] != null
                                        ? [
                                            for (DateTime? i
                                                in dateResultsState!)
                                              DateFormat('MMM d').format(i!)
                                          ].join(', ')
                                        : ""),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: Centre.dialogText,
                              ))
                        ]
                      : [
                          SizedBox(
                              width: Centre.safeBlockHorizontal * 21,
                              child: Text(
                                dateResultsState?[0] != null
                                    ? DateFormat('MMM d')
                                        .format(dateResultsState![0]!)
                                    : "",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: Centre.dialogText,
                              )),
                          SizedBox(
                              width: Centre.safeBlockHorizontal * 21,
                              child: Text(
                                dateResultsState?[1] != null
                                    ? DateFormat('MMM d')
                                        .format(dateResultsState![1]!)
                                    : "",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: Centre.dialogText,
                              )),
                        ]);
            })
          : const SizedBox(),
    ];

    // Button to select the times and the text widgets to show the chosen times
    Widget timePickerRow = Builder(builder: (context) {
      bool checkBoxState = false;
      CalendarType calendarState = CalendarType.single;
      if (!daily) {
        checkBoxState = context.watch<CheckboxCubit>().state;
        calendarState = context.watch<CalendarTypeCubit>().state;
      }
      final TimeRangeState timeRangeState =
          context.watch<TimeRangeCubit>().state;

      return calendarState != CalendarType.ranged
          ? Row(
              children: [
                GestureDetector(
                    onTap: () async {
                      if (!checkBoxState) {
                        TimeRangeState? value = await chooseTimeRange(
                            dailyDate:
                                daily ? context.read<DateCubit>().state : null,
                            context: context,
                            daily: daily,
                            editingEvent: event,
                            prevChosenStart: timeRangeState.startResult,
                            prevChosenEnd: timeRangeState.endResult);
                        if (value.startResult != null &&
                            value.endResult != null) {
                          editedTimes = true;
                          timeRangeChosen.value = value;
                        }
                      }
                    },
                    child: svgButton(
                      name: "range_time",
                      color: !checkBoxState
                          ? Centre.yellow
                          : Centre.lighterDialogColor,
                      height: 7,
                      width: 7,
                      margin: daily
                          ? EdgeInsets.fromLTRB(Centre.safeBlockHorizontal * 5,
                              0, Centre.safeBlockHorizontal, 0)
                          : EdgeInsets.symmetric(
                              horizontal: Centre.safeBlockHorizontal * 2),
                      padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                    )),
                Padding(
                    padding: EdgeInsets.only(
                        bottom: daily ? 0 : Centre.safeBlockVertical * 2.5),
                    child: Column(
                      mainAxisAlignment: daily
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeRangeState.startResult == null
                              ? ""
                              : "${timeRangeState.startResult!.hour.toString().padLeft(2, '0')}${timeRangeState.startResult!.minute.toString().padLeft(2, '0')}",
                          style: daily
                              ? (fromDailyMonthlyList || fromUnfinishedList) &&
                                      !editedTimes
                                  ? Centre.dialogText.copyWith(
                                      color: Centre.lighterDialogColor)
                                  : Centre.dialogText
                              : Centre.dialogText.copyWith(
                                  decoration: checkBoxState
                                      ? TextDecoration.lineThrough
                                      : null),
                        ),
                        Text(
                          timeRangeState.endResult == null
                              ? ""
                              : "${timeRangeState.endResult!.hour.toString().padLeft(2, '0')}${timeRangeState.endResult!.minute.toString().padLeft(2, '0')}",
                          style: daily
                              ? (fromDailyMonthlyList || fromUnfinishedList) &&
                                      !editedTimes
                                  ? Centre.dialogText.copyWith(
                                      color: Centre.lighterDialogColor)
                                  : Centre.dialogText
                              : Centre.dialogText.copyWith(
                                  decoration: checkBoxState
                                      ? TextDecoration.lineThrough
                                      : null),
                        ),
                      ],
                    ))
              ],
            )
          : const SizedBox(
              height: 0,
              width: 0,
            );
    });

    Widget fullDayCheckbox = BlocBuilder<CalendarTypeCubit, CalendarType>(
        builder: (unUsedcontext, state) {
      return state != CalendarType.ranged
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<CheckboxCubit, bool>(
                  builder: (unUsedcontext, state) {
                    return GestureDetector(
                      onTap: () {
                        context.read<CheckboxCubit>().toggle();
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                            left: Centre.safeBlockHorizontal * 6,
                            right: Centre.safeBlockHorizontal),
                        height: Centre.safeBlockHorizontal * 6,
                        width: Centre.safeBlockHorizontal * 6,
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 2,
                                color: state
                                    ? Centre.colors[8]
                                    : Centre.colors[3]),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(3)),
                            color: Colors.transparent),
                        child: state
                            ? Center(
                                child: Icon(
                                Icons.check,
                                color: Centre.textColor,
                                size: Centre.safeBlockHorizontal * 4,
                              ))
                            : const SizedBox(
                                height: 0,
                                width: 0,
                              ),
                      ),
                    );
                  },
                ),
                Text(
                  "Full day",
                  style: Centre.todoText,
                ),
                Padding(
                  padding:
                      EdgeInsets.only(left: Centre.safeBlockHorizontal * 7.5),
                  child: editButton(height: 5, width: 15, context: context),
                )
              ],
            )
          : Padding(
              padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 33),
              child: editButton(height: 5, width: 15, context: context),
            );
    });

    return GestureDetector(
      onTap: () {},
      child: AlertDialog(
        scrollable: true,
        contentPadding: EdgeInsets.symmetric(
            horizontal: Centre.safeBlockHorizontal * 5,
            vertical: Centre.safeBlockVertical * 3),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(40))),
        backgroundColor: Centre.dialogBgColor,
        elevation: 5,
        content: SizedBox(
          height: daily
              ? Centre.safeBlockVertical * 35
              : Centre.safeBlockVertical * 48,
          width: Centre.safeBlockHorizontal * 85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dialogHeader,
              Padding(
                padding: EdgeInsets.only(
                    top: Centre.safeBlockVertical * 1,
                    left: Centre.safeBlockHorizontal * 2,
                    right: Centre.safeBlockHorizontal * 2),
                child: const Divider(
                  color: Colors.grey,
                ),
              ),
              firstColorRow,
              secondColourRow,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EventNameTextField(
                        controller: controller, formKey: _formKey),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: !daily
                            ? [
                                calendarTypeToggleBtns,
                                SizedBox(
                                  height: Centre.safeBlockVertical * 43,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          calendarPickerRow[0],
                                          calendarPickerRow[1]
                                        ],
                                      ),
                                      SizedBox(
                                        height: Centre.safeBlockVertical * 1,
                                      ),
                                      timePickerRow,
                                      fullDayCheckbox,
                                    ],
                                  ),
                                ),
                              ]
                            : [
                                calendarPickerRow[0],
                                calendarPickerRow[1],
                                timePickerRow,
                                Expanded(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Only show the addToUnfinished button if adding from the todo table, not the unfinished list or the daily monthly list
                                    event != null &&
                                            !fromUnfinishedList &&
                                            !fromDailyMonthlyList
                                        ? addToUnfinishedBtn(context: context)
                                        : const SizedBox(),
                                    editButton(
                                        height: 7, width: 15, context: context),
                                  ],
                                ))
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget addToUnfinishedBtn({required BuildContext context}) {
    // Only called from daily page
    return GestureDetector(
      onTap: () {
        if (!_formKey.currentState!.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Centre.dialogBgColor,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Missing required info: name',
              style: Centre.dialogText,
            ),
            duration: const Duration(seconds: 2),
          ));
          return;
        }
        TimeOfDay start = context.read<TimeRangeCubit>().state.startResult!;
        TimeOfDay end = context.read<TimeRangeCubit>().state.endResult!;
        DateTime prevDay = DateTime.utc(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day -
                (DateTime.now().hour == 0 ||
                        DateTime.now().hour == 1 && DateTime.now().minute == 0
                    ? 1
                    : 0) -
                1);
        EventData newEvent = event!.edit(
            fullDay: false,
            start: prevDay.add(Duration(
                hours: start.hour >= 0 && start.hour < 2
                    ? start.hour + 24
                    : start.hour,
                minutes: start.minute)),
            end: prevDay.add(Duration(
                hours:
                    end.hour >= 0 && end.hour <= 2 ? end.hour + 24 : end.hour,
                minutes: end.minute)),
            color: Centre.colors[context.read<ColorCubit>().state].value,
            text: controller.text,
            finished: false);
        context.read<TodoBloc>().add(TodoToUnfinished(event: newEvent));
        context.read<UnfinishedListBloc>().add(const UnfinishedListUpdate());
        Navigator.pop(context);
      },
      child: SizedBox(
        height: Centre.safeBlockVertical * 7,
        width: Centre.safeBlockHorizontal * 15,
        child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.all(Centre.safeBlockHorizontal),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: Centre.editButtonColor,
                boxShadow: [
                  BoxShadow(
                    color: Centre.darkerDialogBgColor,
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.playlist_add_check_sharp,
                color: Centre.primaryColor,
                size: Centre.safeBlockHorizontal * 8,
              ),
            )),
      ),
    );
  }

  Widget editButton(
      {required int height,
      required int width,
      required BuildContext context}) {
    EventData? oldEvent = event == null
        ? null
        : EventData(
            fullDay: event!.fullDay,
            start: event!.start,
            end: event!.end,
            color: event!.color,
            text: event!.text,
            finished: event!.finished);
    return GestureDetector(
      onTap: () {
        if (!daily) {
          // If the user did not input the required monthly data correctly
          /* Required monthly data:
           * - textfield text
           * - time range OR the full day box should be checked
           * - list of dates
           */
          Map<String, bool> missingNameDatesTime = {
            "name": !_formKey.currentState!.validate(),
            "date": (context.read<DialogDatesCubit>().state ?? []).isEmpty,
            "time": context.read<TimeRangeCubit>().state.endResult == null &&
                !context.read<CheckboxCubit>().state &&
                context.read<CalendarTypeCubit>().state != CalendarType.ranged
          };

          if (missingNameDatesTime.values.contains(true)) {
            String snackBarString = 'Missing required info:';
            missingNameDatesTime.forEach((key, missing) {
              if (missing) snackBarString += " $key,";
            });

            // Remove the last comma
            snackBarString =
                snackBarString.substring(0, snackBarString.length - 1);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Centre.dialogBgColor,
              behavior: SnackBarBehavior.floating,
              content: Text(
                snackBarString,
                style: Centre.dialogText,
              ),
              duration: const Duration(seconds: 2),
            ));
            return;
          }
        } else {
          // If the user did not input the required daily data correctly
          /* Required daily data:
           * - textfield text
           * - time range
           * - date in which the time range is 
           *    (provided already if creating an event via the Daily Page as opposed to the Unordered Page)
           */

          Map<String, bool> missingNameTime = {
            "name": !_formKey.currentState!.validate(),
            "time": context.read<TimeRangeCubit>().state.endResult == null ||
                !editedTimes
          };

          if (missingNameTime.values.contains(true)) {
            String snackBarString = 'Missing required info:';
            missingNameTime.forEach((key, missing) {
              if (missing) snackBarString += " $key,";
            });

            // Remove the last comma
            snackBarString =
                snackBarString.substring(0, snackBarString.length - 1);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Centre.dialogBgColor,
              behavior: SnackBarBehavior.floating,
              content: Text(
                snackBarString,
                style: Centre.dialogText,
              ),
              duration: const Duration(seconds: 2),
            ));
            return;
          }
        }

        TimeOfDay start = const TimeOfDay(hour: 0, minute: 0);
        TimeOfDay end = const TimeOfDay(hour: 0, minute: 0);

        if (oldEvent == null) {
          // If adding an event

          if (!daily) {
            // To monthly page
            CalendarType calendarState =
                context.read<CalendarTypeCubit>().state;

            if (calendarState != CalendarType.ranged &&
                !context.read<CheckboxCubit>().state) {
              // If the event is not ranged and a time range was provided
              // Set the start and end times

              start = context.read<TimeRangeCubit>().state.startResult!;
              end = context.read<TimeRangeCubit>().state.endResult!;
            }
            bool fullDay = context.read<CheckboxCubit>().state;
            if (calendarState == CalendarType.multi) {
              for (DateTime? date in context.read<DialogDatesCubit>().state!) {
                // Add the event to the repository
                context.read<MonthlyTodoBloc>().add(MonthlyTodoCreate(
                    currentMonth: monthOrDayDate,
                    selectedDailyDay: context.read<DateCubit>().state,
                    event: EventData(
                        fullDay: fullDay,
                        start: date!.add(
                            Duration(hours: start.hour, minutes: start.minute)),
                        end: date.add(Duration(
                            hours: start.isBefore(end: end)
                                ? end.hour
                                : end.hour + 24,
                            minutes: end.minute)),
                        color: Centre
                            .colors[context.read<ColorCubit>().state].value,
                        text: controller.text,
                        finished: false)));
              }
            } else {
              // Add the event to the repository
              context.read<MonthlyTodoBloc>().add(MonthlyTodoCreate(
                  currentMonth: monthOrDayDate,
                  selectedDailyDay: context.read<DateCubit>().state,
                  event: EventData(
                      fullDay:
                          calendarState == CalendarType.ranged ? true : fullDay,
                      start: context.read<DialogDatesCubit>().state![0]!.add(
                          Duration(hours: start.hour, minutes: start.minute)),
                      end: context
                          .read<DialogDatesCubit>()
                          .state![calendarState == CalendarType.single ? 0 : 1]!
                          .add(Duration(
                              hours: start.isBefore(end: end)
                                  ? end.hour
                                  : end.hour + 24,
                              minutes: end.minute)),
                      color:
                          Centre.colors[context.read<ColorCubit>().state].value,
                      text: controller.text,
                      finished: false)));
            }
          } else {
            // Set the start and end times
            start = context.read<TimeRangeCubit>().state.startResult!;
            end = context.read<TimeRangeCubit>().state.endResult!;

            // Add the event to the repository
            // If the hours fall past 00:00, event is on the next day, so another 24 hours must be added
            context.read<TodoBloc>().add(TodoCreate(
                date: null,
                event: EventData(
                    fullDay: false,
                    start: (context.read<DateCubit>().state).add(Duration(
                        hours: start.hour >= 0 && start.hour < 2
                            ? start.hour + 24
                            : start.hour,
                        minutes: start.minute)),
                    end: (context.read<DateCubit>().state).add(Duration(
                        hours: end.hour >= 0 && end.hour < 2
                            ? end.hour + 24
                            : end.hour,
                        minutes: end.minute)),
                    color:
                        Centre.colors[context.read<ColorCubit>().state].value,
                    text: controller.text,
                    finished: false)));
          }
        } else {
          // Editing an event
          if (!daily) {
            CalendarType calendarState =
                context.read<CalendarTypeCubit>().state;
            bool fullDay = context.read<CheckboxCubit>().state;

            if (calendarState == CalendarType.multi) {
              context.read<MonthlyTodoBloc>().add(MonthlyTodoDelete(
                  event: event!,
                  selectedDailyDay: context.read<DateCubit>().state,
                  currentMonth: monthOrDayDate));

              for (DateTime? date in context.read<DialogDatesCubit>().state!) {
                // Add the event to the repository
                context.read<MonthlyTodoBloc>().add(MonthlyTodoCreate(
                    currentMonth: monthOrDayDate,
                    selectedDailyDay: context.read<DateCubit>().state,
                    event: EventData(
                        fullDay: fullDay,
                        start: date!.add(
                            Duration(hours: start.hour, minutes: start.minute)),
                        end: date.add(Duration(
                            hours: start.isBefore(end: end)
                                ? end.hour
                                : end.hour + 24,
                            minutes: end.minute)),
                        color: Centre
                            .colors[context.read<ColorCubit>().state].value,
                        text: controller.text,
                        finished: false)));
              }
            } else {
              if (context.read<CalendarTypeCubit>().state !=
                      CalendarType.ranged &&
                  !context.read<CheckboxCubit>().state) {
                // If the event is not ranged and a time range was provided
                // Set the start and end times

                start = context.read<TimeRangeCubit>().state.startResult!;
                end = context.read<TimeRangeCubit>().state.endResult!;
              }

              DateTime? dateWithoutTime;
              if (context.read<CalendarTypeCubit>().state ==
                  CalendarType.single) {
                DateTime prevDate = context.read<DialogDatesCubit>().state![0]!;
                dateWithoutTime =
                    DateTime.utc(prevDate.year, prevDate.month, prevDate.day);
              }

              context.read<MonthlyTodoBloc>().add(MonthlyTodoUpdate(
                  currentMonth: monthOrDayDate,
                  oldEvent: oldEvent,
                  selectedDailyDay: context.read<DateCubit>().state,
                  event: event!.edit(
                      fullDay: fullDay,
                      start: (dateWithoutTime ??
                              context.read<DialogDatesCubit>().state![0]!)
                          .add(Duration(
                              hours: start.hour, minutes: start.minute)),
                      end: (dateWithoutTime ??
                              context.read<DialogDatesCubit>().state![1]!)
                          .add(Duration(
                              hours: start.isBefore(end: end)
                                  ? end.hour
                                  : end.hour + 24,
                              minutes: end.minute)),
                      color:
                          Centre.colors[context.read<ColorCubit>().state].value,
                      text: controller.text,
                      finished: false)));
            }
          } else {
            start = context.read<TimeRangeCubit>().state.startResult!;
            end = context.read<TimeRangeCubit>().state.endResult!;

            if (!fromUnfinishedList || fromDailyMonthlyList) {
              context.read<TodoBloc>().add(TodoUpdate(
                  event: fromDailyMonthlyList
                      ? EventData(
                          fullDay: false,
                          start: context.read<DateCubit>().state.add(Duration(
                              hours: start.hour >= 0 && start.hour < 2
                                  ? start.hour + 24
                                  : start.hour,
                              minutes: start.minute)),
                          end: context.read<DateCubit>().state.add(Duration(
                              hours: end.hour >= 0 && end.hour <= 2
                                  ? end.hour + 24
                                  : end.hour,
                              minutes: end.minute)),
                          color: Centre
                              .colors[context.read<ColorCubit>().state].value,
                          text: controller.text,
                          finished: false)
                      // Somehow Editing the event here will reflect the changes in the monthly hive even though I never call put or save
                      // Maybe put or save is only needed when closing the app, otherwise changes are reflected immediately?
                      // This ternary prevents adding the dailyMonthly from editing the original in the monthly hive
                      : event!.edit(
                          fullDay: false,
                          start: context.read<DateCubit>().state.add(Duration(
                              hours: start.hour >= 0 && start.hour < 2
                                  ? start.hour + 24
                                  : start.hour,
                              minutes: start.minute)),
                          end: context.read<DateCubit>().state.add(Duration(
                              hours: end.hour >= 0 && end.hour <= 2
                                  ? end.hour + 24
                                  : end.hour,
                              minutes: end.minute)),
                          color: Centre
                              .colors[context.read<ColorCubit>().state].value,
                          text: controller.text,
                          finished: false),
                  fromDailyMonthlyList: fromDailyMonthlyList));
            } else {
              // Add the unfinished event to the daily page and remove it from the unfinished list
              EventData newEvent = event!.edit(
                  fullDay: false,
                  start: context.read<DateCubit>().state.add(Duration(
                      hours: start.hour >= 0 && start.hour < 2
                          ? start.hour + 24
                          : start.hour,
                      minutes: start.minute)),
                  end: context.read<DateCubit>().state.add(Duration(
                      hours: end.hour >= 0 && end.hour <= 2
                          ? end.hour + 24
                          : end.hour,
                      minutes: end.minute)),
                  color: Centre.colors[context.read<ColorCubit>().state].value,
                  text: controller.text,
                  finished: false);
              context.read<TodoBloc>().add(TodoFromUnfinished(event: newEvent));
              context
                  .read<UnfinishedListBloc>()
                  .add(const UnfinishedListUpdate());
            }
          }
        }

        Navigator.pop(context, true);
      },
      child: SizedBox(
        height: Centre.safeBlockVertical * height,
        width: Centre.safeBlockHorizontal * width,
        child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.all(Centre.safeBlockHorizontal),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: Centre.editButtonColor,
                boxShadow: [
                  BoxShadow(
                    color: Centre.darkerDialogBgColor,
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                color: Centre.primaryColor,
                size: Centre.safeBlockHorizontal * 8,
              ),
            )),
      ),
    );
  }

  /*
   * Opens a time picker dialog for both the start time and end time.
   * Loops until the user has picked both
   */
  Future<TimeRangeState> chooseTimeRange({
    required BuildContext context,
    required bool daily,
    EventData? editingEvent,
    DateTime? dailyDate,
    TimeOfDay? prevChosenStart,
    TimeOfDay? prevChosenEnd,
  }) async {
    TimeOfDay? endResult;
    TimeOfDay? startResult;
    double time = 0;
    do {
      // Pick the start time first
      // If adding an unfinished event, treat like adding a new event to the table rather than editing one in the table

      time = 0;
      startResult = await showDialog(
          context: context,
          builder: (BuildContext tcontext) {
            return custom_time_picker.TimePickerDialog(
              // Start the initial time with either something previously chosen or the current time rounded to the
              // nearest 5 minutes
              initialTime: prevChosenStart ??
                  TimeOfDay.now().replacing(
                      minute: (TimeOfDay.now().minute / 5).ceil() * 5 == 60
                          ? 0
                          : (TimeOfDay.now().minute / 5).round() * 5,
                      hour: (TimeOfDay.now().minute / 5).ceil() * 5 == 60
                          ? TimeOfDay.now().hour + 1
                          : TimeOfDay.now().hour),
              helpText: "Choose Start time",
              daily: daily,
              orderedDailyKeyList: daily
                  ? context.read<TodoBloc>().state.orderedDailyKeyList
                  : null,
              dailyTableMap:
                  daily ? context.read<TodoBloc>().state.dailyTableMap : null,

              // If editing event already on the table, send in that event, but if not, treat it like adding a new event i.e. editingEvent = null
              editingEvent: daily &&
                          !context
                              .read<TodoBloc>()
                              .state
                              .orderedDailyKeyList
                              .contains(editingEvent?.key) ||
                      fromDailyMonthlyList
                  ? null
                  : editingEvent,
              dailyDate: dailyDate,
            );
          });
      if (startResult != null) {
        // Pick the end time
        prevChosenStart = startResult;

        // ignore: use_build_context_synchronously
        endResult = await showDialog(
            context: context,
            builder: (BuildContext tcontext) {
              TimeOfDay endMinimum = startResult!.add(minutes: 15);

              return custom_time_picker.TimePickerDialog(
                // Start the initial time 15 minutes time after the chosen start time
                initialTime: (prevChosenEnd?.isBefore(end: endMinimum) ?? true
                    ? startResult.replacing(
                        minute: (startResult.minute + 15) % 60,
                        hour: startResult.minute + 15 >= 60
                            ? startResult.hour + 1 % 24
                            : startResult.hour)
                    : prevChosenEnd!),
                helpText: "Choose End time",
                daily: daily,
                orderedDailyKeyList: daily
                    ? context.read<TodoBloc>().state.orderedDailyKeyList
                    : null,
                dailyTableMap:
                    daily ? context.read<TodoBloc>().state.dailyTableMap : null,
                startTime: startResult,
                editingEvent: daily &&
                            !context
                                .read<TodoBloc>()
                                .state
                                .orderedDailyKeyList
                                .contains(editingEvent?.key) ||
                        fromDailyMonthlyList
                    ? null
                    : editingEvent,
                dailyDate: dailyDate,
              );
            });
        time = endResult != null ? endResult.hour + endResult.minute / 60.0 : 0;
      }
    } while (time == 1 / 60.0);
    // time only has this value if user decides to go back to change start time from end time
    return TimeRangeState(startResult, endResult);
  }
}
