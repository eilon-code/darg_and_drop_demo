import 'package:darg_and_drop_demo/util/drag_manager.dart';
import 'package:darg_and_drop_demo/util/dropable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DragAndDropExample extends StatefulWidget {
  const DragAndDropExample({super.key});

  @override
  State<DragAndDropExample> createState() => _DragAndDropExampleState();
}

class _DragAndDropExampleState extends State<DragAndDropExample> {
  late DropList listA;
  late DropList listB;
  late DropList listC;

  @override
  void initState() {
    super.initState();
    populateLists();
  }

  void populateLists() {
    listA = DropList(items: List.empty(growable: true));
    List<Widget> listBMembers = [
      SizedBox(
        height: 25,
        width: 100,
        child: const Text("List B Header"),
      ),
    ];
    List<Widget> listCMembers = [
      SizedBox(
        height: 25,
        width: 100,
        child: const Text("List C Header"),
      ),
    ];
    DraggedItem draggableBItem = DraggedItem(
      parentList: listA,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.lightBlue,
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: listBMembers,
          ),
        ),
      ),
    );
    DraggedItem draggableCItem = DraggedItem(
      parentList: listA,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.blueGrey,
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: listCMembers,
          ),
        ),
      ),
    );
    listB = DropList(items: List.empty(growable: true), parentDetails: draggableBItem);
    listC = DropList(items: List.empty(growable: true), parentDetails: draggableCItem);
    listBMembers.add(listB);
    listCMembers.add(listC);
    for (int index = 0; index < 3; index++) {
      listA.items.add(
        DraggedItem(
          parentList: listA,
          child: SizedBox(
            height: 25,
            width: 100,
            child: Text('A${index + 1}'),
          ),
        ),
      );
      listB.items.add(
        DraggedItem(
          parentList: listB,
          child: SizedBox(
            height: 25,
            width: 100,
            child: Text('B${index + 1}'),
          ),
        ),
      );
      listC.items.add(
        DraggedItem(
          parentList: listC,
          child: SizedBox(
            height: 25,
            width: 100,
            child: Text('C${index + 1}'),
          ),
        ),
      );
    }
    listA.items.add(
      draggableBItem,
    );
    listA.items.add(
      draggableCItem,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<DragManager>();
    return Scaffold(
      appBar: AppBar(title: const Text("Drag & Drop Demo")),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.amber
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 25,
                width: 100,
                child: const Text("List A"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50),
                child: listA,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: IconButton(
        icon: Icon(Icons.restart_alt_rounded),
        onPressed: () => setState(populateLists),
      )
    );
  }
}