import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../worker/worker.dart';

///Task for download file in isolate
class DownloadTask implements FileTask<Future<bool>> {
  final Dio dio;
  final String url;
  final String savePath;
  CancelToken cancelToken;

  DownloadTask(
      {@required this.dio, @required this.url, this.savePath, this.taskId});

  @override
  Future<bool> execute() {
    return _doExecute();
  }

  Future<bool> _doExecute() async {
    cancelToken = CancelToken();
    var completer = Completer<bool>();

    try {
      final response = await dio.download(url, savePath,
          cancelToken: cancelToken, onReceiveProgress: taskProgressCallback);

      print('DownloadTask success: $response');
      completer.complete(true);
    } catch (e) {
      print('DownloadTask error: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  ActionType actionType = ActionType.download;

  @override
  String taskId;

  @override
  var taskProgressCallback;

  @override
  void handleCancel(String taskId) {
    cancelToken?.cancel('Cancel download $taskId');
  }
}
