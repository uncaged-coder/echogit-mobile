import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echogit_mobile/providers/project_provider.dart';
import 'package:echogit_mobile/screens/project_settings_screen.dart';

class ProjectTile extends StatefulWidget {
  final Project project;

  const ProjectTile({Key? key, required this.project}) : super(key: key);

  @override
  _ProjectTileState createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  bool _isSyncing = false;
  bool _isCloning = false; // State for tracking the cloning process

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final projectName = project.name;
    final projectPath = project.path;
    final isLocal = project.isLocal;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: isLocal ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isLocal ? Colors.blue : Colors.green,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          projectName,
          style: TextStyle(
            color: isLocal ? Colors.blue[900] : Colors.green[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(
          isLocal ? Icons.computer : Icons.cloud,
          color: isLocal ? Colors.blue : Colors.green,
        ),
        trailing: isLocal
            ? Row(
                mainAxisSize: MainAxisSize.min, // This ensures the Row takes up only the necessary space
                children: [
                  IconButton(
                    icon: Icon(Icons.info, color: Colors.blue[700]),
                    onPressed: () {
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.blue[700]),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProjectSettingsScreen(projectPath)),
                    ),
                  ),
                  IconButton(
                    icon: _isSyncing
                        ? CircularProgressIndicator(
                            color: Colors.blue[700],
                          )
                        : Icon(Icons.sync, color: Colors.blue[700]),
                    onPressed: () async {
                      setState(() {
                        _isSyncing = true;
                      });

                      final provider = Provider.of<ProjectProvider>(context, listen: false);
                      await provider.sync(projectPath);

                      setState(() {
                        _isSyncing = false;
                      });
                    },
                  ),
                ],
              )
            : IconButton(
                icon: _isCloning
                    ? CircularProgressIndicator(
                        color: Colors.green[700],
                      )
                    : Icon(Icons.download, color: Colors.green[700]),
                onPressed: () async {
                  setState(() {
                    _isCloning = true;
                  });

                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  await provider.cloneProject(projectPath);

                  setState(() {
                    _isCloning = false;
                  });
                },
              ),
        onTap: () {
          // Handle tap on the project item if needed
        },
      ),
    );
  }
}
