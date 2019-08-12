import 'package:flutter/foundation.dart';

import '../worker/worker.dart';

class CancelDownloadTask implements FileTask<bool> {
  CancelDownloadTask({@required this.taskId});

  @override
  bool execute() {
    print('exetucte CancelDownloadTask');
    return true;
  }

  @override
  ActionType actionType = ActionType.cancelDownload;

  @override
  String taskId;

  @override
  var taskProgressCallback;

  @override
  void handleCancel(String taskId) {}
}
