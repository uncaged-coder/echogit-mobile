import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:io';

class Project {
  final String name;
  final String path;
  final bool isLocal;

  Project(String name, String path, this.isLocal)
      : name = name,
        path = _cleanPath(path);

  // Method to remove ".git" from the end of the path
  static String _cleanPath(String path) {
    if (path.endsWith(".git/")) {
      return path.substring(0, path.length - 5);
    } else if (path.endsWith(".git")) {
      return path.substring(0, path.length - 4);
    }
    return path;
  }

  @override
  String toString() => "$name (${isLocal ? 'Local' : 'Remote'})";
}

class ProjectProvider extends ChangeNotifier {
  List<Project> _ownedProjects = [];
  List<Project> _remoteProjects = [];
  String _log = "";
  bool enableLogging = true;
  bool? _ignorePeersDown;
  String? _projectsPath;

  static const platform = MethodChannel("com.uncaged.echogit_mobile/termux");

  List<Project> get ownedProjects => _ownedProjects;
  List<Project> get remoteProjects => _remoteProjects;
  String get log => _log;

  ProjectProvider() {
  }

  List<Project> get allProjects {
    return [
      ..._ownedProjects,
      ..._remoteProjects,
    ];
  }

  Future<Map<String, dynamic>> _runOnAndroid(String echogitCommand) async {

    final homePath = "/data/data/com.termux/files/home";
    final taskerPath = "$homePath/.termux/tasker/";
    final String command = "$taskerPath/echogit.sh";

    final result = await platform.invokeMethod(
      "executeTermuxCommand",
      {
        "command": command,
        "arguments": echogitCommand,
        "workingDirectory": taskerPath,
      },
    );
    return {
      "stdout": result["stdout"] ?? "No stdout",
      "stderr": result["stderr"] ?? "No stderr",
      "exitCode": result["exitCode"] ?? -1
    };
  }

  Future<Map<String, dynamic>> _runOnLinux(String echogitCommand) async {
    // FIXME: Remove this hard coded path.
    // Note that this is only for linux target, which is implemented only
    // to help on development and testing purpose.
    final echogitPath = "/zdata/data/desk/echogit/";
    final String command = "python3 $echogitPath/echogit.py $echogitCommand";

    final result = await Process.run(
      "bash", ["-c", command],
      //workingDirectory: homePath,
    );
    return {
      "stdout": result.stdout ?? "No stdout",
      "stderr": result.stderr ?? "No stderr",
      "exitCode": result.exitCode ?? -1
    };
  }

  Future<Map<String, dynamic>> executeCommand(String command) async {
    try {
      Map<String, dynamic> result;
      if (Platform.isAndroid) {
        result = await _runOnAndroid(command);
      } else if (Platform.isLinux || Platform.isMacOS) {
        result = await _runOnLinux(command);
      } else {
        return {
          "stdout": "",
          "stderr": "Unsupported platform",
          "exitCode": -1
        };
      }

      _logMessage(
        "Command executed:\nstdout: ${result['stdout']}\nstderr: ${result['stderr']}\nexitCode: ${result['exitCode']}"
      );

      return result;
    } catch (e) {
      _logMessage("Error executing command: $e");
      return {
        "stdout": "",
        "stderr": "Error executing command: $e",
        "exitCode": -1
      };
    }
  }

  Future<Map<String, dynamic>> getEchogitConfig() async {
    if (_ignorePeersDown == null || _projectsPath == null) {
      final command = "config -g";

      // Execute the command
      final result = await executeCommand(command);

      // Extract the stdout from the result
      final String output = result["stdout"] ?? "No stdout";

      // Extract the values from the stdout string
      final dataPathRegEx = RegExp(r"Data Path: (.*)");
      final ignorePeersDownRegEx = RegExp(r"Ignore peers down: (true|false)");
      final echogitBinRegEx = RegExp(r"Echogit bin: (.*)");
      _projectsPath = dataPathRegEx.firstMatch(output)?.group(1)?.trim();
      _ignorePeersDown = ignorePeersDownRegEx.firstMatch(output)?.group(1) == 'true';
    }

    return {
      'ignorePeersDown': _ignorePeersDown,
      'projectsPath': _projectsPath,
    };
  }

