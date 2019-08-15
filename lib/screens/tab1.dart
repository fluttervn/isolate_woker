import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iso/iso.dart';

import '../todo_model.dart';

class Tab1 extends StatefulWidget {
  @override
  _Tab1State createState() => _Tab1State();
}

class _Tab1State extends State<Tab1> {
  TodoModel todoModel;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    var value = 'No data';
    if (loading) {
      value = 'Loading...';
    } else {
      if (todoModel != null) {
        value = todoModel.toString();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Tab1'),
      ),
      body: Column(
        children: <Widget>[
          RaisedButton(
            child: Text('Get Todo'),
            onPressed: getTodoData,
          ),
          Divider(),
          Text(value)
        ],
      ),
    );
  }

//  void getTodoData() async {
//    setState(() {
//      loading = true;
//    });
//    final dio = Dio();
//    var todoTask = GetTodoTask(dio: dio, id: 1);
//    final worker = Worker(poolSize: 2);
//    todoModel = (await worker.handle(todoTask)) as TodoModel;
//    setState(() {
//      loading = false;
//    });
//  }

  void getTodoData() async {
    setState(() {
      loading = true;
    });

    final iso = Iso(run,
        onDataOut: (dynamic data) => setState(() {
              todoModel = data as TodoModel;
              loading = false;
            }));
    iso.run();
    await iso.onCanReceive;
    // now we can send messages to the isolate
    iso.send([1, Dio()]);
  }

  static void run(IsoRunner iso) async {
    iso.receive();
    // listen to the data coming in
    iso.dataIn.listen((dynamic data) async {
      if (data is List<dynamic>) {
        var dio = data.last as Dio;
        var id = data.first as int;
        var response = await dio.get<Map<String, dynamic>>(
            'https://jsonplaceholder.typicode.com/todos/$id');
        var todoModel = TodoModel.fromJson(response.data);
        // send into the main thread
        print('send: $todoModel');
        iso.send(todoModel);
      }
    });
  }
}
