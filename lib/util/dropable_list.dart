import 'package:darg_and_drop_demo/util/drag_manager.dart';
import 'package:darg_and_drop_demo/util/dragable_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraggedItem {
  DropList parentList;
  Widget child;
  bool? isShadow;

  DraggedItem({required this.parentList, required this.child, this.isShadow = false});

  bool isItemShadow() {
    return (isShadow ?? false) || parentList.isShadow();
  }
}

class DropList extends StatefulWidget {
  final List<DraggableItem> items;
  final DraggedItem? parentDetails;
  final Function(int index, DraggableItem item)? onInsert;

  const DropList({
    super.key,
    required this.items,
    this.parentDetails,
    this.onInsert,
  });
  
  bool isShadow() {
    return parentDetails?.isItemShadow() ?? false;
  }

  @override
  State<DropList> createState() => _DropListState();
}

class _DropListState extends State<DropList> {
  // Finds the closest index where the shadow should be placed
  double _smoothIndex = 0;
  int? _lastIndex;

  int _findInsertIndex(Offset dragPosition) {
    if (widget.items.isEmpty) {
      return 0; // Always insert at index 0 if the list is empty
    }

    double relativeY = dragPosition.dy;
    int bottomIndex = 0;
    int topIndex = widget.items.length - 1;
    int indexToCheck = bottomIndex + 1;
    bool up = true;

    // Step 1: Find a valid range while ignoring shadow items
    while (topIndex > bottomIndex + 1) {
      if (indexToCheck < bottomIndex || indexToCheck > topIndex) break;

      final DraggableItem currentItem = widget.items[indexToCheck];
      if (currentItem.item.isItemShadow()) {
        indexToCheck += up ? 1 : -1;
        continue;
      }

      final GlobalKey key = currentItem.itemKey;
      final RenderBox? itemBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) {
        indexToCheck += up ? 1 : -1;
        continue;
      }

      final Offset itemOffset = itemBox.localToGlobal(Offset.zero);
      final double itemStartY = itemOffset.dy;
      final double itemEndY = itemOffset.dy + itemBox.size.height;

      if (relativeY > itemEndY) {
        bottomIndex = indexToCheck + 1;
        indexToCheck++;
        up = true;
      } else if (relativeY < itemStartY) {
        topIndex = indexToCheck - 1;
        indexToCheck--;
        up = false;
      } else {
        bottomIndex = topIndex = indexToCheck;
      }
    }

    // Step 2: If we have a single candidate, return immediately
    if (topIndex == bottomIndex) {
      _smoothIndex = (_smoothIndex * 0.6) + (topIndex * 0.4);
      _lastIndex = _smoothIndex.round();
      return _lastIndex!;
    }

    // Step 3: Compute a weighted average of candidate indices
    double resultIndex = 0;
    double totalWeight = 0;
    double constant = 4;

    for (int i = bottomIndex; i <= topIndex; i++) {
      final DraggableItem currentItem = widget.items[i];
      if (currentItem.item.isItemShadow()) continue;

      final GlobalKey key = currentItem.itemKey;
      final RenderBox? itemBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) continue;

      final Offset itemOffset = itemBox.localToGlobal(Offset.zero);
      final double itemStartY = itemOffset.dy;
      final double itemEndY = itemOffset.dy + itemBox.size.height;
      final double itemCenterY = (itemStartY + itemEndY) / 2;

      double distance = (relativeY - itemCenterY).abs();
      
      // Sigmoid-like weight function for smoother priority
      double weight = (1 / ((1 + distance) * 0.04)) - 3;

      resultIndex += (i + constant) * weight;
      totalWeight += weight;
    }

    if (totalWeight > 0) {
      resultIndex /= totalWeight;
      resultIndex -= constant;
    }
    resultIndex = resultIndex < 0 ? 0 : resultIndex;

    // Step 4: Apply adaptive smoothing
    double smoothingFactor = 0.7; // Increase for more stability, decrease for responsiveness
    _smoothIndex = (_smoothIndex * smoothingFactor) + (resultIndex * (1 - smoothingFactor));
    _lastIndex = _smoothIndex.round();

    return _lastIndex!;
  }

  @override
  Widget build(BuildContext context) {
    final DragManager dragManager = context.watch<DragManager>();
    bool skipDrag = widget.isShadow();
    if (skipDrag) {
      return Column(
        children: widget.items.isNotEmpty ? widget.items : [
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
          children: widget.items.isNotEmpty ? widget.items : [
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