  Future<void> setEchogitConfig(String projectPath, bool ignorePeersDown) async {
    if (_ignorePeersDown != ignorePeersDown || _projectsPath != projectPath) {
      _ignorePeersDown = ignorePeersDown;
      _projectsPath = projectPath;

      final command = "config -s 'ignore_peers_down:$ignorePeersDown, projects_path=$projectPath'";
      final result = await executeCommand(command);

      // TODO: Add logic to check success in 'result'
    }
  }

  void loadProjects(bool useCache) async {
    _logMessage("Loading projects ...");
    _ownedProjects.clear();
    _remoteProjects.clear();
    try {
      final command = useCache ? "list --remote -c" : "list --remote";

      final result = await executeCommand(command);
      final projects = _parseProjectsOutput(result["stdout"]);

      if (projects != null) {
        final ours = projects["ours"] ?? {};
        final available = projects["available"] ?? {};

        _logMessage("Discovered projects:");
        _logMessage("Ours: $ours");
        _logMessage("Available: $available");

        _ownedProjects = ours.keys.map((path) => Project(ours[path]!, path, true)).toList();
        _remoteProjects = available.keys.map((path) => Project(available[path]!, path, false)).toList();
      } else {
        _logMessage("No valid projects discovered.");
      }
    } catch (e) {
      _logMessage("Error discovering projects: $e");
    }

    notifyListeners();
  }

  Map<String, Map<String, String>>? _parseProjectsOutput(String output) {
    try {
      final oursRegex = RegExp(r"Local projects:\s*\{(.*?)\}", dotAll: true);
      final availableRegex = RegExp(r"Available remote projects:\s*\{(.*?)\}", dotAll: true);

      // Find the local projects section (mandatory)
      final oursMatch = oursRegex.firstMatch(output);
      if (oursMatch == null) {
        // Fail if no local projects are found
        _logMessage("Error: No valid 'local' projects section found in the output.");
        return null;
      }

      // Extract and parse local projects
      final oursStr = oursMatch.group(1)!;
      final ours = _parseProjectSection(oursStr);

      // Find the available remote projects section (optional)
      final availableMatch = availableRegex.firstMatch(output);
      final availableStr = availableMatch?.group(1) ?? ""; // If missing, treat as empty string
      final available = _parseProjectSection(availableStr);

      // Return the parsed maps
      return {
        "ours": ours,
        "available": available, // Can be empty if no available projects are found
      };

    } catch (e) {
      _logMessage("Error parsing projects output: $e");
      return null;
    }
  }

  Map<String, String> _parseProjectSection(String section) {
    final projectMap = <String, String>{};

    final projectPairs = section.split(",");
    for (var pair in projectPairs) {
      final parts = pair.split(":");
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll("'", "");
        final value = parts[1].trim().replaceAll("'", "");
        projectMap[key] = value;
      }
    }

    return projectMap;
  }

  Future<void> cloneProject(String remoteProject) async {
    final command = "clone $_projectsPath/$remoteProject";
    _logMessage("execute command: $command");
    final result = await executeCommand(command);
    _logMessage("command result: $result");
    notifyListeners();
  }

  Future<void> sync([String projectDir = ""]) async {
    String path = "";
    if (projectDir.isNotEmpty) {
      path = "$_projectsPath/$projectDir";
    }

    _logMessage("execute command: sync");
    final result = await executeCommand("sync $path");
    _logMessage("command result: $result");
    notifyListeners();
  }

  void _logMessage(String message) {
    if (enableLogging) {
      _log += "$message\n";
    }
  }
}
