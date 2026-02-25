enum ProjectStatus { inProgress, done }

class PhotoProject {
  PhotoProject({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    required this.isFavorite,
    required this.beforePath,
    required this.afterPath,
    this.duringPath,
    required this.beforeNote,
    required this.duringNote,
    required this.afterNote,
    required this.description,
  });

  String id;
  String title;
  DateTime createdAt;
  ProjectStatus status;
  bool isFavorite;

  String beforePath;
  String afterPath;
  String? duringPath;

  String beforeNote;
  String duringNote;
  String afterNote;

  String description;

  bool get hasAfter => afterPath.trim().isNotEmpty;
  bool get hasDuring => (duringPath ?? '').trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'isFavorite': isFavorite,
      'beforePath': beforePath,
      'afterPath': afterPath,
      'duringPath': duringPath ?? '',
      'beforeNote': beforeNote,
      'duringNote': duringNote,
      'afterNote': afterNote,
      'description': description,
    };
  }

  factory PhotoProject.fromJson(Map<String, dynamic> json) {
    final rawAfterPath = (json['afterPath'] ?? '').toString();
    final parsedStatus = _parseStatus((json['status'] ?? '').toString());
    final inferredStatus = rawAfterPath.trim().isNotEmpty ? ProjectStatus.done : ProjectStatus.inProgress;

    return PhotoProject(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      status: parsedStatus ?? inferredStatus,
      isFavorite: json['isFavorite'] == true,
      beforePath: (json['beforePath'] ?? '').toString(),
      afterPath: rawAfterPath,
      duringPath: (json['duringPath'] ?? '').toString(),
      beforeNote: (json['beforeNote'] ?? '').toString(),
      duringNote: (json['duringNote'] ?? '').toString(),
      afterNote: (json['afterNote'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  static ProjectStatus? _parseStatus(String value) {
    for (final status in ProjectStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}
