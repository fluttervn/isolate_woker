class TodoModel {
  final int userId;
  final int id;
  final String title;
  final bool completed;

  TodoModel({this.userId, this.id, this.title, this.completed});

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }

  @override
  String toString() {
    return 'TodoModel{'
        'userId: $userId, id: $id, title: $title, completed: $completed}';
  }
}
