library worker.events;

import 'worker.dart';

class WorkerEvent {
  final String type;
  final WorkerIsolate isolate;

  WorkerEvent(this.type, this.isolate);
}

class IsolateSpawnedEvent extends WorkerEvent {
  IsolateSpawnedEvent(WorkerIsolate isolate) :
    super("isolateSpawned", isolate);
}

class IsolateClosedEvent extends WorkerEvent {
  IsolateClosedEvent(WorkerIsolate isolate) :
      super("isolateClosed", isolate);
}

class TaskScheduledEvent extends WorkerEvent {
  final Task task;

  TaskScheduledEvent(WorkerIsolate isolate, this.task) :
      super("taskScheduled", isolate);
}

class TaskCompletedEvent extends WorkerEvent {
  final Task task;
  final result;

  TaskCompletedEvent(WorkerIsolate isolate, this.task, this.result) :
        super("taskCompleted", isolate);
}

class TaskFailedEvent extends WorkerEvent {
  final Task task;
  final error;
  final StackTrace stackTrace;

  TaskFailedEvent(WorkerIsolate isolate,
                      this.task,
                      this.error,
                      [this.stackTrace = null]) :

        super("taskFailed", isolate);
}