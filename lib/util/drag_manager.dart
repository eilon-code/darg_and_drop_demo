import 'package:darg_and_drop_demo/util/dragable_item.dart';
import 'package:darg_and_drop_demo/util/dropable_list.dart';
import 'package:flutter/foundation.dart';

class DragManager extends ChangeNotifier {
  DraggableItem? _draggedWidget;
  DraggedItem? _draggedItem;
  DropList? originalList;
  int? originalIndex;
  DropList? currentList;

  bool isDraggedItem(DraggedItem item) {
    return item == _draggedItem;
  }

  void startDrag(DraggableItem draggedWidget) {
    _draggedWidget = draggedWidget;
    _draggedItem = draggedWidget.item;
    DropList? fromList = _draggedItem!.parentList;
    if (kDebugMode) {
      print("startDrag");
    }
    originalList = fromList;
    originalIndex = fromList.items.indexOf(_draggedItem!);
    bool sucess = fromList.items.remove(_draggedItem!); // Remove from original list
    _draggedWidget?.onRemove?.call();
    if (!sucess) {
      originalIndex = null;
      originalList = null;
    }
    if (kDebugMode) {
      print("Deleted: $sucess");
    }
    currentList = null;
  }

  void updateShadow(DropList targetList, int index) {
    if (currentList != null) {
      removeShadow(currentList!, notify: false);
    }
    if (_draggedItem == null) return;
    _draggedItem?.parentList = targetList;
    currentList = targetList;
    targetList.items.insert(index, _draggedItem!);
    notifyListeners();
  }

  void removeShadow(DropList list, {bool notify = true}) {
    if (kDebugMode) {
      print("RemoveShadow");
    }
    list.items.remove(_draggedItem);
    currentList = null;
    if (notify) notifyListeners();
  }

  void endDrag(bool droppedInList) {
    if (kDebugMode) {
      print("EndDrag");
    }
    if (originalList != null && !droppedInList) {
      _draggedItem!.parentList = originalList!;
      originalList!.items.insert(originalIndex!, _draggedItem!);
    }
    originalIndex = null;
    _draggedItem = null;
    currentList = null;
    originalList = null;
    notifyListeners();
  }
}
