import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iso/iso.dart';
import 'package:isolate_worker/utils.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class Tab3 extends StatefulWidget {
  @override
  _Tab3State createState() => _Tab3State();
}

class _Tab3State extends State<Tab3> {
  bool loading = false;
  double percent = 0;
  String imagePath;
  String fullPath;
  Iso iso;

  @override
  void initState() {
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
                      ),
                    ],
                  )
                : imagePath != null
                    ? Image.file(
                        File(imagePath),
                        width: 400,
                        height: 400,
                      )
                    : Text('No image')
          ],
        ));
  }

//  void downloadImage() async {
//    setState(() {
//      imagePath = null;
//      loading = true;
//      percent = 0;
//    });
//
//    Function(TransferProgress progress) progressCallback = (progress) {
//      setState(() {
//        percent = progress.count / progress.total;
//      });
//    };
//
//    var saveFolder = await Utils.getDownloadDirectory('Demo/Download');
//    fullPath = '${saveFolder.path}/download.jpg';
//    print('fullpath: $fullPath');
//    final urlPath = 'https://sample-videos.com/img/Sample-jpg-image-5mb.jpg';
//    final dio = Dio();
//    var downloadTask = DownloadTask(
//        taskId: fullPath, dio: dio, url: urlPath, savePath: fullPath);
//
//    try {
//      await worker.handle(downloadTask, callback: progressCallback);
//      setState(() {
//        loading = false;
//        imagePath = fullPath;
//      });
//    } catch (e) {
//      if (e is DioError) {
//        if (e.type == DioErrorType.CANCEL) {
//          Utils.showToast('File has been canceled');
//        }
//      }
//      print('error: $e');
//    }
//  }
//
//  void cancel() async {
//    var task = CancelDownloadTask(taskId: fullPath);
//    await worker.handle(task);
//  }

  void cancel() async {
    iso.send('Cancel');
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
    final fullPath = '${saveFolder.path}/download_cancel.jpg';
    final urlPath = 'https://sample-videos.com/img/Sample-jpg-image-5mb.jpg';
    final dio = Dio();

    iso = Iso(run, onDataOut: null);
    iso.dataOut.listen((dynamic payload) {
      print('payload: $payload');
      if (payload is TransferProgress) {
        progressCallback(payload);
      } else if (payload is bool) {
        setState(() {
          loading = false;
          imagePath = fullPath;
        });
        iso.dispose();
      } else if (payload is DioError) {
        print('ook  ');
        if (payload.type == DioErrorType.CANCEL) {
          Utils.showToast('File has been canceled');
        }
      } else {
        print('Data from isolate -> $payload / ${payload.runtimeType}');
      }
    });
    iso.run();
    await iso.onCanReceive;
    // now we can send messages to the isolate
    iso.send([fullPath, Dio(), urlPath, fullPath]);
  }

  static void run(IsoRunner iso) async {
    iso.receive();
    // listen to the data coming in
    var taskId = '';
    var cancelToken = CancelToken();

    iso.dataIn.listen((dynamic data) async {
      print('data isolate: $data');

      if (data is List<dynamic>) {
        taskId = data[0] as String;
        var dio = data[1] as Dio;
        var url = data[2] as String;
        var savePath = data[3] as String;

        try {
          final response = await dio.download(url, savePath,
              cancelToken: cancelToken, onReceiveProgress: (count, total) {
            // send into the main thread
            iso.send(TransferProgress(count: count, total: total));
          });
          print('DownloadTask success: $response');
          // send into the main thread
          iso.send(true);
        } catch (e) {
          print('DownloadTask error: $e');
          // send into the main thread
          iso.send(e);
        }
      } else if (data is String) {
        if (data == 'Cancel') {
          cancelToken?.cancel('Cancel download $taskId');
        }
      }
    });
  }
}
