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
  final bool daily;
  late final DateTime monthOrDayDate;
  final EventData? event;
  final ValueNotifier<List<DateTime?>?> dateResults = ValueNotifier<List<DateTime?>?>(null);
  final ValueNotifier<TimeRangeState> timeRangeChosen = ValueNotifier<TimeRangeState>(TimeRangeState(null, null));
  final ValueNotifier<bool?> deleting = ValueNotifier<bool?>(false);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController controller;
  AddEventDialog.daily({super.key, this.daily = true, this.event});
  AddEventDialog.monthly({super.key, this.daily = false, this.event, required this.monthOrDayDate});

  @override
  Widget build(BuildContext context) {
    if (!daily) {
      dateResults.addListener(() {
        context.read<DialogDatesCubit>().update(dateResults.value);
      });
    } else {
      monthOrDayDate = context.read<DateCubit>().state;
    }
    timeRangeChosen.addListener(() {
      context.read<TimeRangeCubit>().update(timeRangeChosen.value.startResult, timeRangeChosen.value.endResult);
    });
    deleting.addListener(() {
      if (deleting.value ?? false) Navigator.pop(context);
    });
    controller = TextEditingController(text: event?.text);

    return AlertDialog(
      scrollable: true,
      contentPadding:
          EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 5, vertical: Centre.safeBlockVertical * 3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
      backgroundColor: Centre.dialogBgColor,
      elevation: 5,
      content: SizedBox(
        height: daily ? Centre.safeBlockVertical * 35 : Centre.safeBlockVertical * 48,
        width: Centre.safeBlockHorizontal * 85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 4),
                  child: Text(
                    event == null ? "New Event" : "Edit Event",
                    style: Centre.todoSemiTitle,
                  ),
                ),
                event != null
                    ? GestureDetector(
                        onTap: () async {
                          deleting.value = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext tcontext) {
                                return MultiBlocProvider(
                                  providers: daily
                                      ? [BlocProvider.value(value: context.read<TodoBloc>())]
                                      : [
                                          BlocProvider.value(value: context.read<MonthlyTodoBloc>()),
                                          BlocProvider.value(value: context.read<DateCubit>())
                                        ],
                                  child: DeleteConfirmationDialog(
                                    type: daily ? DeletingFrom.todoTable : DeletingFrom.monthCalen,
                                    event: event!,
                                    currentMonth: monthOrDayDate,
                                  ),
                                );
                              });
                        },
                        child: Container(
                          height: Centre.safeBlockVertical * 3.5,
                          width: Centre.safeBlockVertical * 3.5,
                          margin: EdgeInsets.only(right: Centre.safeBlockHorizontal * 4),
                          child: Icon(Icons.delete_rounded, color: Color(event!.color), size: 35),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: Centre.safeBlockVertical * 3.5,
                          width: Centre.safeBlockVertical * 3.5,
                          margin: EdgeInsets.only(right: Centre.safeBlockHorizontal * 4),
                          child: Icon(Icons.cancel_outlined, color: Centre.red, size: 35),
                        ),
                      ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: Centre.safeBlockVertical * 1,
                  left: Centre.safeBlockHorizontal * 2,
                  right: Centre.safeBlockHorizontal * 2),
              child: const Divider(
                color: Colors.grey,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: Centre.safeBlockVertical * 1),
              child: BlocBuilder<ColorCubit, int>(
                builder: (context, state) => Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < 5; i++)
                      GestureDetector(
                        onTap: () {
                          context.read<ColorCubit>().update(i);
                        },
                        child: Container(
                          width: 25,
                          height: 25,
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
                      )
                  ],
                ),
              ),
            ),
            BlocBuilder<ColorCubit, int>(
              builder: (context, state) => Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 5; i < 10; i++)
                    GestureDetector(
                      onTap: () {
                        context.read<ColorCubit>().update(i);
                      },
                      child: Container(
                        width: 25,
                        height: 25,
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
                    )
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EventNameTextField(controller: controller, formKey: _formKey),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: !daily
                          ? [
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 3),
                                height: Centre.safeBlockHorizontal * 43,
                                width: Centre.safeBlockVertical * 8,
                                decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 77, 77, 77),
                                    borderRadius: BorderRadius.all(Radius.circular(10))),
                                child: BlocBuilder<CalendarTypeCubit, CalendarType>(
                                  builder: (context, state) => Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (event == null) {
                                            context.read<CalendarTypeCubit>().pressed(CalendarType.single);
                                            context.read<DialogDatesCubit>().update(null);
                                          }
                                        },
                                        child: svgButton(
                                            name: "single_date",
                                            color: event == null
                                                ? (state == CalendarType.single ? Centre.yellow : Centre.colors[4])
                                                : (state == CalendarType.single
                                                    ? Centre.yellow
                                                    : Centre.lighterDialogColor),
                                            height: 7,
                                            width: 7,
                                            padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                                            borderColor: event == null && state == CalendarType.single
                                                ? Centre.colors[8]
                                                : Colors.transparent),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (event == null) {
                                            context.read<CalendarTypeCubit>().pressed(CalendarType.ranged);
                                            context.read<DialogDatesCubit>().update(null);
                                          }
                                        },
                                        child: svgButton(
                                            name: "range_date",
                                            color: event == null
                                                ? (state == CalendarType.ranged ? Centre.yellow : Centre.colors[4])
                                                : (state == CalendarType.ranged
                                                    ? Centre.yellow
                                                    : Centre.lighterDialogColor),
                                            height: 7,
                                            width: 7,
                                            padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                                            borderColor: event == null && state == CalendarType.ranged
                                                ? Centre.colors[8]
                                                : Colors.transparent),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (event == null) {
                                            context.read<CalendarTypeCubit>().pressed(CalendarType.multi);
                                            context.read<DialogDatesCubit>().update(null);
                                          }
                                        },
                                        child: svgButton(
                                            name: "multi_date",
                                            color: event == null
                                                ? (state == CalendarType.multi ? Centre.yellow : Centre.colors[4])
                                                : Centre.lighterDialogColor,
                                            height: 7,
                                            width: 7,
                                            padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                                            borderColor: event == null && state == CalendarType.multi
                                                ? Centre.colors[8]
                                                : Colors.transparent),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Centre.safeBlockHorizontal * 43,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            List<DateTime?>? results = await showCalendarDatePicker2Dialog(
                                              dialogBackgroundColor: Centre.dialogBgColor,
                                              barrierColor: Colors.transparent,
                                              borderRadius: 40,
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(
                                                weekdayLabelTextStyle: Centre.todoText.copyWith(color: Centre.yellow),
                                                controlsTextStyle: Centre.dialogText,
                                                gapBetweenCalendarAndButtons: 0,
                                                lastMonthIcon: const SizedBox(
                                                  width: 0,
                                                  height: 0,
                                                ),
                                                nextMonthIcon: const SizedBox(
                                                  width: 0,
                                                  height: 0,
                                                ),
                                                shouldCloseDialogAfterCancelTapped: true,
                                                cancelButtonTextStyle: Centre.dialogText,
                                                okButton: Container(
                                                  margin: EdgeInsets.only(right: Centre.safeBlockHorizontal * 3),
                                                  child: Text(
                                                    "OK",
                                                    style: Centre.dialogText,
                                                  ),
                                                ),
                                                dayTextStyle: Centre.todoText,
                                                calendarType:
                                                    context.read<CalendarTypeCubit>().state == CalendarType.single
                                                        ? CalendarDatePicker2Type.single
                                                        : context.read<CalendarTypeCubit>().state == CalendarType.ranged
                                                            ? CalendarDatePicker2Type.range
                                                            : CalendarDatePicker2Type.multi,
                                                firstDate: DateTime(monthOrDayDate.year),
                                                lastDate: DateTime(monthOrDayDate.year + 2, 12, 31),
                                                currentDate: monthOrDayDate,
                                                selectedDayHighlightColor: Centre.red,
                                              ),
                                              dialogSize:
                                                  Size(Centre.safeBlockHorizontal * 85, Centre.safeBlockVertical * 48),
                                              initialValue: context.read<DialogDatesCubit>().state ?? [],
                                            );
                                            if (results != null) dateResults.value = results;
                                          },
                                          child: BlocBuilder<CalendarTypeCubit, CalendarType>(
                                            builder: (context, state) {
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
                                        ),
                                        Builder(builder: (context) {
                                          final calendarState = context.watch<CalendarTypeCubit>().state;
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
                                                                    ? DateFormat('MMM d').format(dateResultsState![0]!)
                                                                    : "")
                                                                : (dateResultsState?[0] != null
                                                                    ? [
                                                                        for (DateTime? i in dateResultsState!)
                                                                          DateFormat('MMM d').format(i!)
                                                                      ].join(', ')
                                                                    : ""),
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                            softWrap: true,
                                                            style: Centre.dialogText,
                                                          )),
                                                    ]
                                                  : [
                                                      SizedBox(
                                                          width: Centre.safeBlockHorizontal * 21,
                                                          child: Text(
                                                            dateResultsState?[0] != null
                                                                ? DateFormat('MMM d').format(dateResultsState![0]!)
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
                                                                ? DateFormat('MMM d').format(dateResultsState![1]!)
                                                                : "",
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                            softWrap: true,
                                                            style: Centre.dialogText,
                                                          )),
                                                    ]);
                                        }),
                                      ],
                                    ),
                                    SizedBox(
                                      height: Centre.safeBlockVertical * 1,
                                    ),
                                    Builder(builder: (context) {
                                      final calendarState = context.watch<CalendarTypeCubit>().state;
                                      final checkBoxState = context.watch<CheckboxCubit>().state;
                                      final TimeRangeState timeRangeState = context.watch<TimeRangeCubit>().state;

                                      return calendarState != CalendarType.ranged
                                          ? Row(
                                              children: [
                                                GestureDetector(
                                                    onTap: () async {
                                                      if (!checkBoxState) {
                                                        TimeRangeState? value = await chooseTimeRange(
                                                            context: context,
                                                            daily: daily,
                                                            editingEvent: event,
                                                            prevChosenStart: timeRangeState.startResult);
                                                        if (value.startResult != null && value.endResult != null) {
                                                          timeRangeChosen.value = value;
                                                        }
                                                      }
                                                    },
                                                    child: svgButton(
                                                      name: "range_time",
                                                      color: Centre.yellow,
                                                      height: 7,
                                                      width: 7,
                                                      margin: EdgeInsets.symmetric(
                                                          horizontal: Centre.safeBlockHorizontal * 2),
                                                      padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                                                    )),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      timeRangeState.startResult == null
                                                          ? ""
                                                          : "${timeRangeState.startResult!.hour.toString().padLeft(2, '0')}${timeRangeState.startResult!.minute.toString().padLeft(2, '0')}",
                                                      style: Centre.dialogText.copyWith(
                                                          decoration:
                                                              checkBoxState ? TextDecoration.lineThrough : null),
                                                    ),
                                                    Text(
                                                      timeRangeState.endResult == null
                                                          ? ""
                                                          : "${timeRangeState.endResult!.hour.toString().padLeft(2, '0')}${timeRangeState.endResult!.minute.toString().padLeft(2, '0')}",
                                                      style: Centre.dialogText.copyWith(
                                                          decoration:
                                                              checkBoxState ? TextDecoration.lineThrough : null),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            )
                                          : const SizedBox(
                                              height: 0,
                                              width: 0,
                                            );
                                    }),
                                    BlocBuilder<CalendarTypeCubit, CalendarType>(builder: (context, state) {
                                      return state != CalendarType.ranged
                                          ? Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                BlocBuilder<CheckboxCubit, bool>(
                                                  builder: (context, state) {
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
                                                            border: Border.all(width: 2, color: Centre.colors[4]),
                                                            borderRadius: const BorderRadius.all(Radius.circular(3)),
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
                                                  padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 7.5),
                                                  child: editButton(
                                                      height: 5, width: 15, context: context, oldEvent: event),
                                                )
                                              ],
                                            )
                                          : Padding(
                                              padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 33),
                                              child:
                                                  editButton(height: 5, width: 15, context: context, oldEvent: event),
                                            );
                                    }),
                                  ],
                                ),
                              ),
                            ]
                          : [
                              BlocBuilder<TimeRangeCubit, TimeRangeState>(
                                builder: (context, state) => GestureDetector(
                                    onTap: () async {
                                      TimeRangeState? value = await chooseTimeRange(
                                          context: context,
                                          daily: daily,
                                          dailyDate: monthOrDayDate,
                                          editingEvent: event,
                                          prevChosenStart: state.startResult);
                                      if (value.startResult != null && value.endResult != null) {
                                        timeRangeChosen.value = value;
                                      }
                                    },
                                    child: svgButton(
                                        name: "range_time",
                                        color: Centre.yellow,
                                        height: 7,
                                        width: 7,
                                        margin: EdgeInsets.fromLTRB(Centre.safeBlockHorizontal * 5, 0,
                                            Centre.safeBlockHorizontal * 5, Centre.safeBlockVertical * 2),
                                        padding: EdgeInsets.all(Centre.safeBlockHorizontal))),
                              ),
                              BlocBuilder<TimeRangeCubit, TimeRangeState>(
                                builder: (context, state) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 2),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.startResult == null
                                              ? ""
                                              : "${state.startResult!.hour.toString().padLeft(2, '0')}${state.startResult!.minute.toString().padLeft(2, '0')}",
                                          style: Centre.dialogText,
                                        ),
                                        Text(
                                          state.endResult == null
                                              ? ""
                                              : "${state.endResult!.hour.toString().padLeft(2, '0')}${state.endResult!.minute.toString().padLeft(2, '0')}",
                                          style: Centre.dialogText,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Expanded(child: editButton(height: 7, width: 15, context: context, oldEvent: event))
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget editButton(
      {required int height, required int width, required BuildContext context, required EventData? oldEvent}) {
    return GestureDetector(
      onTap: () {
        if (!daily) {
          if (!_formKey.currentState!.validate() ||
              (context.read<DialogDatesCubit>().state ?? []).isEmpty ||
              context.read<TimeRangeCubit>().state.endResult == null &&
                  !context.read<CheckboxCubit>().state &&
                  context.read<CalendarTypeCubit>().state != CalendarType.ranged) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Centre.dialogBgColor,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Missing required info',
                style: Centre.dialogText,
              ),
              duration: const Duration(seconds: 2),
            ));
            return;
          }
        } else {
          if (!_formKey.currentState!.validate() || context.read<TimeRangeCubit>().state.endResult == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Centre.dialogBgColor,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Missing required info',
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
          if (!daily) {
            if (context.read<CalendarTypeCubit>().state != CalendarType.ranged &&
                !context.read<CheckboxCubit>().state) {
              start = context.read<TimeRangeCubit>().state.startResult!;
              end = context.read<TimeRangeCubit>().state.endResult!;
            }
            bool fullDay = context.read<CheckboxCubit>().state;
            switch (context.read<CalendarTypeCubit>().state) {
              case CalendarType.single:
                context.read<MonthlyTodoBloc>().add(MonthlyTodoCreate(
                    currentMonth: monthOrDayDate,
                    selectedDailyDay: context.read<DateCubit>().state,
                    event: EventData(
                        fullDay: fullDay,
                        start: context
                            .read<DialogDatesCubit>()
                            .state![0]!
                            .add(!fullDay ? Duration(hours: start.hour, minutes: start.minute) : const Duration()),
                        end: context
                            .read<DialogDatesCubit>()
                            .state![0]!
                            .add(!fullDay ? Duration(hours: end.hour, minutes: end.minute) : const Duration()),
                        color: Centre.colors[context.read<ColorCubit>().state].value,
                        text: controller.text,
                        finished: false)));
                break;
              case CalendarType.ranged:
                context.read<MonthlyTodoBloc>().add(MonthlyTodoCreate(
                    currentMonth: monthOrDayDate,
                    selectedDailyDay: context.read<DateCubit>().state,
                    event: EventData(
                        fullDay: true,
                        start: context.read<DialogDatesCubit>().state![0]!,
                        end: context.read<DialogDatesCubit>().state![1]!,
                        color: Centre.colors[context.read<ColorCubit>().state].value,
                        text: controller.text,
                        finished: false)));
                break;
              case CalendarType.multi:
                for (DateTime? date in context.read<DialogDatesCubit>().state ?? []) {
                  context.read<MonthlyTodoBloc>().add(MonthlyTodoCreate(
                      currentMonth: monthOrDayDate,
                      selectedDailyDay: context.read<DateCubit>().state,
                      event: EventData(
                          fullDay: fullDay,
                          start: date!
                              .add(!fullDay ? Duration(hours: start.hour, minutes: start.minute) : const Duration()),
                          end: date.add(!fullDay ? Duration(hours: end.hour, minutes: end.minute) : const Duration()),
                          color: Centre.colors[context.read<ColorCubit>().state].value,
                          text: controller.text,
                          finished: false)));
                }

                break;
            }
          } else {
            start = context.read<TimeRangeCubit>().state.startResult!;
            end = context.read<TimeRangeCubit>().state.endResult!;
            context.read<TodoBloc>().add(TodoCreate(
                event: EventData(
                    fullDay: false,
                    start: context.read<DateCubit>().state.add(Duration(
                        hours: start.hour >= 0 && start.hour < 2 ? start.hour + 24 : start.hour,
                        minutes: start.minute)),
                    end: context.read<DateCubit>().state.add(
                        Duration(hours: end.hour >= 0 && end.hour < 2 ? end.hour + 24 : end.hour, minutes: end.minute)),
                    color: Centre.colors[context.read<ColorCubit>().state].value,
                    text: controller.text,
                    finished: false)));
          }
        } else {
          if (!daily) {
            if (context.read<CalendarTypeCubit>().state != CalendarType.ranged &&
                !context.read<CheckboxCubit>().state) {
              start = context.read<TimeRangeCubit>().state.startResult!;
              end = context.read<TimeRangeCubit>().state.endResult!;
            }
            bool fullDay = context.read<CheckboxCubit>().state;
            switch (context.read<CalendarTypeCubit>().state) {
              case CalendarType.single:
                DateTime prevDate = context.read<DialogDatesCubit>().state![0]!;
                DateTime dateWithoutTime = DateTime(prevDate.year, prevDate.month, prevDate.day);
                context.read<MonthlyTodoBloc>().add(MonthlyTodoUpdate(
                    currentMonth: monthOrDayDate,
                    oldEvent: oldEvent,
                    selectedDailyDay: context.read<DateCubit>().state,
                    event: event!.edit(
                        fullDay: fullDay,
                        start: dateWithoutTime
                            .add(!fullDay ? Duration(hours: start.hour, minutes: start.minute) : const Duration()),
                        end: dateWithoutTime
                            .add(!fullDay ? Duration(hours: end.hour, minutes: end.minute) : const Duration()),
                        color: Centre.colors[context.read<ColorCubit>().state].value,
                        text: controller.text,
                        finished: false)));
                break;
              case CalendarType.ranged:
                context.read<MonthlyTodoBloc>().add(MonthlyTodoUpdate(
                    currentMonth: monthOrDayDate,
                    oldEvent: oldEvent,
                    selectedDailyDay: context.read<DateCubit>().state,
                    event: event!.edit(
                        fullDay: true,
                        start: context.read<DialogDatesCubit>().state![0]!,
                        end: context.read<DialogDatesCubit>().state![1]!,
                        color: Centre.colors[context.read<ColorCubit>().state].value,
                        text: controller.text,
                        finished: false)));
                break;
              default:
                break;
            }
          } else {
            start = context.read<TimeRangeCubit>().state.startResult!;
            end = context.read<TimeRangeCubit>().state.endResult!;

            if (oldEvent.start.isSameDate(other: context.read<DateCubit>().state, daily: true)) {
              context.read<TodoBloc>().add(TodoUpdate(
                  event: event!.edit(
                      fullDay: false,
                      start: context.read<DateCubit>().state.add(Duration(
                          hours: start.hour >= 0 && start.hour < 2 ? start.hour + 24 : start.hour,
                          minutes: start.minute)),
                      end: context.read<DateCubit>().state.add(Duration(
                          hours: end.hour >= 0 && end.hour <= 2 ? end.hour + 24 : end.hour, minutes: end.minute)),
                      color: Centre.colors[context.read<ColorCubit>().state].value,
                      text: controller.text,
                      finished: false)));
            } else {
              context.read<TodoBloc>().add(TodoAddUnfinished(
                  event: event!.edit(
                      fullDay: false,
                      start: context.read<DateCubit>().state.add(Duration(
                          hours: start.hour >= 0 && start.hour < 2 ? start.hour + 24 : start.hour,
                          minutes: start.minute)),
                      end: context.read<DateCubit>().state.add(Duration(
                          hours: end.hour >= 0 && end.hour <= 2 ? end.hour + 24 : end.hour, minutes: end.minute)),
                      color: Centre.colors[context.read<ColorCubit>().state].value,
                      text: controller.text,
                      finished: false)));
              context.read<UnfinishedListBloc>().add(const UnfinishedListUpdate());
            }
          }
        }

        Navigator.pop(context);
      },
      child: SizedBox(
        height: Centre.safeBlockVertical * height,
        width: Centre.safeBlockHorizontal * width,
        child: Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.edit,
              color: Centre.primaryColor,
              size: 35,
            )),
      ),
    );
  }

  Future<TimeRangeState> chooseTimeRange({
    required BuildContext context,
    required bool daily,
    EventData? editingEvent,
    DateTime? dailyDate,
    TimeOfDay? prevChosenStart,
  }) async {
    TimeOfDay? endResult;
    TimeOfDay? startResult;
    double time = 0;
    do {
      time = 0;
      startResult = await showDialog(
          context: context,
          builder: (BuildContext tcontext) {
            return custom_time_picker.TimePickerDialog(
              initialTime: prevChosenStart ??
                  TimeOfDay.now().replacing(
                      minute:
                          (TimeOfDay.now().minute / 5).ceil() * 5 == 60 ? 0 : (TimeOfDay.now().minute / 5).round() * 5,
                      hour: (TimeOfDay.now().minute / 5).ceil() * 5 == 60
                          ? TimeOfDay.now().hour + 1
                          : TimeOfDay.now().hour),
              helpText: "Choose Start time",
              daily: daily,
              orderedDailyKeyList: daily ? context.read<TodoBloc>().state.orderedDailyKeyList : null,
              dailyTableMap: daily ? context.read<TodoBloc>().state.dailyTableMap : null,
              editingEvent: editingEvent,
              dailyDate: dailyDate,
            );
          });
      if (startResult != null) {
        endResult = await showDialog(
            context: context,
            builder: (BuildContext tcontext) {
              return custom_time_picker.TimePickerDialog(
                initialTime: startResult!.replacing(
                    minute: (startResult.minute + 15) % 60,
                    hour: startResult.minute + 15 >= 60 ? startResult.hour + 1 : startResult.hour),
                helpText: "Choose End time",
                daily: daily,
                orderedDailyKeyList: daily ? context.read<TodoBloc>().state.orderedDailyKeyList : null,
                dailyTableMap: daily ? context.read<TodoBloc>().state.dailyTableMap : null,
                startTime: startResult,
                editingEvent: editingEvent,
                dailyDate: dailyDate,
              );
            });
        time = endResult != null ? endResult.hour + endResult.minute / 60.0 : 0;
      }
    } while (time == 1 / 60.0);
    return TimeRangeState(startResult, endResult);
  }
}
