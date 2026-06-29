import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../core/constants/app_constants.dart';
import '../models/release_info.dart';

class UpdateService {
  static const _githubApiBase = 'https://api.github.com';
  String? _repoOwner;
  String? _repoName;

  UpdateService() {
    _detectRepo();
  }

  void _detectRepo() {
    final repoUrl = AppConstants.repositoryUrl;
    if (repoUrl.isEmpty) return;

    try {
      final uri = Uri.parse(repoUrl);
      final parts = uri.pathSegments;
      if (parts.length >= 2) {
        _repoOwner = parts[0];
        _repoName = parts[1].replaceAll('.git', '');
      }
    } catch (e) {
      debugPrint('[UpdateService] Failed to parse repo URL: $e');
    }
  }

  bool get isConfigured =>
      _repoOwner != null && _repoName != null && _repoOwner!.isNotEmpty;

  Future<ReleaseInfo?> checkForUpdate() async {
    if (!isConfigured) return null;

    try {
      final url = '$_githubApiBase/repos/$_repoOwner/$_repoName/releases/latest';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final release = ReleaseInfo.fromJson(data);
        if (release.draft || release.prerelease) return null;
        return release;
      }
      return null;
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
      return null;
    }
  }

  bool isNewerVersion(String remoteTag, String currentVersion) {
    try {
      final remote = _parseVersion(remoteTag);
      final current = _parseVersion(currentVersion);
      return _compare(remote, current) > 0;
    } catch (e) {
      return false;
    }
  }

  List<int> _parseVersion(String version) {
    final clean = version.replaceAll(RegExp(r'[vV]'), '').split('.');
    return clean.map((p) => int.tryParse(p) ?? 0).toList();
  }

  int _compare(List<int> a, List<int> b) {
    final maxLen = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < maxLen; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av > bv) return 1;
      if (av < bv) return -1;
    }
    return 0;
  }

  Future<UpdateResult?> checkUpdateIfNeeded() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final release = await checkForUpdate();
      if (release == null) return null;

      if (isNewerVersion(release.tagName, packageInfo.version)) {
        return UpdateResult(
          release: release,
          currentVersion: packageInfo.version,
          platform: _getCurrentPlatform(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[UpdateService] error: $e');
      return null;
    }
  }

  UpdatePlatform _getCurrentPlatform() {
    if (Platform.isAndroid) return UpdatePlatform.android;
    if (Platform.isIOS) return UpdatePlatform.ios;
    if (Platform.isWindows) return UpdatePlatform.windows;
    if (Platform.isMacOS) return UpdatePlatform.macos;
    if (Platform.isLinux) return UpdatePlatform.linux;
    return UpdatePlatform.unknown;
  }
}

class UpdateResult {
  final ReleaseInfo release;
  final String currentVersion;
  final UpdatePlatform platform;

  UpdateResult({
    required this.release,
    required this.currentVersion,
    required this.platform,
  });

  ReleaseAsset? getPlatformAsset() {
    switch (platform) {
      case UpdatePlatform.android:
        return release.getApkAsset();
      case UpdatePlatform.ios:
        return release.getIosAsset();
      case UpdatePlatform.windows:
        return release.getWindowsAsset();
      default:
        return null;
    }
  }

  bool get hasPlatformAsset => getPlatformAsset()?.isEmpty == false;
}

enum UpdatePlatform { android, ios, windows, macos, linux, unknown }
