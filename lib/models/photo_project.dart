enum ProjectStatus { inProgress, done }

class DuringPhoto {
  DuringPhoto({
    required this.id,
    required this.path,
    required this.note,
    required this.date,
  });

  final String id;
  final String path;
  final String note;
  final DateTime? date;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'note': note,
      'date': date?.toIso8601String() ?? '',
    };
  }

  factory DuringPhoto.fromJson(Map<String, dynamic> json) {
    return DuringPhoto(
      id: (json['id'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
    );
  }
}

class PhotoProject {
  PhotoProject({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    required this.isFavorite,
    required this.beforePath,
    required this.afterPath,
    required this.beforeNote,
    required this.afterNote,
    required this.description,
    required this.duringPhotos,
    required this.afterDate,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final ProjectStatus status;
  final bool isFavorite;

  final String beforePath;
  final String afterPath;

  final String beforeNote;
  final String afterNote;

  final String description;

  final List<DuringPhoto> duringPhotos;
  final DateTime? afterDate;

  bool get hasAfter => afterPath.trim().isNotEmpty;
  bool get hasDuring => duringPhotos.isNotEmpty;

  PhotoProject copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    ProjectStatus? status,
    bool? isFavorite,
    String? beforePath,
    String? afterPath,
    String? beforeNote,
    String? afterNote,
    String? description,
    List<DuringPhoto>? duringPhotos,
    DateTime? afterDate,
    bool clearAfterDate = false,
  }) {
    return PhotoProject(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      beforePath: beforePath ?? this.beforePath,
      afterPath: afterPath ?? this.afterPath,
      beforeNote: beforeNote ?? this.beforeNote,
      afterNote: afterNote ?? this.afterNote,
      description: description ?? this.description,
      duringPhotos: duringPhotos ?? this.duringPhotos,
      afterDate: clearAfterDate ? null : (afterDate ?? this.afterDate),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'isFavorite': isFavorite,
      'beforePath': beforePath,
      'afterPath': afterPath,
      'beforeNote': beforeNote,
      'afterNote': afterNote,
      'description': description,
      'duringPhotos': duringPhotos.map((e) => e.toJson()).toList(),
      'afterDate': afterDate?.toIso8601String() ?? '',
    };
  }

  factory PhotoProject.fromJson(Map<String, dynamic> json) {
    final rawAfter = (json['afterPath'] ?? '').toString();
    final parsedStatus = (json['status'] ?? '').toString() == ProjectStatus.done.name
        ? ProjectStatus.done
        : ProjectStatus.inProgress;
    final effectiveStatus =
        rawAfter.trim().isNotEmpty ? ProjectStatus.done : parsedStatus;

    final duringPhotosRaw = json['duringPhotos'];
    List<DuringPhoto> duringPhotos = [];

    if (duringPhotosRaw is List) {
      duringPhotos = duringPhotosRaw
          .whereType<Map>()
          .map((e) => DuringPhoto.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.path.trim().isNotEmpty)
          .toList();
    }

    // Migration ancien format : duringPath + duringNote
    final legacyDuringPath = (json['duringPath'] ?? '').toString();
    final legacyDuringNote = (json['duringNote'] ?? '').toString();
    if (duringPhotos.isEmpty && legacyDuringPath.trim().isNotEmpty) {
      duringPhotos = [
        DuringPhoto(
          id: 'legacy_during',
          path: legacyDuringPath,
          note: legacyDuringNote,
          date: null,
        ),
      ];
    }

    return PhotoProject(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      status: effectiveStatus,
      isFavorite: (json['isFavorite'] ?? false) == true,
      beforePath: (json['beforePath'] ?? '').toString(),
      afterPath: rawAfter,
      beforeNote: (json['beforeNote'] ?? '').toString(),
      afterNote: (json['afterNote'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      duringPhotos: duringPhotos,
      afterDate: DateTime.tryParse((json['afterDate'] ?? '').toString()),
    );
  }
}