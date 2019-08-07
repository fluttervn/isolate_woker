import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isolate_worker/isolate_tasks/cancel_download_task.dart';
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
  String imagePath;
  String fullPath;
  Worker worker;

  @override
  void initState() {
    worker = Worker(poolSize: 2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tab3'),
        ),
        body: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('Download'),
              onPressed: downloadImage,
            ),
            Divider(),
            loading
                ? Column(
                    children: <Widget>[
                      CircularPercentIndicator(
                        radius: 150.0,
                        lineWidth: 10.0,
                        percent: percent,
                        center: Text('${(percent * 100).toInt()}%'),
                        backgroundColor: Colors.grey,
                        progressColor: Colors.blue,
                      ),
                      RaisedButton(
                        child: Text('Cancel'),
                        onPressed: cancel,
                      )
                    ],
                  )
                : imagePath != null
                    ? Image.file(File(imagePath))
                    : Text('No image')
          ],
        ));
  }

  void downloadImage() async {
    setState(() {
      imagePath = null;
      loading = true;
      percent = 0;
    });

    Function(TransferProgress progress) progressCallback = (progress) {
      setState(() {
        percent = progress.count / progress.total;
      });
    };

    var saveFolder = await Utils.getDownloadDirectory('Demo/Download');
    fullPath = '${saveFolder.path}/download.jpg';
    print('fullpath: $fullPath');
    final urlPath = 'https://sample-videos.com/img/Sample-jpg-image-5mb.jpg';
    final dio = Dio();
    var downloadTask = DownloadTask(
        taskId: fullPath, dio: dio, url: urlPath, savePath: fullPath);

    try {
      await worker.handle(downloadTask, callback: progressCallback);
      setState(() {
        loading = false;
        imagePath = fullPath;
      });
    }
    catch (e) {
      if (e is DioError) {
        if (e.type == DioErrorType.CANCEL) {
          Utils.showToast('File has been canceled');
        }
      }
      print('error: $e');
    }
  }

  void cancel() async {
    var task = CancelDownloadTask(
      taskId: fullPath
    );
    await worker.handle(task);

  }
}
