import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isolate_worker/isolate_tasks/upload_task.dart';
import 'package:isolate_worker/utils.dart';
import 'package:isolate_worker/worker/worker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:isolate_worker/isolate_tasks/download_task.dart';


class Tab3 extends StatefulWidget {
  @override
  _Tab3State createState() => _Tab3State();
}

class _Tab3State extends State<Tab3> {
  bool loading = false;
  double percent = 0;
  final fileName = 'beautiful-girl.jpg';

  @override
  Widget build(BuildContext context) {
    print('rebuild');
    return Scaffold(
        appBar: AppBar(
          title: Text('Tab3'),
        ),
        body: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('Upload'),
              onPressed: () {
                uploadImage();
              },
            ),
            Divider(),
            loading
                ? CircularPercentIndicator(
              radius: 150.0,
              lineWidth: 10.0,
              percent: percent,
              center: Text("Uploading..."),
              backgroundColor: Colors.grey,
              progressColor: Colors.blue,
            ):
                SizedBox(),
            Image.asset('assets/$fileName')
          ],
        ));
  }

  void uploadImage() async {

    print('comming soon...');
    //    setState(() {
//      loading = true;
//      percent = 0;
//    });
//
//    Function(TransferProgress progress) progressCallback = (progress) {
//      print('DownloadTask callback count=${progress.count}, total=${progress.total}');
//      setState(() {
//        percent = progress.count / progress.total;
//      });
//    };
//
//    File file = await Utils.getImageFileFromAssets(fileName);
//
//
//    print('file: ${file.readAsBytesSync()}');
//    UploadTask uploadTask = UploadTask(
//        taskId: fileName, fileName: fileName, file: file);
//    final Worker worker = Worker(poolSize: 1);
//    await worker.handle(uploadTask, callback: progressCallback);
//    setState(() {
//      loading = false;
//    });
//  }
}
