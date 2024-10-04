import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:echogit_mobile/providers/project_provider.dart';

class ProjectSettingsScreen extends StatefulWidget {
  final String projectPath;

  // Constructor
  ProjectSettingsScreen(this.projectPath);

  @override
  _ProjectSettingsScreenState createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _autoCommit = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Fetches the settings from the provider using projectPath
  void _loadSettings() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    // Pass the projectPath to load the specific project configuration
    final config = await provider.getProjectConfig(widget.projectPath);

    setState(() {
      _autoCommit = config['autoCommit'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Project settings for ${widget.projectPath}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _autoCommit,
                    onChanged: (bool? value) {
                      setState(() {
                        _autoCommit = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Auto commit any changes when syncing',
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await provider.setProjectConfig(widget.projectPath, _autoCommit);
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
