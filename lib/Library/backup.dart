import 'dart:io';
import 'package:flutter/material.dart';

Future<void> backupDatabaseDesktop(BuildContext context) async {
  try {
    // If your DB is in app's current directory
    final dbFile = File('Invoxel.db');

    if (!await dbFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database file not found')),
      );
      return;
    }

    // Get Desktop folder path based on OS
    Directory? desktopDir;

    if (Platform.isWindows) {
      desktopDir = Directory('${Platform.environment['USERPROFILE']}\\Desktop');
    } else if (Platform.isMacOS || Platform.isLinux) {
      desktopDir = Directory('${Platform.environment['HOME']}/Desktop');
    } else {
      desktopDir = Directory.current;
    }

    final backupFilePath = '${desktopDir.path}/Invoxel_backup_${DateTime.now().millisecondsSinceEpoch}.db';

    await dbFile.copy(backupFilePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup saved to: $backupFilePath')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup failed: $e')),
    );
  }
}
