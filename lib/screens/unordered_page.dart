import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:todo/utils/centre.dart';
import 'package:todo/models/future_todo.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/widgets/future_todo_tile.dart';

class UnorderedPage extends StatefulWidget {
  const UnorderedPage({super.key, required this.pageController});
  final PageController pageController;

  @override
  State<UnorderedPage> createState() => _UnorderedPageState();
}

class _UnorderedPageState extends State<UnorderedPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final TextEditingController addingTodoTextController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<Widget> reorderablesList = [];
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  FocusNode focusNode = FocusNode();
  late final AnimationController animController;
  @override
  initState() {
    animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.reverse) {
          context.read<TodoTileAddCubit>().update([context.read<TodoTileAddCubit>().state[0], 0, 1]);
          addingTodoTextController.clear();
        }
      });
    reorderableTodos(context.read<FutureTodoBloc>().state.futureList);
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        int? indexEditing = context.read<TodoTextEditingCubit>().state;
        if (controller.text.isNotEmpty && indexEditing != null) {
          FutureTodo currTodo = context.read<FutureTodoBloc>().state.futureList[indexEditing];
          currTodo.changeName(controller.text);
          context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: currTodo));
        }
        context.read<TodoTextEditingCubit>().update(null);
      }
    });

    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    animController.dispose();
    controller.dispose();
    addingTodoTextController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour,
              DateTime.now().minute)
          .isAfter(context.read<FirstDailyDateBtnCubit>().state.add(const Duration(hours: 25)))) {
        context.read<FirstDailyDateBtnCubit>().update(DateTime.utc(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day -
                (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0
                    ? 1
                    : 0)));
      }
      context.read<DateCubit>().setToCurrentDayOnResume();
      context.read<TodoBloc>().add(TodoDateChange(
          date: DateTime.utc(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day -
                  (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0
                      ? 1
                      : 0))));
      context.read<UnfinishedListBloc>().add(const UnfinishedListResume());
      context.read<DailyMonthlyListCubit>().update();
    }
  }

  reorderableTodos(List<FutureTodo> list) {
    // If there was an addTile, keep it there
    int addTileIndex = reorderablesList.indexWhere((Widget widget) => widget.key == ValueKey(12345));
    Widget? addTile = addTileIndex != -1 ? reorderablesList[addTileIndex] : null;

    reorderablesList = [
      for (FutureTodo todo in list)
        MultiBlocProvider(
            key: ValueKey(todo),
            providers: [
              BlocProvider.value(value: context.read<ToggleTodoEditingCubit>()),
              BlocProvider.value(value: context.read<TodoTileAddCubit>()),
              BlocProvider.value(value: context.read<TodoTextEditingCubit>()),
              BlocProvider.value(value: context.read<FutureTodoBloc>()),
              BlocProvider.value(value: context.read<TodoRecentlyAddedCubit>()),
            ],
            child: FutureTodoTile(
              todo: todo,
              focusNode: focusNode,
              expandable:
                  todo.index + 1 == list.length ? false : list[todo.index + 1].indented > todo.indented,
              textController: controller,
            ))
    ];
    if (addTileIndex != -1) {
      reorderablesList.insert(addTileIndex, addTile ?? const SizedBox());
    }
  }

  Widget addingTodoTile(int index, int indents) {
    final formKey = GlobalKey<FormState>();
    Animation<double> animation = CurvedAnimation(
      parent: animController,
      curve: Curves.fastOutSlowIn,
    );
    return AnimatedBuilder(
      key: const ValueKey(12345),
      animation: animation,
      builder: (_, child) => ClipRect(
        child: Form(
          key: formKey,
          child: Align(
            alignment: Alignment.center,
            heightFactor: animation.value,
            widthFactor: null,
            child: child,
          ),
        ),
      ),
      child: GestureDetector(
        // onLongPress overrides the dragging from ReorderableListView
        onLongPress: () {},
        child: SizedBox(
          height: Centre.safeBlockVertical * 10,
          width: Centre.safeBlockHorizontal * 90,
          child: Row(children: [
            // Indents
            SizedBox(width: Centre.safeBlockHorizontal * (3 + 7 * indents)),
            Text(
              ' \u2022 ',
              style: Centre.todoSemiTitle.copyWith(fontSize: Centre.safeBlockHorizontal * 10),
            ),
            Expanded(
                child: TextFormField(
              validator: (input) {
                if (input == null || input.isEmpty) {
                  return 'Can\'t be empty';
                }
                return null;
              },
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              controller: addingTodoTextController,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              maxLength: 50,
              focusNode: focusNode,
              style: Centre.dialogText,
            )),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      context.read<FutureTodoBloc>().add(FutureTodoCreate(
                          event: FutureTodo(
                              indented: indents,
                              text: addingTodoTextController.text,
                              index: index,
                              collapsed: false)));
                      context.read<TodoRecentlyAddedCubit>().update([index, 0]);
                      context
                          .read<TodoTileAddCubit>()
                          .update([context.read<TodoTileAddCubit>().state[0], 0, 1]);
                      addingTodoTextController.clear();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Centre.secondaryColor),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
                    padding: EdgeInsets.all(Centre.safeBlockHorizontal * 1.5),
                    child: Icon(
                      Icons.check,
                      color: Centre.secondaryColor,
                      size: Centre.safeBlockHorizontal * 5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    animController.reverse();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Centre.red),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
                    padding: EdgeInsets.all(Centre.safeBlockHorizontal * 1.5),
                    child: Icon(
                      Icons.delete,
                      color: Centre.red,
                      size: Centre.safeBlockHorizontal * 5,
                    ),
                  ),
                ),
              ],
            )
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Centre().init(context);

    return SafeArea(
        child: Scaffold(
      key: scaffoldKey,
      backgroundColor: Centre.bgColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          context.read<TodoTextEditingCubit>().update(null);
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: Centre.safeBlockHorizontal * 7, vertical: Centre.safeBlockVertical * 3),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Todo List",
                      style: Centre.todoSemiTitle,
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!(reorderablesList.indexWhere((Widget widget) => widget.key == ValueKey(12345)) !=
                            -1)) {
                          context.read<TodoTileAddCubit>().update([0, 0, 0]);
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                            left: Centre.safeBlockHorizontal, right: Centre.safeBlockHorizontal * 2),
                        padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: Centre.lighterBgColor,
                          boxShadow: [
                            BoxShadow(
                              color: Centre.darkerBgColor,
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: Centre.primaryColor,
                          size: Centre.safeBlockHorizontal * 8,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<ToggleTodoEditingCubit>().toggle();
                        context.read<TodoTextEditingCubit>().update(null);
                        if (reorderablesList.indexWhere((Widget widget) => widget.key == ValueKey(12345)) !=
                            -1) {
                          animController.reverse();
                        }
                      },
                      child: BlocBuilder<ToggleTodoEditingCubit, bool>(
                          builder: (context, editingState) => Container(
                                margin: EdgeInsets.only(
                                    left: Centre.safeBlockHorizontal, right: Centre.safeBlockHorizontal * 2),
                                padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  color: editingState ? Centre.primaryColor : Centre.lighterBgColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Centre.darkerBgColor,
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: editingState ? Centre.lighterBgColor : Centre.primaryColor,
                                  size: Centre.safeBlockHorizontal * 8,
                                ),
                              )),
                    ),
                  ],
                ),
                SizedBox(
                  height: Centre.safeBlockVertical,
                ),
                Divider(
                  height: Centre.safeBlockVertical,
                  color: Centre.secondaryColor,
                )
              ],
            ),
          ),
          Expanded(
            child: MultiBlocListener(
                listeners: [
                  BlocListener<FutureTodoBloc, FutureTodoState>(listener: ((notUsedContext, state) {
                    reorderableTodos(state.futureList);

                    if (state is FutureTodoRefreshedFromDelete) {
                      // Show Snackbar with Undo action
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Centre.darkerDialogBgColor,
                        content: Text(
                          'Deleted: ${state.deletedTodo.text}',
                          overflow: TextOverflow.ellipsis,
                          style: Centre.dialogText,
                        ),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: Centre.secondaryColor,
                          onPressed: () {
                            scaffoldKey.currentContext!.read<FutureTodoBloc>().add(FutureTodoUndoDelete(
                                event: state.deletedTodo, undoIndentsIndices: state.deletedTreeIndexes));
                          },
                        ),
                      ));
                    }
                  })),
                  BlocListener<TodoTileAddCubit, List<int>>(listener: ((context, state) {
                    if (state[2] == 1) {
                      reorderablesList.removeAt(state[0]);
                    } else {
                      reorderablesList.insert(state[0], addingTodoTile(state[0], state[1]));
                      animController.value = 0.0;
                      controller.clear();
                    }
                  })),
                ],
                child: BlocBuilder<TodoTextEditingCubit, int?>(
                    buildWhen: (previous, current) {
                      return reorderablesList.indexWhere((Widget widget) => widget.key == ValueKey(12345)) !=
                              -1 &&
                          current != null;
                      // If an addingTile exists but another tile is also about to be edited, remove the adding tile
                    },
                    builder: (tcontext, textEditingState) => BlocBuilder<TodoTileAddCubit, List<int>>(
                        builder: (tcontext, tileAddState) =>
                            BlocBuilder<FutureTodoBloc, FutureTodoState>(builder: (tcontext, state) {
                              if (reorderablesList
                                      .indexWhere((Widget widget) => widget.key == ValueKey(12345)) !=
                                  -1) {
                                // Adding tile exists
                                if (textEditingState != null) {
                                  animController.reverse();
                                } else {
                                  animController.forward();
                                }
                              }
                              print("bruh $reorderablesList");

                              return SizedBox(
                                  height: Centre.safeBlockVertical * 75,
                                  child: ReorderableListView(
                                      scrollController: scrollController,
                                      children: reorderablesList,
                                      onReorderStart: (index) {
                                        for (int i = index + 1;
                                            i < state.futureList.length &&
                                                state.futureList[index].indented <
                                                    state.futureList[i].indented;
                                            i++) {
                                          state.futureList[i].setCollapsed(true);
                                        }

                                        context
                                            .read<FutureTodoBloc>()
                                            .add(FutureTodoListUpdate(eventList: state.futureList));
                                      },
                                      onReorder: (int old, int news) {
                                        List<FutureTodo> oldList = state.futureList;
                                        List<FutureTodo> todosMoved = [oldList[old]];

                                        // First todo in the todosMoved list is the ROOT todo of the tree that was picked up and dragged

                                        // Add the rest of the todos that are part of the root's tree
                                        int i = old + 1;
                                        while (i < oldList.length &&
                                            oldList[old].indented < oldList[i].indented) {
                                          todosMoved.add(oldList[i]);

                                          i++;
                                        }

                                        // Correct the new index
                                        if (old < news) news -= todosMoved.length;

                                        // Remove the tree and place it where it was dragged
                                        oldList.removeRange(old, old + todosMoved.length);

                                        // But first check if placing it under a collapsed tree to ensure not placing it inside the tree
                                        if (news < oldList.length) {
                                          while (oldList[news].collapsed) {
                                            if (++news == oldList.length) break;
                                          }
                                        }
                                        oldList.insertAll(news, todosMoved);

                                        // Update the index attribute of each FutureTodo
                                        for (int i = 0; i < oldList.length; i++) {
                                          oldList[i].changeIndex(i);
                                        }

                                        // Update the indentation
                                        int rootIndentation = todosMoved[0].indented;

                                        if (news == 0 || news + todosMoved.length - 1 == oldList.length - 1) {
                                          // If at the top or bottom, default to no indentation
                                          if (rootIndentation != 0) {
                                            for (int i = 0; i < todosMoved.length; i++) {
                                              oldList[news + i]
                                                  .changeIndent(todosMoved[i].indented - rootIndentation);
                                            }
                                          }
                                        } else {
                                          // In every other case, matches the indentation of the next item (outside of the group if moving a group of todos)
                                          int nextItemIndentation =
                                              oldList[news + todosMoved.length].indented;

                                          if (rootIndentation != nextItemIndentation) {
                                            for (int i = 0; i < todosMoved.length; i++) {
                                              oldList[news + i].changeIndent(todosMoved[i].indented +
                                                  (nextItemIndentation - rootIndentation));
                                            }
                                          }
                                        }

                                        context
                                            .read<FutureTodoBloc>()
                                            .add(FutureTodoListUpdate(eventList: oldList));
                                      }));
                            })))),
          ),
        ]),
      ),
    ));
  }
}
