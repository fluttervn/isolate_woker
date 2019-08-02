import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../worker/worker.dart';
import 'package:firebase_storage/firebase_storage.dart';


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
    Completer<bool> completer = Completer();



    try {
      final StorageReference storageRef =
      FirebaseStorage.instance.ref().child(fileName);

      final StorageUploadTask uploadTask = storageRef.putFile(
          file,
      );
      uploadTask.events.listen((event){
        taskProgressCallback(event.snapshot.bytesTransferred, event.snapshot.totalByteCount);
      });

      final StorageTaskSnapshot downloadUrl =
      (await uploadTask.onComplete);
      final String url = (await downloadUrl.ref.getDownloadURL());


      print('UploadTask is DONE result=$url');
      completer.complete(true);
    } catch (e) {
      print('UploadTask error: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  ActionType actionType = ActionType.UPLOAD;

  @override
  String taskId;

  @override
  var taskProgressCallback;

  @override
  void handleCancel(String taskId) {
    // TODO: implement handleCancel
  }
}
