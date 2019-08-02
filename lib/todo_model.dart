
class TodoModel {
  final int userId;
  final int id;
  final String title;
  final bool completed;

  TodoModel({this.userId, this.id, this.title, this.completed});

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      userId: json['userId'],
        id: json['id'],
      title: json['title'],
      completed: json['completed']
    );
  }

  @override
  String toString() {
    return 'TodoModel{userId: $userId, uid: $id, title: $title, completed: $completed}';
  }


}