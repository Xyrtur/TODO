import 'package:flutter/material.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';

enum DeletingFrom { unfinishedList, todoTable, monthCalen }

class DeleteConfirmationDialog extends StatelessWidget {
  final DeletingFrom type;
  final EventData event;
  final DateTime? currentMonth;

  const DeleteConfirmationDialog({super.key, required this.type, required this.event, this.currentMonth});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
        backgroundColor: Centre.dialogBgColor,
        elevation: 5,
        content: SizedBox(
            height: Centre.safeBlockVertical * 19.5,
            width: Centre.safeBlockHorizontal * 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Are you sure?",
                  style: Centre.titleDialogText,
                ),
                SizedBox(
                  height: Centre.safeBlockVertical * 2,
                ),
                Text(
                  "This will permanently remove ${event.text} from ${type == DeletingFrom.unfinishedList ? "your unfinished list." : type == DeletingFrom.todoTable ? "your todo list." : "this month's calendar."}",
                  maxLines: 2,
                  style: Centre.todoText,
                ),
                SizedBox(
                  height: Centre.safeBlockVertical * 2.5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                                  event: event,
                                  selectedDailyDay: context.read<DateCubit>().state,
                                  currentMonth: currentMonth!));

                              break;
                          }

                          Navigator.pop(context, true);
                        },
                        child: Text(
                          "OK",
                          style: Centre.dialogText,
                        ))
                  ],
                )
              ],
            )));
  }
}
