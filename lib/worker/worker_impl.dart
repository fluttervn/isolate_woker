part of worker.core;

class _WorkerImpl implements Worker {
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  int poolSize;

  final Queue<WorkerIsolate> isolates = new Queue<WorkerIsolate>();

  Iterable<WorkerIsolate> get availableIsolates =>
      this.isolates.where((isolate) => isolate.isFree);

  Iterable<WorkerIsolate> get workingIsolates =>
      this.isolates.where((isolate) => !isolate.isFree);

  StreamController<IsolateSpawnedEvent> _isolateSpawnedEventController =
      new StreamController<IsolateSpawnedEvent>.broadcast();

  Stream<IsolateSpawnedEvent> get onIsolateSpawned =>
      _isolateSpawnedEventController.stream;

  StreamController<IsolateClosedEvent> _isolateClosedEventController =
      new StreamController<IsolateClosedEvent>.broadcast();

  Stream<IsolateClosedEvent> get onIsolateClosed =>
      _isolateClosedEventController.stream;

  StreamController<TaskScheduledEvent> _taskScheduledEventController =
      new StreamController<TaskScheduledEvent>.broadcast();

  Stream<TaskScheduledEvent> get onTaskScheduled =>
      _taskScheduledEventController.stream;

  StreamController<TaskCompletedEvent> _taskCompletedEventController =
      new StreamController<TaskCompletedEvent>.broadcast();

  Stream<TaskCompletedEvent> get onTaskCompleted =>
      _taskCompletedEventController.stream;

  StreamController<TaskFailedEvent> _taskFailedEventController =
      new StreamController<TaskFailedEvent>.broadcast();

  Stream<TaskFailedEvent> get onTaskFailed =>
      _taskFailedEventController.stream;

  _WorkerImpl ({this.poolSize = 1, spawnLazily = true}) {
    if (this.poolSize <= 0)
      this.poolSize = 1;

    if (!spawnLazily) {
      for (var i = 0; i < this.poolSize; i++) {
        this._spawnIsolate();
      }
    }
  }

//  Future handle (Task task) {
//    if (this.isClosed)
//      throw new Exception('Worker is closed!');
//
//    WorkerIsolate isolate = this._selectIsolate();
//
//    if (isolate != null)
//      return isolate.performTask(task);
//    else
//      throw new Exception("No isolate available");
//  }

  Future handle(Task task, {Function(TransferProgress progress) callback}) {
    if (this.isClosed) throw new Exception('Worker is closed!');




      if (task is FileTask &&
          (task.actionType == ActionType.CANCEL_UPLOAD || task.actionType == ActionType.CANCEL_DOWNLOAD)) {
        String taskId = task.taskId;
        isolates.forEach((workerIsolate) {
          print('Worker: handle: CancelFileTask: $workerIsolate');
          if (workerIsolate.taskId == taskId) {
            workerIsolate.performTask(task, callback: callback);
          }
        });

        return Future.value(null);
      }




    WorkerIsolate isolate = this._selectIsolate();

    if (isolate != null) {
      return isolate.performTask(task, callback: callback);
    } else
      throw new Exception("No isolate available");
  }


  WorkerIsolate _selectIsolate () {
    return this.isolates.firstWhere((islt) => islt.isFree,
        orElse:
          () {
            var isolate;

            if (this.isolates.length < this.poolSize) {
              isolate = this._spawnIsolate();
            } else {
              isolate = this.isolates.firstWhere(
                  (isolate) => isolate.isFree,
                  orElse: () => this.isolates.reduce(
                      (a, b) =>
                          a.scheduledTasks.length <= b.scheduledTasks.length ?
                              a : b));
            }

            return isolate;
        });
  }

  WorkerIsolate _spawnIsolate () {
    var isolate = new _WorkerIsolateImpl();
    mergeStream(_isolateSpawnedEventController, isolate.onSpawned);
    mergeStream(_isolateClosedEventController, isolate.onClosed);
    mergeStream(_taskScheduledEventController, isolate.onTaskScheduled);
    mergeStream(_taskCompletedEventController, isolate.onTaskCompleted);
    mergeStream(_taskFailedEventController, isolate.onTaskFailed);
    this.isolates.add(isolate );

    return isolate;
  }

  Future<Worker> close ({bool afterDone= true}) {
    if (this._isClosed)
          return new Future.value(this);

    this._isClosed = true;

    var closeFutures = <Future<WorkerIsolate>>[];
    this.isolates.forEach(
        (isolate) => closeFutures.add(isolate.close(afterDone: afterDone)));

    return Future.wait(closeFutures).then((_) => this);
  }

}

