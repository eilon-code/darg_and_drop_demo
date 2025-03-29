import 'package:darg_and_drop_demo/util/dragable_item.dart';
import 'package:darg_and_drop_demo/util/dropable_list.dart';
import 'package:flutter/material.dart';

class DragManager extends ChangeNotifier {
  DraggableItem? draggedItem;
  DropList? originalList;
  int? originalIndex;
  DropList? currentList;
  DraggableItem? shadowItem;

  Widget cloneWidgetWithNewKey(Widget widget) {
    if (widget is DropList) {
      return DropList(
        items: widget.items.map((draggableItem) => DraggableItem(
              item: DraggedItem(
                child: cloneWidgetWithNewKey(draggableItem.item.child),
                parentList: draggableItem.item.parentList,
              ),
              itemKey: GlobalKey(), // Ensure a fresh key
            )).toList(),
        parentDetails: widget.parentDetails,
      );
    } else if (widget is Opacity) {
      return Opacity(
        opacity: widget.opacity,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else if (widget is Container) {
      return Container(
        key: GlobalKey(),
        decoration: widget.decoration,
        padding: widget.padding,
        margin: widget.margin,
        alignment: widget.alignment,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else if (widget is GestureDetector) {
      return GestureDetector(
        key: GlobalKey(),
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onPanStart: widget.onPanStart,
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: widget.onPanEnd,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else if (widget is Material) {
      return Material(
        key: GlobalKey(),
        type: widget.type,
        elevation: widget.elevation,
        color: widget.color,
        shadowColor: widget.shadowColor,
        surfaceTintColor: widget.surfaceTintColor,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else if (widget is Text) {
      return Text(
        widget.data ?? "",
        key: ValueKey(widget.data), // Use ValueKey instead of GlobalKey
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    } else if (widget is Row) {
      return Row(
        key: GlobalKey(),
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: widget.children.map(cloneWidgetWithNewKey).toList(),
      );
    } else if (widget is Column) {
      return Column(
        key: GlobalKey(),
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: widget.children.map(cloneWidgetWithNewKey).toList(),
      );
    } else if (widget is Stack) {
      return Stack(
        key: GlobalKey(),
        alignment: widget.alignment,
        children: widget.children.map(cloneWidgetWithNewKey).toList(),
      );
    } else if (widget is Padding) {
      return Padding(
        key: GlobalKey(),
        padding: widget.padding,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else if (widget is Align) {
      return Align(
        key: GlobalKey(),
        alignment: widget.alignment,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else if (widget is SizedBox) {
      return SizedBox(
        key: GlobalKey(),
        width: widget.width,
        height: widget.height,
        child: widget.child != null ? cloneWidgetWithNewKey(widget.child!) : null,
      );
    } else {
      return Builder(
        builder: (context) => widget, // Avoid unnecessary GlobalKey wrapping
      );
    }
  }

  void startDrag(DraggableItem item, DropList fromList) {
    print("startDrag");
    draggedItem = item;
    originalList = fromList;
    originalIndex = fromList.items.indexOf(item);
    bool sucess = fromList.items.remove(item); // Remove from original list
    item.onRemove?.call();
    if (!sucess) {
      originalIndex = null;
      originalList = null;
    }
    print("Deleted: $sucess");
    currentList = null;
    shadowItem = null;
  }

  void updateShadow(DropList targetList, int index) {
    if (currentList != null) {
      removeShadow(currentList!, notify: false);
    }
    if (draggedItem == null) return;
    shadowItem ??= DraggableItem(
      item: DraggedItem(
        isShadow: true,
        parentList: targetList,
        child: Opacity(
          opacity: 0.3,
          child: cloneWidgetWithNewKey(draggedItem!.item.child),
        ),
      ),
      itemKey: GlobalKey(
        debugLabel: "shadow"
      ),
    );
    currentList = targetList;
    targetList.items.insert(index, shadowItem!);
    // print("IS shadow: ${shadowItem?.item.isItemShadow()}");
    // int i = 0;
    // for (var draggedItem in targetList.items) {
    //   print("Index: $i, IS shadow: ${draggedItem.item.isItemShadow()}");
    //   i++;
    // }
    notifyListeners();
  }

  void removeShadow(DropList list, {bool notify = true}) {
    print("RemoveShadow");
    list.items.remove(shadowItem);
    shadowItem = null;
    currentList = null;
    if (notify) notifyListeners();
  }

  void endDrag(bool droppedInList) {
    print("EndDrag");
    if (!droppedInList) {
      if (originalList != null) {
        draggedItem!.item.parentList = originalList!;
        originalList!.items.insert(originalIndex!, draggedItem!);
      }
    } else if (currentList != null) {
      // shadowItem?.item.child = draggedItem!.item.child;
      int index = shadowItem?.item.parentList.items.indexOf(shadowItem!) ?? -1;
      if (index != -1) {
        shadowItem?.item.parentList.items.remove(shadowItem);
        shadowItem?.item.parentList.items.insert(index, draggedItem!);
        shadowItem?.item.parentList.onInsert?.call(index, draggedItem!);
      }
    }
    originalIndex = null;
    draggedItem = null;
    shadowItem = null;
    currentList = null;
    originalList = null;
    notifyListeners();
  }
}