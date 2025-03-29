import 'package:darg_and_drop_demo/util/drag_manager.dart';
import 'package:darg_and_drop_demo/util/dropable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraggableItem extends StatelessWidget {
  final DraggedItem item;
  final void Function()? onRemove;

  const DraggableItem({
    super.key,
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final DragManager dragManager = context.watch<DragManager>();
    return Draggable<DraggableItem>(
      key: key,
      maxSimultaneousDrags: 1,
      data: this,
      feedback: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 700, // Limits width to 700
        ),
        child: Material(
          color: Colors.transparent, // Ensure no white background
          child: item.child,
        ),
      ),
      onDragStarted: () {
        print("ItemStartDrag");
        dragManager.startDrag(this);
      },
      onDragEnd: (details) {
        print("ItemEndDrag");
        dragManager.endDrag(false); // Assume not dropped until confirmed
      },
      onDraggableCanceled: (velocity, offset) {
        print("ItemDragCanceled");
        dragManager.endDrag(false);
      },
      onDragCompleted: () {
        print("ItemDragCompleted");
        dragManager.endDrag(false);
      },
      child: item.child,
    );
  }
}
