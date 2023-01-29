import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:todo/blocs/todo_expanded_bloc.dart';
import 'package:todo/blocs/future_todo_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/models/future_todo.dart';
import 'package:todo/utils/centre.dart';

class FutureTodoTile extends StatefulWidget {
  final FutureTodo todo;
  final bool expandable;
  final TextEditingController textController;
  final FocusNode focusNode;

  const FutureTodoTile(
      {super.key,
      required this.todo,
      required this.expandable,
      required this.textController,
      required this.focusNode});

  @override
  State<FutureTodoTile> createState() => _FutureTodoTileState();
}

class _FutureTodoTileState extends State<FutureTodoTile> with TickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController arrowController;
  late AnimationController animController;
  bool deleted = false;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    arrowController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    List<int> recentAddedInfo = context.read<TodoRecentlyAddedCubit>().state;
    if (widget.todo.indented == 0) {
      animController.value = 1.0;
    }
    if (recentAddedInfo.isNotEmpty && recentAddedInfo[1] == 0 && recentAddedInfo[0] == widget.todo.index) {
      context.read<TodoRecentlyAddedCubit>().update([recentAddedInfo[0], 1]);
      animController.value = 1.0;
    }
    animation = CurvedAnimation(
      parent: animController,
      curve: Curves.fastOutSlowIn,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.dismissed && deleted) {
          context.read<FutureTodoBloc>().add(FutureTodoDelete(event: widget.todo));
        }
      });
    if (widget.expandable) {
      if (context.read<FutureTodoBloc>().state.futureList[widget.todo.index + 1].collapsed) {
        arrowController.reverse();
      } else {
        arrowController.forward();
      }
    }
    if (context.read<FutureTodoBloc>().state.futureList[widget.todo.index].collapsed) {
      animController.reverse();
      arrowController.reverse();
    } else {
      animController.forward();
    }
  }

  @override
  void dispose() {
    arrowController.dispose();
    animController.dispose();
    super.dispose();
  }

  Widget tileBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
        onTap: () {
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: color),
          ),
          margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
          padding: EdgeInsets.all(Centre.safeBlockHorizontal * 1.5),
          child: Icon(
            icon,
            color: color,
            size: Centre.safeBlockHorizontal * 5,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FutureTodoBloc, FutureTodoState>(listener: (unUsedContext, state) {
          if (state is FutureTodoRefreshedFromDelete &&
              state.deletedTreeIndexes.contains(widget.todo.index)) {
            animController.forward();
          } else if (state is FutureTodoRefreshed) {
            // Control the arrows
            if (widget.expandable) {
              if (widget.todo.index + 1 != state.futureList.length &&
                  state.futureList[widget.todo.index + 1].collapsed) {
                arrowController.reverse();
              } else {
                arrowController.forward();
              }
            }

            // Control whether or not todo is expanded
            if (state.futureList[widget.todo.index].collapsed) {
              animController.reverse();
              arrowController.reverse();
            } else {
              animController.forward();
            }
          }
        })
      ],
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, child) => ClipRect(
          child: Align(
            alignment: Alignment.center,
            heightFactor: animation.value,
            widthFactor: null,
            child: child,
          ),
        ),
        child: Dismissible(
            key: Key("${widget.todo.text} ${widget.todo.index}"),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              context.read<FutureTodoBloc>().add(FutureTodoDelete(event: widget.todo));
            },
            child: GestureDetector(
              // onLongPress overrides the dragging from ReorderableListView
              onLongPress: () {},
              onTap: () {
                if (widget.expandable) {
                  List<FutureTodo> futureList = context.read<FutureTodoBloc>().state.futureList;

                  if (arrowController.status == AnimationStatus.dismissed ||
                      arrowController.status == AnimationStatus.reverse) {
                    for (int i = widget.todo.index + 1;
                        i < futureList.length &&
                            futureList[widget.todo.index].indented < futureList[i].indented;
                        i++) {
                      if (futureList[i].indented == futureList[widget.todo.index].indented + 1) {
                        futureList[i].setCollapsed(false);
                      }
                    }

                    context.read<FutureTodoBloc>().add(FutureTodoListUpdate(eventList: futureList));
                  } else {
                    for (int i = widget.todo.index + 1;
                        i < futureList.length &&
                            futureList[widget.todo.index].indented < futureList[i].indented;
                        i++) {
                      futureList[i].setCollapsed(true);
                    }

                    context.read<FutureTodoBloc>().add(FutureTodoListUpdate(eventList: futureList));
                  }
                }
              },
              onDoubleTap: () {
                List<FutureTodo> futureList = context.read<FutureTodoBloc>().state.futureList;
                if (widget.todo.indented > 0 &&
                    (widget.todo.index + 1 == futureList.length ||
                        futureList[widget.todo.index + 1].indented <= widget.todo.indented)) {
                  widget.todo.changeIndent(widget.todo.indented - 1);
                  arrowController.forward();

                  context.read<FutureTodoBloc>().add(FutureTodoUpdate(event: widget.todo));
                }
              },
              child: BlocBuilder<ToggleTodoEditingCubit, bool>(builder: (context, editingState) {
                return SizedBox(
                  height: Centre.safeBlockVertical * (editingState ? 8.5 : 6),
                  width: Centre.safeBlockHorizontal * 90,
                  child: Row(children: [
                    // Indents
                    SizedBox(width: Centre.safeBlockHorizontal * (3 + 7 * widget.todo.indented)),
                    GestureDetector(
                        onDoubleTap: () {
                          List<FutureTodo> futureList = context.read<FutureTodoBloc>().state.futureList;
                          if (widget.todo.indented < 4 &&
                              widget.todo.index != 0 &&
                              futureList[widget.todo.index - 1].indented >= widget.todo.indented) {
                            // Update the indentation
                            futureList[widget.todo.index].changeIndent(widget.todo.indented + 1);

                            // Expand the index of the tree parent that the current widget was just indented into
                            int indexTapped = widget.todo.index - 1;
                            while (indexTapped != -1 &&
                                futureList[indexTapped].indented != widget.todo.indented) {
                              indexTapped--;
                            }
                            indexTapped = indexTapped == -1 ? widget.todo.index - 1 : indexTapped;
                            for (int i = indexTapped + 1;
                                i < futureList.length &&
                                    futureList[indexTapped].indented < futureList[i].indented;
                                i++) {
                              if (futureList[i].indented == futureList[indexTapped].indented + 1) {
                                futureList[i].setCollapsed(false);
                              }
                            }

                            context.read<FutureTodoBloc>().add(FutureTodoListUpdate(eventList: futureList));
                          }
                        },
                        child: widget.expandable
                            ? RotationTransition(
                                turns: Tween(begin: 0.0, end: 0.25).animate(arrowController),
                                child: Icon(Icons.arrow_right_rounded,
                                    color: Centre.textColor, size: Centre.safeBlockHorizontal * 10),
                              )
                            : Text(
                                ' \u2022 ',
                                style:
                                    Centre.todoSemiTitle.copyWith(fontSize: Centre.safeBlockHorizontal * 10),
                              )),
                    Expanded(
                      child: !editingState
                          ? Text(widget.todo.text,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: Centre.dialogText)
                          : BlocBuilder<TodoTextEditingCubit, int?>(builder: (context, indexEditing) {
                              return (indexEditing ?? -1) == widget.todo.index
                                  ? TextFormField(
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.amber),
                                        ),
                                      ),
                                      controller: widget.textController,
                                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                      maxLength: 50,
                                      focusNode: widget.focusNode,
                                      style: Centre.dialogText,
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        context.read<TodoTextEditingCubit>().update(widget.todo.index);
                                        widget.textController.text = widget.todo.text;
                                      },
                                      child: Text(widget.todo.text,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Centre.dialogText),
                                    );
                            }),
                    ),
                    !editingState
                        ? ReorderableDragStartListener(
                            index: widget.todo.index,
                            child: Padding(
                              padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 2),
                              child: Icon(Icons.drag_handle_rounded, size: Centre.safeBlockHorizontal * 6),
                            ))
                        : BlocBuilder<TodoTextEditingCubit, int?>(builder: (context, indexEditing) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                (indexEditing ?? -1) == widget.todo.index
                                    ? tileBtn(
                                        icon: Icons.check,
                                        color: Centre.secondaryColor,
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                        })
                                    : tileBtn(
                                        icon: Icons.add,
                                        color: Centre.secondaryColor,
                                        onTap: () {
                                          widget.textController.clear();
                                          arrowController.forward();

                                          List<FutureTodo> futureList =
                                              context.read<FutureTodoBloc>().state.futureList;

                                          for (int i = widget.todo.index + 1;
                                              i < futureList.length &&
                                                  futureList[widget.todo.index].indented <
                                                      futureList[i].indented;
                                              i++) {
                                            if (futureList[i].indented ==
                                                futureList[widget.todo.index].indented + 1) {
                                              futureList[i].setCollapsed(false);
                                            }
                                          }
                                          context
                                              .read<TodoTileAddCubit>()
                                              .update([widget.todo.index + 1, widget.todo.indented + 1, 0]);
                                          context
                                              .read<FutureTodoBloc>()
                                              .add(FutureTodoListUpdate(eventList: futureList));
                                        }),
                                tileBtn(
                                    icon: Icons.delete,
                                    color: Centre.red,
                                    onTap: () {
                                      deleted = true;
                                      animController.reverse();
                                    })
                              ],
                            );
                          }),
                  ]),
                );
              }),
            )),
      ),
    );
  }
}
