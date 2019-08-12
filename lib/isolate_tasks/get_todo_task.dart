import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../todo_model.dart';
import '../worker/worker.dart';

class GetTodoTask implements Task<Future<TodoModel>> {
  final Dio dio;
  final int id;

  GetTodoTask({@required this.dio, @required this.id});

  @override
  Future<TodoModel> execute() {
    return _doExecute();
  }

  Future<TodoModel> _doExecute() async {
    var completer = Completer<TodoModel>();

    try {
      var response = await dio.get<Map<String, dynamic>>(
          'https://jsonplaceholder.typicode.com/todos/$id');
      var todoModel = TodoModel.fromJson(response.data);

      print('GetTodoTask is DONE result=$todoModel');
      completer.complete(todoModel);
    } catch (e) {
      print('GetTodoTask error: $e');
      completer.completeError(e);
    }

    return completer.future;
  }
}
