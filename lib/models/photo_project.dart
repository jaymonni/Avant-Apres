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
    final beforePath = (json['beforePath'] ?? '').toString();
    final afterPath = (json['afterPath'] ?? '').toString();
    final duringRaw = (json['duringPath'] ?? '').toString();
    final statusRaw = (json['status'] ?? '').toString();

    ProjectStatus status;
    if (afterPath.trim().isNotEmpty) {
      status = ProjectStatus.done;
    } else if (statusRaw == ProjectStatus.done.name) {
      status = ProjectStatus.done;
    } else {
      status = ProjectStatus.inProgress;
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse((json['createdAt'] ?? '').toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    return PhotoProject(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      createdAt: createdAt,
      status: status,
      isFavorite: json['isFavorite'] == true,
      beforePath: beforePath,
      afterPath: afterPath,
      duringPath: duringRaw.trim().isEmpty ? null : duringRaw,
      beforeNote: (json['beforeNote'] ?? '').toString(),
      duringNote: (json['duringNote'] ?? '').toString(),
      afterNote: (json['afterNote'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}
