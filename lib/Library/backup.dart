import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<void> backupDatabaseDesktop(BuildContext context) async {
  try {
    // If your DB is in app's current directory
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDocDir.path, 'Invoxel.db'));

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
