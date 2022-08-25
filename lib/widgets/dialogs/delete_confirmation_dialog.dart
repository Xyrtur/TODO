import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/daily_todo_bloc.dart';
import 'package:todo/blocs/monthly_todo_bloc.dart';
import 'package:todo/blocs/unfinished_bloc.dart';
import 'package:todo/models/event_data.dart';
import 'package:todo/utils/centre.dart';
import 'package:flutter/material.dart';

enum DeletingFrom { unfinishedList, todoTable, monthCalen }

class DeleteConfirmationDialog extends StatelessWidget {
  final DeletingFrom type;
  final EventData event;

  const DeleteConfirmationDialog({super.key, required this.type, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
        backgroundColor: Centre.dialogBgColor,
        elevation: 5,
        content: SizedBox(
            height: Centre.safeBlockVertical * 25,
            width: Centre.safeBlockHorizontal * 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Are you sure?",
                  style: Centre.titleDialogText,
                ),
                Text(
                  "This will permanently remove ${event.text} from ${type == DeletingFrom.unfinishedList ? "your unfinished list." : type == DeletingFrom.todoTable ? "your todo list." : "this month's calendar."}",
                  maxLines: 2,
                  style: Centre.todoText,
                ),
                SizedBox(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: Text(
                              "Cancel",
                              style: Centre.dialogText,
                            )),
                        TextButton(
                            onPressed: () {
                              switch (type) {
                                case DeletingFrom.unfinishedList:
                                  context.read<UnfinishedListBloc>().add(UnfinishedListRemove(event: event));

                                  break;
                                case DeletingFrom.todoTable:
                                  context.read<TodoBloc>().add(TodoDelete(event: event));

                                  break;
                                case DeletingFrom.monthCalen:
                                  context.read<MonthlyTodoBloc>().add(MonthlyTodoDelete(
                                      event: event, selectedDailyDay: context.read<DateCubit>().state));

                                  break;
                              }

                              Navigator.pop(context, true);
                            },
                            child: Text(
                              "OK",
                              style: Centre.dialogText,
                            ))
                      ],
                    ),
                  ),
                )
              ],
            )));
  }
}
