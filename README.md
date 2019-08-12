# isolate_worker

[![Build Status](https://travis-ci.org/fluttervn/isolate_woker.svg?branch=master)](https://travis-ci.org/fluttervn/isolate_woker)

Library help run flutter tasks in other isolate. The library improve from original library: https://github.com/Dreckr/Worker
Improvement:
- Return callback progress for upload/download file
- Support cancel download/upload file

## Usage

Define class:
```dart
class DownloadTask implements FileTask<Future<bool>> {
  final Dio dio;
  final String url;
  final String savePath;
  CancelToken cancelToken;

  DownloadTask(
      {@required this.dio, @required this.url, this.savePath, this.taskId});

  @override
  Future<bool> execute() {
    return _doExecute();
  }

  Future<bool> _doExecute() async {
    cancelToken = CancelToken();
    var completer = Completer<bool>();

    try {
      final response = await dio.download(url, savePath,
          cancelToken: cancelToken, onReceiveProgress: taskProgressCallback);

      print('DownloadTask success: $response');
      completer.complete(true);
    } catch (e) {
      print('DownloadTask error: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  ActionType actionType = ActionType.download;

  @override
  String taskId;

  @override
  var taskProgressCallback;

  @override
  void handleCancel(String taskId) {
    cancelToken?.cancel('Cancel download $taskId');
  }
}
```
Use:
```dart
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
```

## Authors
- [anlam87](https://github.com/anticafe) (anlam12787@gmail.com)