class _WorkerIsolateImpl implements WorkerIsolate {
  Map<String, Function(TransferProgress progress)> mapTaskCallback = Map();
  bool _isClosed = false;

  bool get isClosed => this._isClosed;

  ReceivePort _receivePort;

  SendPort _sendPort;

  Queue<_ScheduledTask> _scheduledTasks = new Queue<_ScheduledTask>();

  _ScheduledTask _runningScheduledTask;

  Task get runningTask => _runningScheduledTask != null ?
                            _runningScheduledTask.task : null;

  List<Task> get scheduledTasks =>
      _scheduledTasks.map((scheduledTask) => scheduledTask.task)
        .toList(growable: false);

  bool get isFree => _scheduledTasks.isEmpty && _runningScheduledTask == null;

  StreamController<IsolateSpawnedEvent> _spawnEventController =
      new StreamController<IsolateSpawnedEvent>.broadcast();

  Stream<IsolateSpawnedEvent> get onSpawned =>
      _spawnEventController.stream;

  StreamController<IsolateClosedEvent> _closeEventController =
      new StreamController<IsolateClosedEvent>.broadcast();

  Stream<IsolateClosedEvent> get onClosed =>
      _closeEventController.stream;

  StreamController<TaskScheduledEvent> _taskScheduledEventController =
      new StreamController<TaskScheduledEvent>.broadcast();

  Stream<TaskScheduledEvent> get onTaskScheduled =>
      _taskScheduledEventController.stream;

  StreamController<TaskCompletedEvent> _taskCompletedEventController =
      new StreamController<TaskCompletedEvent>.broadcast();

  Stream<TaskCompletedEvent> get onTaskCompleted =>
      _taskCompletedEventController.stream;

  StreamController<TaskFailedEvent> _taskFailedEventController =
      new StreamController<TaskFailedEvent>.broadcast();

  Stream<TaskFailedEvent> get onTaskFailed =>
      _taskFailedEventController.stream;

  Completer<WorkerIsolate> _closeCompleter;

  _WorkerIsolateImpl () {
    this._receivePort = new ReceivePort();

    this._spawnIsolate();
  }

  Future<WorkerIsolate> _spawnIsolate() {
    Completer<WorkerIsolate> completer = new Completer();
    Isolate.spawn(_workerMain, this._receivePort.sendPort).then((isolate) {},
        onError: (error) {
          print(error);
        });

    this._receivePort.listen((message) {
//      print('Worker: receivePort: $message');
      if (message is _WorkerProgress) {
        Function callback = mapTaskCallback[message.taskId];
        if (callback != null) {
          callback(TransferProgress(
            count: message.count,
            total: message.total,
          ));
        } else {
//          print('... but not callback for taskId=${message.taskId}');
        }

        return;
      } else if (message is FileTask &&
          (message.actionType == ActionType.CANCEL_UPLOAD || message.actionType == ActionType.CANCEL_DOWNLOAD)) {
        print('... CancelFileTask this=$this');

        return;
      } else if (message is SendPort) {
        print('... SendPort this=$this');
        completer.complete(this);
        this._spawnEventController.add(new IsolateSpawnedEvent(this));
        this._sendPort = message;

        this._runNextTask();

        return;
      } else if (message is String) {
        print('... SendPort this String=$message');
//        completer.complete(this);
//        this._spawnEventController.add(new IsolateSpawnedEvent(this));
        this.taskId = message;

//        this._runNextTask();

        return;
      } else if (message is _WorkerException) {
        this._taskFailedEventController.add(new TaskFailedEvent(
            this,
            this._runningScheduledTask.task,
            message.exception,
            message.stackTrace));

        this
            ._runningScheduledTask
            .completer
            .completeError(message.exception, message.stackTrace);
      } else if (message is _WorkerSignal) {
        if (message.id == _CLOSE_SIGNAL.id) {
          this._closeEventController.add(new IsolateClosedEvent(this));
          this._closeStreamControllers();
          _receivePort.close();
        }
      } else if (message is _WorkerResult) {
        print('... WorkerResult result=${message.result}, this=$this');
        this._taskCompletedEventController.add(new TaskCompletedEvent(
            this, this._runningScheduledTask.task, message.result));

        this._runningScheduledTask.completer.complete(message.result);
      }

      this._runningScheduledTask = null;

      this._runNextTask();
    }, onError: (exception) {
      this._runningScheduledTask.completer.completeError(exception);
      this._runningScheduledTask = null;
    });

    return completer.future;
  }

