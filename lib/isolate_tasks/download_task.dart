import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../worker/worker.dart';

final userAgent = 'FileString/3.17 (iOS; 12.1 iPhone) iPad/Stag';

class DownloadTask implements FileTask<Future<bool>> {
  final Dio dio;
  final String url;
  final String savePath;

  DownloadTask({@required this.dio, @required this.url, this.savePath, this.taskId});

  @override
  Future<bool> execute() {
    print('exetucte...');
    return _doExecute();
  }

  Future<bool> _doExecute() async {
    Completer<bool> completer = Completer();

    try {

      Response response = await dio.download(url, savePath,
          onReceiveProgress: taskProgressCallback);

//      Response response = await dio.download(url, savePath,
//          onReceiveProgress: (int count, int total) {
//        print('isolate: $count - $total');
//      });

      print('DownloadTask is DONE result=$response');
      completer.complete(true);
    } catch (e) {
      print('DownloadTask error: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  ActionType actionType = ActionType.DOWNLOAD;

  @override
  String taskId;

  @override
  var taskProgressCallback;

  @override
  void handleCancel(String taskId) {
    // TODO: implement handleCancel
  }
}
