import 'package:flutter/material.dart';

//데이터 베이스 함수를 사용하는데 필요한 패키지
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'todo.dart';
import 'addTodo.dart';
import 'clearList.dart';

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
      //새로운 페이지를 만들면 routes에 경로 추가!
      initialRoute: '/',
      routes: {
        //각 클래스를 호출하면서 database객체를 전달
        //이렇게 하면 한 곳에서 데이터베이스를 호출하고 페이지별로 한 번 호출된 데이터베이스를 사용할 수 있음
        '/': (context) => DatabaseApp(database),
        '/add': (context) => AddTodoApp(database),
        '/clear': (context) => ClearListApp(database),
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
  Future<List<Todo>>?
      todoList; //Future로 선언할 할 일 목록은 계속 값이 변하므로 따로 변수를 선언해 initState()함수에서 호출

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
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await Navigator.of(context).pushNamed('/clear');
              setState(() {
                todoList = getTodos();
              });
            },
            child: Text(
              '완료한 일',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
                case ConnectionState
                    .done: //상태가 done이 되면 가져온 데이터를 바탕으로 ListView.builder를 이용해 화면에 표시함
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        Todo todo = (snapshot.data as List<Todo>)[index];
                        //Card위젯이 칸막이를 만들고 그 안에서 위젯을 자유롭게 꾸몄다면
                        //ListTile은 title,subtitle,leading,trailing옵션으로 위젯의 위치를 지정할 수 있음
                        return ListTile(
                          onTap: () async {
                            TextEditingController controller =
                                TextEditingController(text: todo.content);

                            //showDialog()함수로 비동기로 알림 창을 호출,실제 알림창은 AlertDialog로 만듦
                            Todo result = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('${todo.id} : ${todo.title}'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.text,
                                  ),
                                  actions: [
                                    //반환한 데이터는 result변수에 할당되고 _updateTodo()에 들어감
                                    //'예'를 고르면 todo값을 변경한 후 pop()함수로 데이터를 전달
                                    TextButton(
                                      onPressed: () {
                                        todo.active == 1
                                            ? todo.active = 0
                                            : todo.active = 1;
                                        todo.content = controller.value.text;
                                        Navigator.of(context).pop(todo);
                                      },
                                      child: Text('예'),
                                    ),
                                    //'아니오'를 고르면 알림창을 종료한 후 pop()함수로 데이터를 전달
                                    TextButton(
                                      onPressed: () {
                                        todo.active == 1
                                            ? todo.active = 0
                                            : todo.active = 1;
                                        todo.content = controller.value.text;
                                        Navigator.of(context).pop(todo);
                                      },
                                      child: Text('아니요'),
                                    ),
                                  ],
                                );
                              },
                            );
                            _updateTodo(result);
                          },
                          title: Text(
                            todo.title!,
                            style: TextStyle(fontSize: 20),
                          ),
                          subtitle: Container(
                            child: Column(
                              children: <Widget>[
                                Text(todo.content!),
                                Text(
                                    '체크 : ${todo.active == 1 ? 'true' : 'false'}'),
                                Container(
                                  height: 1,
                                  color: Colors.blueGrey,
                                ),
                              ],
                            ),
                          ),
                          //onLongPress이벤트가 발샹하면 알림창이 뜨고 '예'를 누르면 가져온 할 일 아이템을 _deleteTodo()함수에 전달해 삭제한
                          onLongPress: () async {
                            Todo result = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('${todo.id} : ${todo.title}'),
                                    content: Text('${todo.content}를 삭제하시겠습니까?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(todo);
                                        },
                                        child: Text('예'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('아니오'),
                                      ),
                                    ],
                                  );
                                });
                            _deleteTodo(result);
                          },
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
      floatingActionButton: Column(
        children: <Widget> [
          FloatingActionButton(
            onPressed: () async {
              final todo = await Navigator.of(context).pushNamed('/add');
              if (todo != null) {
                _insertTodo(todo as Todo);
              }
            },
            heroTag: null,  //heroTag를 null로 설정하지 않으면 오류가 발생! 이유: 페이지가 넘어가는 위젯에 받아줄 태그가 없어서 오류 발생
            child: Icon(Icons.add),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton(onPressed: () async {
            _allUpdate();
          },
            heroTag: null,
            child: Icon(Icons.update),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      ),
    );
  }

  void _allUpdate() async {
    final Database database = await widget.db;
    //데이터베이스에서 데이터를 수정할 때는 update문을 이용
    await database.rawUpdate('update todos set active = 1 where active = 0');  //이 질의문은 todos테이블에서 active가 0인 데이터를 모두 찾아서 active를 1로 변경(set)한다
    setState(() {
      todoList = getTodos();
    });
  }

  void _insertTodo(Todo todo) async {
    // * widget.을 이용하면 현재 State 상위에 있는 StatefulWidget에 있는 변수를 사용할 수 있음
    final Database database = await widget.db; //widget.db를 이용해 database객체 선언
    await database.insert('todos', todo.toMap(),
        //'todos'는 테이블을 생성할 때 명시한 테이불 이름, todo.toMap()함수는 Todo클래스를 Map형태로 바꿔줌
        conflictAlgorithm: ConflictAlgorithm
            .replace); //충돌이 발생할 때를 대비한 것, 데이터 입력과정에서 충돌이 발생할 경우 새 데이터로 교체하고자 replace선언
    //새로운 데이터를 입력했을 때 화면에 나타나게끔 갱신하는 코드
    setState(() {
      todoList = getTodos();
    });
  }

  //List<Map>은 value 값이 Map형태인 List타입
  //(데이터베이스에서 가져온 데이터로 데이터베이스 인스턴스를 생성한 후 그걸 가지고 데이터 수정하고 투두리스트 리턴하는 형)
  Future<List<Todo>> getTodos() async {
    final Database database = await widget.db; //widget.db를 가져와서 database선언
    final List<Map<String, dynamic>> maps = await database
        .query('todos'); //.query()함수는 테이블 전체를 불러옴, 테이블을 가져와서 maps목록에 넣음
    //위의 maps목록을 활용해 List.generate()함수에서 할 일 목록에 표시할 각 아이템을 만듦
    return List.generate(maps.length, (i) {
      int active = maps[i]['active'] == 1
          ? 1
          : 0; //SQLite는 bool형이 없으므로 Integer를 이용해 0과 1로 표시, 0은 false 1은 true
      //active변수를 선언해 Todo에 넣어서 반환
      return Todo(
        title: maps[i]['title'].toString(),
        content: maps[i]['content'].toString(),
        active: active,
        id: maps[i]['id'],
      );
    });
  }

  void _updateTodo(Todo todo) async {
    final Database database = await widget.db;
    //데이터베이스에서 데이터를 수정할 때는 database.update()함수를 사용함
    await database.update(
      'todos',
      todo.toMap(),
      //매개변수 todo로 전달받은 할 일 데이터의 id값을 whereArgs에 설정하고 이 값으로 데이터베이스에서 수정할 데이터를 찾을 수 있도록 where에 'id = ?'를 입력함, ?는 whereArgs에 입력한 값에 대응함
      //id값은 기본 키로 설정했으므로 중복되지 않고 유일함, 따라서 id값으로 수정할 데이터를 찾는다
      where: 'id = ?',
      //where는 어떤 데이터를 수정할 것인지 나타내는 것, 이를 잘 설정해야 다른 데이터가 수정되지 않는다
      whereArgs: [todo.id],
    );
    setState(() {
      todoList = getTodos();
    });
  }

  //매개변수로 전달받은 할 일 아이템을 데이터베이스에서 삭제하는 함수
  void _deleteTodo(Todo todo) async {
    final Database database = await widget.db;
    //데이터베이스에서 데이터를 삭제하려면 database.delete()함수를 호출한다
    //이때 데이터를 수정할 때와 마찬가지로 id값으로 찾아서 해당 데이터를 지운다
    await database.delete('todos', where: 'id = ?', whereArgs: [todo.id]);
    setState(() {
      //삭제 후 getTodos()함수를 호출해 현재 목록을 새로 고침 한다
      todoList = getTodos();
    });
  }
}
