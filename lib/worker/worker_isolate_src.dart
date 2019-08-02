part of worker.core;

Map<String, FileTask> mapUploadTask = Map();
Map<String, FileTask> mapDownloadTask = Map();
void _workerMain(sendPort) {
  ReceivePort receivePort;
  if (receivePort == null) {
    receivePort = new ReceivePort();
  }

  if (sendPort is SendPort) {
    sendPort = sendPort;
    print('Worker: sendPort send=${receivePort.sendPort}');
    sendPort.send(receivePort.sendPort);
  }

  receivePort.listen((message) {
    if (!_acceptMessage(sendPort, receivePort, message)) return;

    var result;

    try {
      if (message is Task) {
        var taskId = '';
        print('Worker: execute Task message=$message');

        if (message is FileTask) {
          if (message.actionType == ActionType.UPLOAD) {
            taskId = message.taskId;
            mapUploadTask[taskId] = message;

            sendPort.send(taskId);
            message.taskProgressCallback = (count, total) {
              sendPort.send(new _WorkerProgress(
                count: count,
                total: total,
                taskId: message.taskId,
              ));
            };
          }
          else if (message.actionType == ActionType.DOWNLOAD) {
            mapDownloadTask[taskId] = message;
            message.taskProgressCallback = (count, total) {
              sendPort.send(new _WorkerProgress(
                count: count,
                total: total,
                taskId: message.taskId,
              ));
            };
          }
          else if (message.actionType == ActionType.CANCEL_UPLOAD) {
            print('... CancelUploadTask message=$message');
            mapUploadTask.forEach((taskId, uploadTask) {
              if (taskId == message.taskId) {
                uploadTask.handleCancel(taskId);
              }
            });

            return;
          }
          else if (message.actionType == ActionType.CANCEL_DOWNLOAD) {
            print('... CancelDownloadTask message=$message');
            mapDownloadTask.forEach((taskId, downloadTask) {
              if (taskId == message.taskId) {
                downloadTask.handleCancel(taskId);
              }
            });

            return;
          }
        }

        result = message.execute();
//        Function callback = mapTaskCallback[taskId];
//        if (callback != null) {}

        if (result is Future) {
          result.then(
                (futureResult) {
              print(
                  'Worker: main: ------ WorkerResult: ${result.runtimeType}: result=$futureResult');
              sendPort.send(new _WorkerResult(futureResult, taskId: taskId));
            },
            onError: (exception, stackTrace) {
              print('Worker: execute main but FAIL: exception=$exception, '
                  'stackTrace=$stackTrace');
              sendException(sendPort, exception, stackTrace);
            },
          );
        } else {
          print('Worker: main2: WorkerResult: result2=$result');
          sendPort.send(new _WorkerResult(result, taskId: taskId));
        }
      } else if (message is String) {
        print('Worker: execute TaskId=$message');
      } else
        throw new Exception('Message is not a task');
    } catch (exception, stackTrace) {
      print('... Worker: execute Task message=$message but FAIL: '
          'exception=$exception, stackTrace=$stackTrace');
      sendException(sendPort, exception, stackTrace);
    }
  });
}

bool _acceptMessage(SendPort sendPort, ReceivePort receivePort, message) {
  if (message is _WorkerSignal && message.id == _CLOSE_SIGNAL.id) {
    sendPort.send(_CLOSE_SIGNAL);
    receivePort.close();
    return false;
  }

  return true;
}

void sendException(SendPort sendPort, exception, StackTrace stackTrace) {
  if (exception is Error) {
    exception = Error.safeToString(exception);
  }

  var stackTraceFrames;
  if (stackTrace != null) {
    stackTraceFrames = new Trace.from(stackTrace).frames;
  }

  sendPort.send(new _WorkerException(exception, stackTraceFrames));
}
