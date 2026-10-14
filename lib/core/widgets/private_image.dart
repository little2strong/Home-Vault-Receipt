import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/file_store.dart';
import '../theme/vault_palette.dart';

/// Loads a private file through [FileStore] (never a public URL). Use only
/// for thumbnails and item photos; receipt originals load in the viewer
/// after the user taps "View receipt".
class PrivateImage extends StatefulWidget {
  const PrivateImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String? path;
  final BoxFit fit;
  final String? semanticLabel;
  final IconData placeholderIcon;

  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  static final _cache = _LruCache(80);
  Future<Uint8List>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PrivateImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _load();
  }

  void _load() {
    final path = widget.path;
    if (path == null) {
      _future = null;
      return;
    }
    final cached = _cache[path];
    _future = cached != null
        ? Future.value(cached)
        : Get.find<FileStore>()
              .getData(path, maxBytes: 20 * 1024 * 1024)
              .then((b) => _cache[path] = b);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final placeholder = Container(
      color: p.illustration,
      alignment: Alignment.center,
      child: Icon(widget.placeholderIcon, color: p.muted),
    );
    if (_future == null) return placeholder;
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(
            snap.data!,
            fit: widget.fit,
            gaplessPlayback: true,
            semanticLabel: widget.semanticLabel,
            errorBuilder: (_, _, _) => placeholder,
          );
        }
        if (snap.hasError) return placeholder;
        return Container(color: p.illustration);
      },
    );
  }
}

class _LruCache {
  _LruCache(this.capacity);

  final int capacity;
  final _map = <String, Uint8List>{};

  Uint8List? operator [](String key) {
    final v = _map.remove(key);
    if (v != null) _map[key] = v;
    return v;
  }

  void operator []=(String key, Uint8List value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > capacity) _map.remove(_map.keys.first);
  }
}
