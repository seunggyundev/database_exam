import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';
import 'todo.dart';

//할 일 목록에 데이터를 입력하는 화면
//AddTodoApp클래스에서도 데이터베이스를 사용할 수 있게 db를 만들어 줌
class AddTodoApp extends StatefulWidget {
  final Future<Database> db;

  AddTodoApp(this.db);

  @override
  State<StatefulWidget> createState() => _AddTodoApp();
}

class _AddTodoApp extends State<AddTodoApp> {
  TextEditingController? titleController;
  TextEditingController? contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    contentController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo 추가'),
      ),
      body: Container(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: '제목'),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: contentController,
                  decoration: InputDecoration(labelText: '할 일'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Todo todo = Todo(
                    title: titleController!.value.text,
                    content: contentController!.value.text,
                    active: 0
                  );
                  Navigator.of(context).pop(todo);  //버튼을 눌렀을 때 pop()함수를 호출하면서 데이터를 메인에 전달함
                },
                child: Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
