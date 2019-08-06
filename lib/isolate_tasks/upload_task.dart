import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../worker/worker.dart';


class UploadTask implements FileTask<Future<bool>> {
  final File file;
  final String fileName;

  UploadTask({@required this.file, @required this.fileName, this.taskId});

  @override
  Future<bool> execute() {
    print('exetucte...');
    return _doExecute();
  }

  Future<bool> _doExecute() async {
    var completer = Completer<bool>();



    try {
      final storageRef =
      FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = storageRef.putFile(
          file,
      );
      uploadTask.events.listen((event){
        taskProgressCallback(
            event.snapshot.bytesTransferred, event.snapshot.totalByteCount);
      });

      final downloadUrl =
      (await uploadTask.onComplete);
      var url = (await downloadUrl.ref.getDownloadURL()) as String;


      print('UploadTask is DONE result=$url');
      completer.complete(true);
    } catch (e) {
      print('UploadTask error: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  ActionType actionType = ActionType.upload;

  @override
  String taskId;

  @override
  var taskProgressCallback;

  @override
  void handleCancel(String taskId) {
    // TODO: implement handleCancel
  }
}
