import 'package:sqflite/sqlite_api.dart';
import 'package:flutter/material.dart';
import 'todo.dart';

//검색질의 예시 페이

class ClearListApp extends StatefulWidget {
  Future<Database> database;

  ClearListApp(this.database);

  @override
  State<StatefulWidget> createState() => _ClearListApp();
}

class _ClearListApp extends State<ClearListApp> {
  Future<List<Todo>>? clearList;

  @override
  void initState() {
    super.initState();
    clearList = getClearList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('완료한 일'),
      ),
      body: Container(
        child: Center(
          //목록을 Future로 선언했으므로 FutureBuilder를 이용해서 화면에 표시할 위젯을 배치
          //FutureBuilder위젯은 서버에서 데이터를 받거나 파일에 데이터를 가져올 때 사용함
          child: FutureBuilder(
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return CircularProgressIndicator();
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                case ConnectionState.active:
                  return CircularProgressIndicator();
                case ConnectionState.done:
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        Todo todo = (snapshot.data as List<Todo>)[index];
                        return ListTile(
                          title: Text(
                            todo.title!,
                            style: TextStyle(fontSize: 20),
                          ),
                          subtitle: Container(
                            child: Column(
                              children: <Widget> [
                                Text(todo.content!),
                                Container(
                                  height: 1,
                                  color: Colors.blueGrey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      itemCount: (snapshot.data as List<Todo>).length,
                    );
                  }
              }
              return Text('no data');
            },
            future: clearList,
          ),
        ),
      ),
    );
  }

  //데이터베이스에서 완료한 일만 불러오는 getClearList()함수
  Future<List<Todo>> getClearList() async {
    final Database database = await widget.database;
    //getTodos()함수와는 다르게 .rawQuery()함수를 이용했음 getTodos()는 데이터를 Map형태로 만들어서 사용함(질의문을 직접 작성하지 않음)
    //.rawQuery()함수는 직접 SQL질의문을 전달해 데이터베이스에 질의함
    List<Map<String, dynamic>> maps = await database
        .rawQuery('select title, content, id from todos where active=1');
    //여기서 쓴 질의문은 데이터베이스에서 데이터를 검색할 때 이용하는 select이다
    //select구문은 from절에 지정한 테이블에서 where절에 지정한 조건에 맞는 데이터를 검색해서 select 뒤에 나열한 칼럼을 가져 온다

    return List.generate(
      maps.length,
      (i) {
        return Todo(
            title: maps[i]['title'].toString(),
            content: maps[i]['content'].toString(),
            id: maps[i]['id']);
      },
    );
  }
}
