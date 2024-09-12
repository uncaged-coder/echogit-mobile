import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:convert';
import 'dart:io';

class ProjectProvider extends ChangeNotifier {
  List<String> _localProjects = [];
  List<String> _remoteProjects = [];
  String _log = '';
  bool enableLogging = true; // Enable logging by default

  String host = '';
  String username = '';
  String password = '';
  String localPath = '';
  String remotePath = '';
  int port = 22;

  final String _configFileName = 'echogit_config.json';
  static const platform = MethodChannel('com.example.echogit_mobile/termux');

  List<String> get localProjects => _localProjects;
  List<String> get remoteProjects => _remoteProjects;
  String get log => _log;

  ProjectProvider() {
    _loadConfiguration();
  }

  List<Map<String, dynamic>> get allProjects {
    return [
      ..._localProjects.map((project) => {'name': project, 'isLocal': true}),
      ..._remoteProjects.map((project) => {'name': project, 'isLocal': false}),
    ];
  }

  Future<void> _loadConfiguration() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, _configFileName));
      if (await file.exists()) {
        final contents = await file.readAsString();
        final config = json.decode(contents);
        localPath = config['localPath'] ?? '';
        remotePath = config['remotePath'] ?? '';
        host = config['host'] ?? '';
        username = config['username'] ?? '';
        password = config['password'] ?? '';
        port = config['port'] ?? 22;
        _localProjects = List<String>.from(config['localProjects'] ?? []);
        _remoteProjects = List<String>.from(config['remoteProjects'] ?? []);
      }
    } catch (e) {
      _logMessage('Failed to load configuration: $e');
    }
    notifyListeners();
  }

  Future<void> _saveConfiguration() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, _configFileName));
      final config = {
        'localPath': localPath,
        'remotePath': remotePath,
        'port': port,
        'host': host,
        'username': username,
        'password': password, /* FIXME */
        'localProjects': _localProjects,
        'remoteProjects': _remoteProjects,
      };
      await file.writeAsString(json.encode(config));
    } catch (e) {
      _logMessage('Failed to save configuration: $e');
    }
  }

  Future<List<String>> _listLocalProjects() async {
    try {
      final dir = Directory(localPath);
      if (await dir.exists()) {
        return dir.listSync().whereType<Directory>().map((d) => path.basename(d.path)).toList();
      }
    } catch (e) {
      _logMessage('Error listing local projects: $e');
    }
    return [];
  }

  Future<String> executeCommand(String command, String workingDirectory) async {
    if (Platform.isAndroid) {
      _logMessage("Attempting to execute command on Android using Termux...");

      try {
        // Call the platform channel to execute the command
        final result = await platform.invokeMethod(
          'executeTermuxCommand',
          {
            'command': command,
            'workingDirectory': workingDirectory,
          },
        );
        _logMessage('Command executed successfully on Android: $result');

        if (result != null) {
          final stdout = result['stdout'] ?? 'No stdout';
          final stderr = result['stderr'] ?? 'No stderr';
          final exitCode = result['exitCode'] ?? 'Unknown exit code';

          _logMessage('Command executed successfully on Android:\n'
                      'stdout: $stdout\nstderr: $stderr\nexitCode: $exitCode');

          return 'stdout: $stdout\nstderr: $stderr\nexitCode: $exitCode';
        } else {
          _logMessage('No output from Termux command.');
          return 'No output';
        }
      } catch (e) {
        _logMessage('Error executing command on Android: $e');
        return 'Error executing command on Android: $e';
      }
    } else if (Platform.isLinux) {
      _logMessage("Attempting to execute command on Linux...");
      try {
        final result = await Process.run(
          'bash', ['-c', command],
          workingDirectory: workingDirectory,
        );
        if (result.exitCode == 0) {
          _logMessage('Command executed successfully on Linux: ${result.stdout}');
          return result.stdout;
        } else {
          _logMessage('Error executing command on Linux: ${result.stderr}');
          return result.stderr;
        }
      } catch (e) {
        _logMessage('Error executing command on Linux: $e');
        return 'Error executing command on Linux: $e';
      }
    } else {
      _logMessage('Unsupported platform.');
      return 'Unsupported platform.';
    }
  }

  /// Updated discoverProjects to use executeCommand and remote SSH
  void discoverProjects() async {
    username='abdel';
    host='192.168.1.5';
    port = 22;
    remotePath="/tmp/test/";

    _logMessage("will discover");
    try {
      final command1 = '/data/data/com.termux/files/home/.termux/tasker/tutu.sh';
      String result1 = await executeCommand(command1, '/data/data/com.termux/files/home/.termux/');
      _logMessage(result1);
/*
      // Execute remote SSH command to discover projects
      final command = 'ssh $username@$host -p $port "find $remotePath -type d -name .echogit -exec dirname {} \\;"';
      String result = await executeCommand(command, localPath);

      _remoteProjects = result.split('\n').where((line) => line.trim().isNotEmpty).toList();

      // Check for local projects
      _localProjects = await _listLocalProjects();

      _logMessage('Discovered projects:\nLocal: ${_localProjects.join(', ')}\nRemote: ${_remoteProjects.join(', ')}');
      await _saveConfiguration();
      */
    } catch (e) {
      _logMessage('Error discovering projects: $e');
    }

    notifyListeners();
  }

  Future<void> cloneProject(String remoteProject) async {
    username='abdel';
    host='192.168.1.5';
    port = 22;
    remotePath="/tmp/test/";
    _logMessage("in cloneProject");
    try {
      // Extract the project name from the remote path
      final projectName = remoteProject.split('/').last;
      // Construct the full local path for the new project directory
      final projectDirectory = Directory(path.join(localPath, projectName));

      // Ensure the local directory exists (create if it does not exist)
      //await projectDirectory.create(recursive: true);

      _logMessage("cloning...");  // Log the result or handle further

      // Construct the Git clone command
      final command = 'git clone ssh://$username@$host:$port/$remoteProject';

      // Execute the Git command with the local path as the working directory
      String result = await executeCommand(command, localPath);

      _logMessage(result);  // Log the result or handle further

      // Update the project lists
      _localProjects.add(projectName);
      _remoteProjects.remove(remoteProject);

      _logMessage('Cloned project: $remoteProject to $projectDirectory');
      await _saveConfiguration();
    } catch (e) {
      _logMessage('Error cloning project $remoteProject: $e');
    }
    notifyListeners();
  }

  void _logMessage(String message) {
    if (enableLogging) {
      _log += '$message\n';
    }
  }
}
