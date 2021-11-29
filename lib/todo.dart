import 'package:flutter/material.dart';

class Todo {
  String? title;
  String? content;
  int? active;
  int? id;

  Todo({this.title, this.content, this.active, this.id});

  //sqflite패키지는 데이터를 Map형태로 다룸,따라서 데이터 구조를 Map형태로 반환하는 함수를 정의해 활용한다
  //toMap함수는 데이터를 Map형태로 반환
  Map<String, dynamic> toMap() {
    return {
      'id' : id,  //순번
      'title' : title,  //제목
      'content' : content,  //내용
      'active' : active,  //완료 여부 sqlite는 Bool이 없음 따라서 int로 판단하게 함 0,1사용
    };
  }
}