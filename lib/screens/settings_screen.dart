import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echogit_mobile/providers/project_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController();
  final _localPathController = TextEditingController();
  final _portController = TextEditingController(text: '22');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    setState(() {
      _hostController.text = provider.host;
      _usernameController.text = provider.username;
      _passwordController.text = provider.password;
      _remotePathController.text = provider.remotePath;
      _localPathController.text = provider.localPath;
      _portController.text = provider.port.toString();
    });
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
              TextFormField(
                controller: _hostController,
                decoration: InputDecoration(labelText: 'Host IP'),
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextFormField(
                controller: _remotePathController,
                decoration: InputDecoration(labelText: 'Remote Path'),
              ),
              TextFormField(
                controller: _localPathController,
                decoration: InputDecoration(labelText: 'Local Path'),
              ),
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  provider.discoverProjects();
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
