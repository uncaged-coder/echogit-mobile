import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:io';

class ProjectProvider extends ChangeNotifier {
  List<String> _localProjects = [];
  List<String> _remoteProjects = [];
  String _log = '';
  bool enableLogging = true; // Enable logging by default
  SSHClient? _client;

  String host = '';
  String username = '';
  String password = '';
  String localPath = '';
  String remotePath = '';
  int port = 22;

  final String _configFileName = 'echogit_config.json';

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

  void connect(String host, String username, String password, String remotePath, String localPath, int port) async {
    this.remotePath = remotePath;
    this.localPath = localPath;
    this.host = host;
    this.username = username;
    this.password = password; /* FIXME */
    this.port = port;
    await _saveConfiguration();

    try {
      _client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );

      _logMessage('Connected to $host');
      discoverProjects();
    } catch (e) {
      _logMessage('Error connecting: $e');
    }

    notifyListeners();
  }

  void discoverProjects() async {
    try {
      // Discover remote projects with .echogit folders
      final result = await _client!.run("find $remotePath -type d -name .echogit -exec dirname {} \\;");
      var result2 = utf8.decode(result);
      _remoteProjects = result2.split('\n').where((line) => line.trim().isNotEmpty).toList();

      // Check for local projects
      _localProjects = await _listLocalProjects();

      _logMessage('Discovered projects:\nLocal: ${_localProjects.join(', ')}\nRemote: ${_remoteProjects.join(', ')}');
      await _saveConfiguration();
    } catch (e) {
      _logMessage('Error discovering projects: $e');
    }

    notifyListeners();
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

  void cloneProject(String remoteProject) async {
    try {
      // Clone the project from the remote to the local path
      print("git clone");
      await _client!.run('git clone $remoteProject $localPath/${remoteProject.split('/').last}');

      _localProjects.add(remoteProject.split('/').last);
      _remoteProjects.remove(remoteProject);

      _logMessage('Cloned project: $remoteProject to $localPath');
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
