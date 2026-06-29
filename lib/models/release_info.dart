class ReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final String htmlUrl;
  final List<ReleaseAsset> assets;
  final bool prerelease;
  final bool draft;

  ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
    this.prerelease = false,
    this.draft = false,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? json['tag_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
      htmlUrl: json['html_url'] as String? ?? '',
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ReleaseAsset? getApkAsset() {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) {
        return asset;
      }
    }
    return null;
  }

  ReleaseAsset? getWindowsAsset() {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.exe') ||
          asset.name.toLowerCase().endsWith('.msix') ||
          asset.name.toLowerCase().endsWith('.zip')) {
        return asset;
      }
    }
    return null;
  }

  ReleaseAsset? getIosAsset() {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.ipa')) {
        return asset;
      }
    }
    return null;
  }

  bool get isEmpty => tagName.isEmpty;
}

class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
    );
  }

  bool get isEmpty => name.isEmpty;

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
