import 'package:flutter/material.dart';
//데이터 베이스 함수를 사용하는데 필요한 패키지
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


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
        '/' : (context) => DatabaseApp(database),  //각 클래스를 호출하면서 database객체를 전달,
        '/add' : (context) => AddTodoApp(database),  //이렇게 하면 한 곳에서 데이터베이스를 호출하고 페이지별로 한 번 호출된 데이터베이스를 사용할 수 있음
      },
    );
  }

  //데이터베이스를 생성하는 initDatabase()함수를 만듦
  //initDatabase()함수는 데이터베이스를 열어서 반환해
  Future<Database> initDatabase() async {
    return openDatabase(
      //어느 경로에 어떤 파일 이름으로 데이터베이스를 만들 건지 정함
      join(await getDatabasesPath(), 'todo_database.db'),  //getDatabasesPath함수가 반환하는 경로에 todo_database.db라는 파일로 저장되어 있으며 이 파일을 불러와서 반환함
      //만약 todo_database.db파일에 테이블이 없으면 onCreate를 이용해 새로운 데이터베이스 테이블을 만듦
      onCreate: (db, version) {
        return db.execute(
        "CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, "  //todos가 테이블 이름
            "title TEXT, content TEXT, active INTEGER)",
        );
      },
      version: 1,
    );
  }
}


//DatabaseApp 클래스에는 데이터베이스에서 가져온 할 일 목록을 보여주는 UI구현
class DatabaseApp extends StatefulWidget {
  final Future<Database> db;  //클래스 호출할 때 database객체를 전달했으니
  DatabaseApp(this.db);

  @override
  State<StatefulWidget> createState() => _DatabaseApp();
}

class _DatabaseApp extends State<DatabaseApp> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Database Example'),),
      body: Container(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final todo = await Navigator.of(context).pushNamed('/add');
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