  Future performTask(Task task,
      {Function(TransferProgress progress) callback}) {
    print('Worker: performTask $task');
    if (this.isClosed) throw new StateError('This WorkerIsolate is closed.');

    if (task is FileTask &&
        (task.actionType == ActionType.CANCEL_UPLOAD || task.actionType == ActionType.CANCEL_DOWNLOAD)) {
      print('Worker: performTask _sendPort.send of CancelFileTask');
      this._sendPort.send(task);
      return Future.value(null);
    }

    Completer completer = new Completer();
    // TODO(triet) at this time only DownloadTask and UploadFileTask has callback


    if (task is FileTask &&
        (task.actionType == ActionType.UPLOAD || task.actionType == ActionType.DOWNLOAD)) {
      mapTaskCallback[task.taskId] = callback;
    }

    this._scheduledTasks.add(new _ScheduledTask(task, completer));
    this._taskScheduledEventController.add(new TaskScheduledEvent(this, task));

    this._runNextTask();

    return completer.future;
  }

  void _runNextTask () {
    if (_sendPort == null ||
        _scheduledTasks.length == 0 ||
        (_runningScheduledTask != null &&
        !_runningScheduledTask.completer.isCompleted)) {
      return;
    }

    _runningScheduledTask = _scheduledTasks.removeFirst();

    this._sendPort.send(_runningScheduledTask.task);

  }

  void _closeStreamControllers () {
    this._spawnEventController.close();
    this._closeEventController.close();
    this._taskScheduledEventController.close();
    this._taskCompletedEventController.close();
    this._taskFailedEventController.close();
  }

  Future<WorkerIsolate> close ({bool afterDone= true}) {
    if (this._isClosed)
      return new Future.value(this);

    this._isClosed = true;
    this._closeCompleter = new Completer<WorkerIsolate>();

    if (afterDone) {
      var closeIfDone = (_) {
        if (this.isFree) {
          this._close();
        }
      };

      var waitTasksToComplete = () {
        if (!this.isFree) {
          this.onTaskCompleted.listen(closeIfDone);
          this.onTaskFailed.listen(closeIfDone);
        } else {
          this._close();
        }
      };

      if (this._sendPort == null) {
        this.onSpawned.listen((_) {
          waitTasksToComplete();
        });
      } else {
        waitTasksToComplete();
      }
    } else {
      this.onSpawned.first.then((_) {
        this._close();
      });
    }

    return this._closeCompleter.future;
  }

  void _close () {
    if (this._sendPort != null) {
      this._sendPort.send(_CLOSE_SIGNAL);
      this._sendPort = null;
    }

    this._receivePort.close();
    this._closeEventController.add(new IsolateClosedEvent(this));
    this._closeCompleter.complete(this);

    var cancelTask = (scheduledTask) {
      var exception = new TaskCancelledException(scheduledTask.task);
      scheduledTask.completer.completeError(exception);
            this._taskFailedEventController.add(
                new TaskFailedEvent(this, scheduledTask.task, exception));
    };

    if (this._runningScheduledTask != null) {
      cancelTask(this._runningScheduledTask);
    }

    this._scheduledTasks.forEach(cancelTask);
  }

  @override
  String taskId;

}

class _ScheduledTask {
  Completer completer;
  Task task;

  _ScheduledTask (Task this.task, Completer this.completer);
}


/**
 * Signals:
 *  1 - CloseIsolate
 */
const _CLOSE_SIGNAL = const _WorkerSignal(1);
class _WorkerSignal {
  final int id;

  const _WorkerSignal (this.id);

}

class _WorkerResult {
  final result;
  final String taskId;
  _WorkerResult(this.result, {this.taskId});

  @override
  String toString() {
    return '_WorkerResult{result=$result, taskId=$taskId}';
  }
}



class _WorkerException {
  final exception;
  final List<Frame> stackTraceFrames;
  StackTrace get stackTrace {
    if (stackTraceFrames != null) {
      return new Trace(stackTraceFrames).vmTrace;
    }

    return null;
  }

  _WorkerException (this.exception, this.stackTraceFrames);
}

void mergeStream (EventSink sink, Stream stream) {
  stream.listen(
      (data) => sink.add(data),
      onError: (errorEvent, stackTrace) =>
          sink.addError(errorEvent, stackTrace));
}


// An add code
class _WorkerProgress {
  int count;
  int total;
//  String saveFilePath;
  String taskId;

  _WorkerProgress({this.count, this.total, this.taskId});

  @override
  String toString() {
    return '_WorkerProgress{count=$count, total=$total}';
  }
}
