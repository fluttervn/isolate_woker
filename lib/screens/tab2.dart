import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isolate_worker/isolate_tasks/download_task.dart';
import 'package:isolate_worker/utils.dart';
import 'package:isolate_worker/worker/worker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class Tab2 extends StatefulWidget {
  @override
  _Tab2State createState() => _Tab2State();
}

class _Tab2State extends State<Tab2> {
  bool loading = false;
  double percent = 0;
  String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tab2'),
        ),
        body: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('Download'),
              onPressed: downloadImage,
            ),
            Divider(),
            loading
                ? CircularPercentIndicator(
                    radius: 150.0,
                    lineWidth: 10.0,
                    percent: percent,
                    center: Text('${(percent * 100).toInt()}%'),
                    backgroundColor: Colors.grey,
                    progressColor: Colors.blue,
                  )
                : imagePath != null
                    ? Image.file(File(imagePath))
                    : Text('No image'),
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
    final fullPath = '${saveFolder.path}/download.jpg';
    final urlPath = 'https://sample-videos.com/img/Sample-jpg-image-2mb.jpg';
    final dio = Dio();
    var downloadTask = DownloadTask(
        taskId: fullPath, dio: dio, url: urlPath, savePath: fullPath);
    final worker = Worker(poolSize: 1);
    await worker.handle(downloadTask, callback: progressCallback);
    setState(() {
      loading = false;
      imagePath = fullPath;
    });
  }
}
