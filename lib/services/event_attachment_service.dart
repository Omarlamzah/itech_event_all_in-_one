import 'package:dio/dio.dart';
import '../models/event_attachment.dart';
import 'api_service.dart';

class EventAttachmentService {
  final _api = ApiService();

  Future<List<EventAttachment>> getAttachments(int eventId) async {
    final res = await _api.get('/events/$eventId/attachments');
    return (res.data as List).map((e) => EventAttachment.fromJson(e)).toList();
  }

  Future<EventAttachment> upload(int eventId, String filePath, String fileName, {String? description}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (description != null && description.isNotEmpty) 'description': description,
    });
    final res = await _api.dio.post('/events/$eventId/attachments', data: formData);
    return EventAttachment.fromJson(res.data);
  }

  Future<void> delete(int eventId, int attachmentId) async {
    await _api.delete('/events/$eventId/attachments/$attachmentId');
  }

  String downloadUrl(int eventId, int attachmentId) {
    return '${_api.dio.options.baseUrl}/events/$eventId/attachments/$attachmentId/download';
  }
}
