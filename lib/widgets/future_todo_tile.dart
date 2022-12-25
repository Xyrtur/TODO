import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/todo_expanded_bloc.dart';

import '../blocs/future_todo_bloc.dart';
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

class _FutureTodoTileState extends State<FutureTodoTile>
    with TickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController arrowController;
  late AnimationController animController;
  bool deleted = false;

  bool stillNeedsIndenting = false;

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
    if (recentAddedInfo.isNotEmpty &&
        recentAddedInfo[1] == 0 &&
        recentAddedInfo[0] == widget.todo.index) {
      context.read<TodoRecentlyAddedCubit>().update([recentAddedInfo[0], 1]);
      animController.value = 1.0;
    }
    animation = CurvedAnimation(
      parent: animController,
      curve: Curves.fastOutSlowIn,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.dismissed && deleted) {
          context
              .read<FutureTodoBloc>()
              .add(FutureTodoDelete(event: widget.todo));
        }
      });
  }

  @override
  void dispose() {
    arrowController.dispose();
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExpandableBloc, ExpandableState>(
          listener: (context, state) {
            if (state.indexesToBeExpandedCollapsed.isNotEmpty) {
              if (state.indexesToBeExpandedCollapsed[0] - 1 ==
                      widget.todo.index &&
                  !state.expanding) {
                arrowController.reverse();
              }
              if (state.indexesToBeExpandedCollapsed
                  .contains(widget.todo.index)) {
                if (state.expanding) {
                  animController.forward();
                } else {
                  animController.reverse();
                  arrowController.reverse();
                }
              }
            }
            if (stillNeedsIndenting) {
              widget.todo.changeIndent(widget.todo.indented + 1);

              context
                  .read<FutureTodoBloc>()
                  .add(FutureTodoUpdate(event: widget.todo));
              stillNeedsIndenting = false;
            }
          },
        ),
        BlocListener<FutureTodoBloc, FutureTodoState>(
            listener: (context, state) {
          if (state is FutureTodoRefreshedFromDelete &&
              state.deletedTreeIndexes.contains(widget.todo.index)) {
            animController.forward();
          } else {
            // After taking away indents, if expandable, set the arrow in the right position
            if (widget.expandable) {
              arrowController.forward();
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
              context
                  .read<FutureTodoBloc>()
                  .add(FutureTodoDelete(event: widget.todo));
            },
            child: GestureDetector(
              // onLongPress overrides the dragging from ReorderableListView
              onLongPress: () {},
              onTap: () {
                if (widget.expandable) {
                  if (arrowController.status == AnimationStatus.dismissed ||
                      arrowController.status == AnimationStatus.reverse) {
                    arrowController.forward();
                    context.read<ExpandableBloc>().add(ExpandableUpdate(
                        context.read<FutureTodoBloc>().state.futureList,
                        widget.todo.index,
                        true));
                  } else {
                    arrowController.reverse();
                    context.read<ExpandableBloc>().add(ExpandableUpdate(
                        context.read<FutureTodoBloc>().state.futureList,
                        widget.todo.index,
                        false));
                  }
                }
              },
              onDoubleTap: () {
                if (widget.todo.indented > 0 &&
                    context
                            .read<FutureTodoBloc>()
                            .state
                            .futureList[widget.todo.index + 1]
                            .indented <=
                        widget.todo.indented) {
                  widget.todo.changeIndent(widget.todo.indented - 1);
                  context
                      .read<FutureTodoBloc>()
                      .add(FutureTodoUpdate(event: widget.todo));
                }
              },
              child: BlocBuilder<ToggleTodoEditingCubit, bool>(
                  builder: (context, editingState) {
                return SizedBox(
                  height: Centre.safeBlockVertical * (editingState ? 8.5 : 6),
                  width: Centre.safeBlockHorizontal * 90,
                  child: Row(children: [
                    // Indents
                    SizedBox(
                        width: Centre.safeBlockHorizontal *
                            (3 + 7 * widget.todo.indented)),
                    GestureDetector(
                        onDoubleTap: () {
                          if (widget.todo.indented < 4 &&
                              widget.todo.index != 0 &&
                              context
                                      .read<FutureTodoBloc>()
                                      .state
                                      .futureList[widget.todo.index - 1]
                                      .indented >=
                                  widget.todo.indented) {
                            // Once this finishes, update the indentation
                            stillNeedsIndenting = true;
                            context.read<ExpandableBloc>().add(ExpandableUpdate(
                                context.read<FutureTodoBloc>().state.futureList,
                                widget.todo.index,
                                true));
                          }
                        },
                        child: widget.expandable
                            ? RotationTransition(
                                turns: Tween(begin: 0.0, end: 0.25)
                                    .animate(arrowController),
                                child: Icon(Icons.arrow_right_rounded,
                                    color: Centre.textColor,
                                    size: Centre.safeBlockHorizontal * 10),
                              )
                            : Text(
                                ' \u2022 ',
                                style: Centre.todoSemiTitle.copyWith(
                                    fontSize: Centre.safeBlockHorizontal * 10),
                              )),
                    Expanded(
                      child: !editingState
                          ? Text(widget.todo.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Centre.dialogText)
                          : BlocBuilder<TodoTextEditingCubit, int?>(
                              builder: (context, indexEditing) {
                              return (indexEditing ?? -1) == widget.todo.index
                                  ? TextFormField(
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.amber),
                                        ),
                                      ),
                                      controller: widget.textController,
                                      maxLengthEnforcement:
                                          MaxLengthEnforcement.enforced,
                                      maxLength: 50,
                                      focusNode: widget.focusNode,
                                      style: Centre.dialogText,
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        context
                                            .read<TodoTextEditingCubit>()
                                            .update(widget.todo.index);
                                        widget.textController.text =
                                            widget.todo.text;
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
                              padding: EdgeInsets.only(
                                  left: Centre.safeBlockHorizontal * 2),
                              child: Icon(Icons.drag_handle_rounded,
                                  size: Centre.safeBlockHorizontal * 6),
                            ))
                        : BlocBuilder<TodoTextEditingCubit, int?>(
                            builder: (context, indexEditing) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                (indexEditing ?? -1) == widget.todo.index
                                    ? GestureDetector(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            border: Border.all(
                                                color: Centre.secondaryColor),
                                          ),
                                          margin: EdgeInsets.symmetric(
                                              horizontal:
                                                  Centre.safeBlockHorizontal *
                                                      2),
                                          padding: EdgeInsets.all(
                                              Centre.safeBlockHorizontal * 1.5),
                                          child: Icon(
                                            Icons.check,
                                            color: Centre.secondaryColor,
                                          ),
                                        ))
                                    : GestureDetector(
                                        onTap: () {
                                          widget.textController.clear();
                                          arrowController.forward();
                                          context.read<ExpandableBloc>().add(
                                              ExpandableUpdate(
                                                  context
                                                      .read<FutureTodoBloc>()
                                                      .state
                                                      .futureList,
                                                  widget.todo.index,
                                                  true));
                                          context
                                              .read<TodoTileAddCubit>()
                                              .update([
                                            widget.todo.index + 1,
                                            widget.todo.indented + 1,
                                            0
                                          ]);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            border: Border.all(
                                                color: Centre.secondaryColor),
                                          ),
                                          margin: EdgeInsets.symmetric(
                                              horizontal:
                                                  Centre.safeBlockHorizontal *
                                                      2),
                                          padding: EdgeInsets.all(
                                              Centre.safeBlockHorizontal * 1.5),
                                          child: Icon(
                                            Icons.add,
                                            color: Centre.secondaryColor,
                                            size:
                                                Centre.safeBlockHorizontal * 5,
                                          ),
                                        )),
                                GestureDetector(
                                    onTap: () {
                                      deleted = true;
                                      animController.reverse();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(40),
                                        border: Border.all(color: Centre.red),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                          horizontal:
                                              Centre.safeBlockHorizontal * 2),
                                      padding: EdgeInsets.all(
                                          Centre.safeBlockHorizontal * 1.5),
                                      child: Icon(
                                        Icons.delete,
                                        size: Centre.safeBlockHorizontal * 5,
                                        color: Centre.red,
                                      ),
                                    )),
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
