import 'package:flutter/material.dart';

//데이터 베이스 함수를 사용하는데 필요한 패키지
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'todo.dart';
import 'addTodo.dart';

void main() {
  runApp(MyApp());
}

//앱이 시작할 때 MyApp클래스에서 데이터베이스를 만들어서 DatabaseApp클래스에 전달
//가장 먼저 생성되는 MyApp클래스에 데이터베이스를 선언해 다른 클래스에서도 접근할 수 있게 함
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future<Database> database = initDatabase();

    return MaterialApp(
      title: 'database exam',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //라우트를 이용하면 한 곳에서 모든 경로를 관리하여 편리하게 화면 이동 구현 가능
      initialRoute: '/',
      routes: {
        '/': (context) => DatabaseApp(database),
        //각 클래스를 호출하면서 database객체를 전달,
        '/add': (context) => AddTodoApp(database),
        //이렇게 하면 한 곳에서 데이터베이스를 호출하고 페이지별로 한 번 호출된 데이터베이스를 사용할 수 있음
      },
    );
  }

  //데이터베이스를 생성하는 initDatabase()함수를 만듦
  //initDatabase()함수는 데이터베이스를 열어서 반환해
  Future<Database> initDatabase() async {
    return openDatabase(
      //어느 경로에 어떤 파일 이름으로 데이터베이스를 만들 건지 정함
      join(await getDatabasesPath(), 'todo_database.db'),
      //getDatabasesPath함수가 반환하는 경로에 todo_database.db라는 파일로 저장되어 있으며 이 파일을 불러와서 반환함
      //만약 todo_database.db파일에 테이블이 없으면 onCreate를 이용해 새로운 데이터베이스 테이블을 만듦
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, " //todos가 테이블 이름
          "title TEXT, content TEXT, active INTEGER)",
        );
      },
      version: 1,
    );
  }
}

//DatabaseApp 클래스에는 데이터베이스에서 가져온 할 일 목록을 보여주는 UI구현
class DatabaseApp extends StatefulWidget {
  final Future<Database> db; //클래스 호출할 때 database객체를 전달했으니
  DatabaseApp(this.db);

  @override
  State<StatefulWidget> createState() => _DatabaseApp();
}

class _DatabaseApp extends State<DatabaseApp> {
  Future<List<Todo>>? todoList;  //Future로 선언할 할 일 목록은 계속 값이 변하므로 따로 변수를 선언해 initState()함수에서 호출

  @override
  void initState() {
    super.initState();
    todoList = getTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Example'),
      ),
      body: Container(
        child: Center(
          //할 일 목록을 Future로 선언했으므로 FutureBuilder를 이용해서 화면에 표시할 위젯을 배치
          //FutureBuilder위젯은 서버에서 데이터를 받거나 파일에 데이터를 가져올 때 사용함
          child: FutureBuilder(
            builder: (context, snapshot) {
              //데이터를 가져오는 동안 시간이 걸리기 때문에 그 사이에 표시할 위젯을 만들기 위해 switch문으로 상태확인함
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return CircularProgressIndicator();
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                case ConnectionState.active:
                  return CircularProgressIndicator();
                case ConnectionState.done:  //상태가 done이 되면 가져온 데이터를 바탕으로 ListView.builder를 이용해 화면에 표시함
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        Todo todo = (snapshot.data as List<Todo>)[index];
                        return Card(
                          child: Column(
                            children: <Widget>[
                              Text(todo.title!),
                              Text(todo.content!),
                              Text('${todo.active == 1 ? 'true' : 'false'}'),
                            ],
                          ),
                        );
                      },
                      itemCount: (snapshot.data as List<Todo>).length,
                    );
                  } else {
                    return Text('No data');
                  }
              }
              return CircularProgressIndicator();
            },
            future: todoList,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final todo = await Navigator.of(context).pushNamed('/add');
          if (todo != null) {
            _insertTodo(todo as Todo);
          }
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _insertTodo(Todo todo) async {
    // * widget.을 이용하면 현재 State 상위에 있는 StatefulWidget에 있는 변수를 사용할 수 있음
    final Database database = await widget.db; //widget.db를 이용해 database객체 선언
    await database.insert('todos', todo.toMap(),  //'todos'는 테이블을 생성할 때 명시한 테이불 이름, todo.toMap()함수는 Todo클래스를 Map형태로 바꿔줌
        conflictAlgorithm: ConflictAlgorithm.replace);  //충돌이 발생할 때를 대비한 것, 데이터 입력과정에서 충돌이 발생할 경우 새 데이터로 교체하고자 replace선언
    //새로운 데이터를 입력했을 때 화면에 나타나게끔 갱신하는 코드
    setState(() {
      todoList = getTodos();
    });
  }

  //List<Map>은 value 값이 Map형태인 List타입
  Future<List<Todo>> getTodos() async {
    final Database database = await widget.db;  //widget.db를 가져와서 database선언
    final List<Map<String, dynamic>> maps = await database.query('todos');  //.query()함수는 테이블 전체를 불러옴, 테이블을 가져와서 maps목록에 넣음
    //위의 maps목록을 활용해 List.generate()함수에서 할 일 목록에 표시할 각 아이템을 만듦
    return List.generate(
      maps.length,
        (i) {
        int active = maps[i]['active'] == 1 ? 1 : 0;  //SQLite는 bool형이 없으므로 Integer를 이용해 0과 1로 표시, 0은 false 1은 true
        //active변수를 선언해 Todo에 넣어서 반환
        return Todo(
          title: maps[i]['title'].toString(),
          content: maps[i]['content'].toString(),
          active: active,
          id: maps[i]['id'],
        );
        }
    );
  }
}
