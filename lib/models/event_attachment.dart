class EventAttachment {
  final int id;
  final int eventId;
  final int uploadedBy;
  final String originalName;
  final String filePath;
  final int fileSize;
  final String? mimeType;
  final String? description;
  final String? uploaderName;
  final String createdAt;

  EventAttachment({
    required this.id,
    required this.eventId,
    required this.uploadedBy,
    required this.originalName,
    required this.filePath,
    required this.fileSize,
    this.mimeType,
    this.description,
    this.uploaderName,
    required this.createdAt,
  });

  factory EventAttachment.fromJson(Map<String, dynamic> json) => EventAttachment(
        id: json['id'],
        eventId: json['event_id'],
        uploadedBy: json['uploaded_by'],
        originalName: json['original_name'] ?? '',
        filePath: json['file_path'] ?? '',
        fileSize: json['file_size'] ?? 0,
        mimeType: json['mime_type'],
        description: json['description'],
        uploaderName: json['uploader']?['name'],
        createdAt: json['created_at'] ?? '',
      );

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => mimeType?.startsWith('image/') ?? false;
  bool get isPdf   => mimeType?.contains('pdf') ?? false;
}
