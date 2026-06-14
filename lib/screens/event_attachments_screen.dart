import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_attachment.dart';
import '../services/event_attachment_service.dart';

class EventAttachmentsScreen extends StatefulWidget {
  final Event event;
  const EventAttachmentsScreen({super.key, required this.event});

  @override
  State<EventAttachmentsScreen> createState() => _EventAttachmentsScreenState();
}

class _EventAttachmentsScreenState extends State<EventAttachmentsScreen> {
  final _svc = EventAttachmentService();
  List<EventAttachment> _attachments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getAttachments(widget.event.id);
      setState(() { _attachments = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  Future<void> _delete(EventAttachment att) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${att.originalName}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try { await _svc.delete(widget.event.id, att.id); _load(); }
    catch (e) { _showError(e.toString()); }
  }

  IconData _fileIcon(EventAttachment att) {
    if (att.isImage) return Icons.image;
    if (att.isPdf)   return Icons.picture_as_pdf;
    final mime = att.mimeType ?? '';
    if (mime.contains('video')) return Icons.videocam;
    if (mime.contains('audio')) return Icons.audiotrack;
    if (mime.contains('zip') || mime.contains('rar')) return Icons.folder_zip;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    if (mime.contains('sheet') || mime.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Color _fileColor(EventAttachment att) {
    if (att.isImage) return Colors.pink;
    if (att.isPdf)   return Colors.red;
    final mime = att.mimeType ?? '';
    if (mime.contains('video')) return Colors.purple;
    if (mime.contains('audio')) return Colors.indigo;
    if (mime.contains('zip'))   return Colors.amber;
    if (mime.contains('word'))  return Colors.blue;
    if (mime.contains('sheet')) return Colors.green;
    return Colors.blueGrey;
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pièces jointes — ${widget.event.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _attachments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.attach_file, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Aucune pièce jointe', style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('Uploadez des fichiers depuis le tableau de bord web.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _attachments.length,
                      itemBuilder: (_, i) {
                        final att = _attachments[i];
                        final color = _fileColor(att);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_fileIcon(att), color: color, size: 24),
                            ),
                            title: Text(att.originalName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(att.formattedSize,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  if (att.uploaderName != null) ...[
                                    const Text(' · ', style: TextStyle(color: Colors.grey)),
                                    Text(att.uploaderName!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                  const Text(' · ', style: TextStyle(color: Colors.grey)),
                                  Text(_formatDate(att.createdAt),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ]),
                                if (att.description != null && att.description!.isNotEmpty)
                                  Text(att.description!,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'delete',
                                    child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                              ],
                              onSelected: (v) { if (v == 'delete') _delete(att); },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
