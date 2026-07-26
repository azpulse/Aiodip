class ProjectItem {
  ProjectItem({
    required this.id,
    required this.title,
    required this.trackCount,
    this.status = 'draft',
  });

  final String id;
  final String title;
  final int trackCount;
  final String status;

  factory ProjectItem.fromMap(Map<String, dynamic> m, {int trackCount = 0}) {
    return ProjectItem(
      id: m['id'] as String,
      title: (m['title'] as String?) ?? 'Untitled mix',
      trackCount: trackCount,
      status: (m['status'] as String?) ?? 'draft',
    );
  }
}

class TrackItem {
  TrackItem({
    required this.id,
    required this.name,
    this.storagePath,
    this.durationLabel,
  });

  final String id;
  final String name;
  final String? storagePath;
  final String? durationLabel;
}
