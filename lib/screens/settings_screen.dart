import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:echogit_mobile/providers/project_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectsPathController = TextEditingController();
  bool _ignorePeersDown = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Fetches the settings from the provider
  void _loadSettings() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    final config = await provider.getEchogitConfig();

    setState(() {
      _projectsPathController.text = config['projectsPath'] ?? "";
      _ignorePeersDown = config['ignorePeersDown'] ?? false;
    });
  }

  void _selectProjectPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _projectsPathController.text = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Row to show and change the projects path
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _projectsPathController,
                      decoration: InputDecoration(labelText: 'Projects path'),
                      readOnly: true,  // Field is read-only; value is updated via file picker
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.folder_open),
                    onPressed: _selectProjectPath,
                  ),
                ],
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: _ignorePeersDown,
                    onChanged: (bool? value) {
                      setState(() {
                        _ignorePeersDown = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Ignore peer down: When enabled, sync will ignore errors when a peer is unavailable (e.g., PC is shut down).',
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  await provider.setEchogitConfig(
                    _projectsPathController.text,
                    _ignorePeersDown,
                  );

                  provider.loadProjects(false);
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
