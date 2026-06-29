import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'dart:io';
import '../models/song.dart';

class AlbumArtWidget extends StatefulWidget {
  final Song song;
  final double size;
  final BorderRadius? borderRadius;

  const AlbumArtWidget({
    super.key,
    required this.song,
    this.size = 56,
    this.borderRadius,
  });

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  Uint8List? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    setState(() {
      _loading = true;
      _imageBytes = null;
    });

    try {
      final metadata = await MetadataRetriever.fromFile(File(widget.song.path));
      if (metadata.albumArt != null && mounted) {
        setState(() {
          _imageBytes = metadata.albumArt;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E44AD),
            Color(0xFF3498DB),
            Color(0xFF16A085),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              )
            : _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.music_note,
        color: Colors.white70,
        size: widget.size * 0.5,
      ),
    );
  }
}
