import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/release_info.dart';

class InstallerService {
  static final InstallerService _instance = InstallerService._internal();
  factory InstallerService() => _instance;
  InstallerService._internal();

  final Dio _dio = Dio();

  Future<InstallResult> installUpdate(
    ReleaseAsset asset, {
    void Function(int, int)? onProgress,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${asset.name}';

      final file = File(savePath);
      if (await file.exists()) await file.delete();

      await _dio.download(
        asset.downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (Platform.isAndroid) {
        return _installAndroid(savePath);
      } else if (Platform.isWindows) {
        return _installWindows(savePath);
      } else {
        final result = await OpenFile.open(savePath);
        return InstallResult(
          success: result.type == ResultType.done,
          message: result.message,
        );
      }
    } catch (e) {
      return InstallResult(success: false, message: e.toString());
    }
  }

  Future<InstallResult> _installAndroid(String path) async {
    try {
      final result = await OpenFile.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      return InstallResult(
        success:
            result.type == ResultType.done || result.type == ResultType.noAppToOpen,
        message: result.message,
      );
    } catch (e) {
      return InstallResult(success: false, message: e.toString());
    }
  }

  Future<InstallResult> _installWindows(String path) async {
    try {
      final result = await OpenFile.open(path);
      return InstallResult(
        success: result.type == ResultType.done,
        message: result.message,
      );
    } catch (e) {
      return InstallResult(success: false, message: e.toString());
    }
  }

  Future<bool> openReleasePage(String htmlUrl) async {
    try {
      final url = Uri.parse(htmlUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class InstallResult {
  final bool success;
  final String message;
  InstallResult({required this.success, required this.message});
}
