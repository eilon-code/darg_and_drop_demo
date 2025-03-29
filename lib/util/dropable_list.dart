import 'package:darg_and_drop_demo/util/drag_manager.dart';
import 'package:darg_and_drop_demo/util/dragable_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraggedItem {
  final Widget child;
  DropList parentList;

  DraggedItem({
    required this.parentList,
    required this.child,
  });

  Widget get shadow => _deepCopyWithOpacity(child);
  static const double decayCoefficient = 0.5;

  Widget _deepCopyWithOpacity(Widget widget) {
    if (widget is DropList) {
      return DropList(
        isShadow: true,
        items: widget.items,
        parentDetails: widget.parentDetails,
      );
    } else if (widget is DraggableItem) {
      return widget.item.shadow;
    } else if (widget is Opacity) {
      return Opacity(
        opacity: widget.opacity,
        child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
      );
    } else if (widget is Container) {
      return Opacity(
        opacity: decayCoefficient,
        child: Container(
          decoration: widget.decoration,
          padding: widget.padding,
          margin: widget.margin,
          alignment: widget.alignment,
          child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
        ),
      );
    } else if (widget is GestureDetector) {
      return GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onPanStart: widget.onPanStart,
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: widget.onPanEnd,
        child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
      );
    } else if (widget is Material) {
      return Opacity(
        opacity: decayCoefficient,
        child: Material(
          type: widget.type,
          elevation: widget.elevation,
          color: widget.color,
          shadowColor: widget.shadowColor,
          surfaceTintColor: widget.surfaceTintColor,
          child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
        ),
      );
    } else if (widget is Text) {
      return Opacity(
        opacity: decayCoefficient,
        child: Text(
          widget.data ?? "",
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        ),
      );
    } else if (widget is Row) {
      return Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: widget.children.map(_deepCopyWithOpacity).toList(),
      );
    } else if (widget is Column) {
      return Column(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: widget.children.map(_deepCopyWithOpacity).toList(),
      );
    } else if (widget is Stack) {
      return Stack(
        alignment: widget.alignment,
        children: widget.children.map(_deepCopyWithOpacity).toList(),
      );
    } else if (widget is Padding) {
      return Padding(
        padding: widget.padding,
        child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
      );
    } else if (widget is Align) {
      return Align(
        alignment: widget.alignment,
        child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
      );
    } else if (widget is SizedBox) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.child != null ? _deepCopyWithOpacity(widget.child!) : null,
      );
    } else {
      return Builder(
        builder: (context) => widget, // Avoid unnecessary GlobalKey wrapping
      );
    }
  }
}

class DropList extends StatefulWidget {
  final List<DraggedItem> items;
  final DraggedItem? parentDetails;
  final Function(int index, DraggedItem item)? onInsert;
  final void Function(DraggedItem item)? onRemove;
  final bool? isShadow;

  const DropList({
    super.key,
    required this.items,
    this.parentDetails,
    this.onInsert,
    this.isShadow,
    this.onRemove,
  });

  @override
  State<DropList> createState() => _DropListState();
}

class _DropListState extends State<DropList> {
  // Finds the closest index where the shadow should be placed
  double _smoothIndex = 0;
  int? _lastIndex;

  List<Widget> children = [];

  int _findInsertIndex(Offset dragPosition) {
    if (widget.items.isEmpty) {
      return 0; // Always insert at index 0 if the list is empty
    }

    double relativeY = dragPosition.dy;
    double minDistance = double.infinity;
    int resultIndex = 0;
    for (int i = 0; i < children.length; i++) {
      final Widget currentItem = children[i];
      final GlobalKey? key = currentItem.key as GlobalKey?;
      final RenderBox? itemBox = key?.currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) continue;

      final Offset itemOffset = itemBox.localToGlobal(Offset.zero);
      final double itemStartY = itemOffset.dy;
      final double itemEndY = itemOffset.dy + itemBox.size.height;
      final double itemCenterY = (itemStartY + itemEndY) / 2;

      double distance = (relativeY - itemCenterY).abs();
      if (distance < minDistance) {
        minDistance = distance;
        resultIndex = i;
      }
    }

    double smoothingFactor = 0.7; // Increase for more stability, decrease for responsiveness
    _smoothIndex = (_smoothIndex * smoothingFactor) + (resultIndex * (1 - smoothingFactor));
    _lastIndex = _smoothIndex.round();

    return _lastIndex!;
  }

  @override
  Widget build(BuildContext context) {
    final DragManager dragManager = context.watch<DragManager>();
    children.clear();
    bool shadowList = widget.isShadow == true;
    for (DraggedItem item in widget.items) {
      bool shadowItem = dragManager.isDraggedItem(item);
      if (shadowList || shadowItem) {
        children.add(item.shadow);
      } else {
        children.add(
          DraggableItem(
            item: item,
            onRemove: () {
              setState(() {
                widget.items.remove(item);
                widget.onRemove?.call(item);
              });
            },
          ),
        );
      }
    }
    print("ShadowList: ${shadowList}");
    if (shadowList) {
      return Column(
        children: widget.items.isNotEmpty ? children : [
          const SizedBox(
            width: 70,
            height: 30,
            child: Text(
              "Drop Here",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      );
    }
    return DragTarget<DraggableItem>(
      onWillAcceptWithDetails: (item) {
        print("ListUpdateShadow");
        int index = _findInsertIndex(item.offset);
        dragManager.updateShadow(widget, index);
        return true;
      },
      onMove: (details) {
        print("ListUpdateShadow");
        int index = _findInsertIndex(details.offset);
        dragManager.updateShadow(widget, index);
      },
      onLeave: (_) {
        print("ListRemoveShadow");
        dragManager.removeShadow(widget);
      },
      onAcceptWithDetails: (item) {
        print("ListEndDrag");
        dragManager.endDrag(true); // Successfully dropped
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: widget.items.isNotEmpty ? children : [
            const SizedBox(
              width: 70,
              height: 30,
              child: Text(
                "Drop Here",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        );
      },
    );
  }
}