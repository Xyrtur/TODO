import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:todo/utils/centre.dart';
import 'package:todo/models/future_todo.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';

class UnorderedPage extends StatefulWidget {
  const UnorderedPage({super.key});

  @override
  State<UnorderedPage> createState() => _UnorderedPageState();
}

class _UnorderedPageState extends State<UnorderedPage> {
// class UnorderedPage extends StatelessWidget {
  // UnorderedPage({super.key});
  final TextEditingController controller = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<FutureTodo?> deletingTodo = ValueNotifier<FutureTodo?>(null);

  @override
  initState() {
    deletingTodo.addListener(() {
      if (deletingTodo.value != null) context.read<FutureTodoBloc>().add(FutureTodoDelete(event: deletingTodo.value!));
    });
    super.initState();
  }

  Future<bool?> showMonthlyDialog(BuildContext context, String text) async {
    return await showDialog(
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
                    BlocProvider<CalendarTypeCubit>(
                      create: (_) => CalendarTypeCubit(null),
                    ),
                    BlocProvider<DialogDatesCubit>(create: (_) => DialogDatesCubit(null)),
                    BlocProvider(create: (_) => CheckboxCubit(false)),
                    BlocProvider.value(value: context.read<MonthlyTodoBloc>()),
                    BlocProvider.value(value: context.read<DateCubit>()),
                  ],
                  child: AddEventDialog.monthly(
                    monthOrDayDate: DateTime(DateTime.now().year, DateTime.now().month),
                    futureTodoText: text,
                  )),
            ));
  }

  Future<bool?> showDailyDialog(BuildContext context, String text) async {
    return await showDialog<bool>(
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
                    BlocProvider.value(value: context.read<TodoBloc>()),
                    BlocProvider<DialogDatesCubit>(create: (_) => DialogDatesCubit(null)),
                  ],
                  child: AddEventDialog.daily(
                    addingFutureTodo: true,
                    futureTodoText: text,
                  )),
            ));
  }

  List<Widget> reorderableTodos(List<FutureTodo> list, BuildContext context) {
    return [
      for (FutureTodo todo in list)
        Slidable(
          key: ValueKey(todo.key),
          startActionPane: ActionPane(
            extentRatio: 0.5,
            motion: const BehindMotion(),
            children: [
              SlidableAction(
                onPressed: (unUsedContext) async {
                  bool? todoAdded = await showDailyDialog(context, todo.text);
                  if (todoAdded ?? false) {
                    deletingTodo.value = todo;
                  }
                },
                backgroundColor: Centre.bgColor,
                foregroundColor: Centre.secondaryColor,
                icon: Icons.wb_sunny_rounded,
                label: '+ Daily',
              ),
              SlidableAction(
                onPressed: (unUsedContext) async {
                  bool? todoAdded = await showMonthlyDialog(context, todo.text);
                  if (todoAdded ?? false) {
                    deletingTodo.value = todo;
                  }
                },
                backgroundColor: Centre.bgColor,
                foregroundColor: Centre.secondaryColor,
                icon: Icons.calendar_month_sharp,
                label: '+ Monthly',
              ),
            ],
          ),
          endActionPane: ActionPane(
            dismissible: DismissiblePane(
              onDismissed: () {
                context.read<FutureTodoBloc>().add(FutureTodoDelete(event: todo));
              },
            ),
            extentRatio: 0.25,
            motion: const BehindMotion(),
            children: [
              SlidableAction(
                // An action can be bigger than the others.
                onPressed: (unUsedContext) {
                  context.read<FutureTodoBloc>().add(FutureTodoDelete(event: todo));
                },
                backgroundColor: Centre.bgColor,
                foregroundColor: Centre.red,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: SizedBox(
            height: Centre.safeBlockVertical * 6,
            child: Row(
              children: [
                SizedBox(
                  width: todo.indented ? Centre.safeBlockHorizontal * 13 : Centre.safeBlockHorizontal * 6,
                ),
                GestureDetector(
                  onTap: () {
                    context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todo.toggleFinished()));
                  },
                  child: Container(
                    width: Centre.safeBlockHorizontal * 7,
                    height: Centre.safeBlockHorizontal * 7,
                    decoration: BoxDecoration(
                        border: Border.all(color: Centre.primaryColor, width: Centre.safeBlockHorizontal * 0.5),
                        borderRadius: const BorderRadius.all(Radius.circular(40))),
                    child: todo.finished
                        ? Icon(Icons.check, size: Centre.safeBlockHorizontal * 5, color: Centre.primaryColor)
                        : null,
                  ),
                ),
                SizedBox(
                  width: Centre.safeBlockHorizontal * 2,
                ),
                TextFormField(
                  decoration: const InputDecoration(border: InputBorder.none),
                  initialValue: todo.text,
                  maxLines: 1,
                  style: Centre.dialogText,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      setState(() {
                        // Rebuilds and sets the text field back
                      });
                    } else {
                      context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todo.changeName(value)));
                    }
                  },
                ),
                GestureDetector(
                  onTap: () {
                    context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todo.toggleIndent()));
                  },
                  child: Expanded(
                      child: Container(
                    color: Colors.blueAccent,
                  )),
                )
              ],
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    Widget addButton = GestureDetector(
      onTap: () {
        if (formKey.currentState!.validate()) {
          context.read<FutureTodoBloc>().add(FutureTodoCreate(
              event: FutureTodo(
                  indented: false,
                  text: controller.text,
                  finished: false,
                  index: context.read<FutureTodoBloc>().state.futureList.length)));
          controller.clear();
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
        padding: EdgeInsets.all(Centre.safeBlockHorizontal * 0.5),
        height: Centre.safeBlockVertical * 5,
        width: Centre.safeBlockVertical * 6,
        child: Icon(
          Icons.add_circle_rounded,
          weight: 700,
          color: Centre.primaryColor,
          size: 35,
        ),
      ),
    );

    Widget textField = SizedBox(
      width: Centre.safeBlockHorizontal * 70,
      child: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          validator: (text) {
            if (text == null || text.isEmpty) {
              return 'Can\'t be empty';
            } else if (text.length > 100) {
              return 'Too long';
            }
            return null;
          },
          style: Centre.dialogText.copyWith(fontSize: Centre.safeBlockHorizontal * 5),
          decoration: InputDecoration(
            hintText: "Todo item",
            hintStyle: Centre.dialogText.copyWith(color: Colors.grey, fontSize: Centre.safeBlockHorizontal * 5),
            isDense: true,
          ),
        ),
      ),
    );

    Widget floatingForm = Container(
      height: Centre.safeBlockVertical * 10,
      width: Centre.safeBlockHorizontal * 90,
      decoration: BoxDecoration(
          color: Centre.dialogBgColor,
          boxShadow: [
            BoxShadow(
              color: Centre.darkerBgColor,
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.fromLTRB(Centre.safeBlockHorizontal * 3, Centre.safeBlockVertical * 2,
          Centre.safeBlockHorizontal * 3, Centre.safeBlockVertical * 5),
      child: Row(
        children: [
          SizedBox(
            width: Centre.safeBlockHorizontal * 5,
          ),
          textField,
          addButton
        ],
      ),
    );

    return SafeArea(
        child: Scaffold(
      backgroundColor: Centre.bgColor,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 7, vertical: Centre.safeBlockVertical * 3),
          child: Text(
            "Near Future",
            style: Centre.todoSemiTitle,
          ),
        ),
        Expanded(
          child: BlocBuilder<FutureTodoBloc, FutureTodoState>(
            builder: (tcontext, state) => Container(
                height: Centre.safeBlockVertical * 75,
                child: ReorderableListView(
                    children: reorderableTodos(state.futureList, context),
                    onReorder: (int old, int news) {
                      List<FutureTodo> oldList = state.futureList;

                      if (old < news) news -= 1;

                      final FutureTodo item = oldList.removeAt(old);
                      oldList.insert(news, item);
                      for (int i = 0; i < oldList.length; i++) {
                        oldList[i].changeIndex(i);
                      }
                      context.read<FutureTodoBloc>().add(FutureTodoListUpdate(eventList: oldList));
                    })),
          ),
        ),
        floatingForm,
      ]),
    ));
  }
}
