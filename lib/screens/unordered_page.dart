import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:todo/utils/centre.dart';
import 'package:todo/models/future_todo.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';

class UnorderedPage extends StatefulWidget {
  const UnorderedPage({super.key, required this.pageController});
  final PageController pageController;

  @override
  State<UnorderedPage> createState() => _UnorderedPageState();
}

class _UnorderedPageState extends State<UnorderedPage> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController textListController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<FutureTodo?> deletingTodo = ValueNotifier<FutureTodo?>(null);
  FutureTodo? todoTextEditing;
  FocusNode focusNode = FocusNode();
  @override
  initState() {
    deletingTodo.addListener(() {
      if (deletingTodo.value != null) context.read<FutureTodoBloc>().add(FutureTodoDelete(event: deletingTodo.value!));
    });
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        if (textListController.text.isNotEmpty && todoTextEditing != null) {
          todoTextEditing!.changeName(textListController.text);
          todoTextEditing!.toggleEditing();
          context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todoTextEditing!));
        }
        todoTextEditing = null;
      }
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
                    monthOrDayDate: DateTime.utc(DateTime.now().toUtc().year, DateTime.now().toUtc().month),
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
                    BlocProvider.value(value: context.read<DateCubit>()),
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
            extentRatio: 0.4,
            motion: const BehindMotion(),
            children: [
              SlidableAction(
                onPressed: (unUsedContext) {
                  if (todoTextEditing != null) {
                    todoTextEditing!.toggleEditing();
                    context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todoTextEditing!));
                  }

                  todo.toggleEditing();
                  context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todo));
                  textListController.text = todo.text;
                  todoTextEditing = todo;
                  focusNode.requestFocus();
                },
                backgroundColor: Centre.bgColor,
                foregroundColor: Centre.secondaryColor,
                icon: Icons.edit,
                label: 'Edit',
              ),
              SlidableAction(
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
          child: Builder(builder: (slidableContext) {
            Slidable.of(slidableContext)!.actionPaneType.addListener(() {
              setState(() {});
            });
            return SizedBox(
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
                          border: Border.all(
                              color: Slidable.of(slidableContext)!.actionPaneType.value == ActionPaneType.end
                                  ? Colors.transparent
                                  : Centre.primaryColor,
                              width: Centre.safeBlockHorizontal * 0.5),
                          borderRadius: const BorderRadius.all(Radius.circular(40))),
                      child: todo.finished
                          ? Icon(Icons.check,
                              size: Centre.safeBlockHorizontal * 5,
                              color: Slidable.of(slidableContext)!.actionPaneType.value == ActionPaneType.end
                                  ? Colors.transparent
                                  : Centre.primaryColor)
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: Centre.safeBlockHorizontal * 2,
                  ),
                  !todo.todoTextEditing
                      ? Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: todo.toggleIndent()));
                            },
                            child: Text(
                              todo.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Centre.dialogText.copyWith(
                                  color: Slidable.of(slidableContext)!.actionPaneType.value == ActionPaneType.end
                                      ? Colors.transparent
                                      : Centre.textColor),
                            ),
                          ),
                        )
                      : Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: Centre.safeBlockHorizontal * 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Slidable.of(slidableContext)!.actionPaneType.value == ActionPaneType.end
                                          ? Colors.transparent
                                          : Colors.amber),
                                ),
                              ),
                              controller: textListController,
                              maxLines: 1,
                              focusNode: focusNode,
                              style: Centre.dialogText.copyWith(
                                  color: Slidable.of(slidableContext)!.actionPaneType.value == ActionPaneType.end
                                      ? Colors.transparent
                                      : Centre.textColor),
                            ),
                          ),
                        ),
                ],
              ),
            );
          }),
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
                  todoTextEditing: false,
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
              offset: const Offset(0, 2),
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
      body: BlocListener<MonthlyTodoBloc, MonthlyTodoState>(
        listener: (context, state) {
          if (state.changedDailyList) context.read<DailyMonthlyListCubit>().update();
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Centre.safeBlockHorizontal * 7, vertical: Centre.safeBlockVertical * 3),
              child: Text(
                "Todo List",
                style: Centre.todoSemiTitle,
              ),
            ),
            Expanded(
              child: BlocBuilder<FutureTodoBloc, FutureTodoState>(
                builder: (tcontext, state) => SizedBox(
                    height: Centre.safeBlockVertical * 75,
                    child: ReorderableListView(
                        scrollController: scrollController,
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
        ),
      ),
    ));
  }
}
