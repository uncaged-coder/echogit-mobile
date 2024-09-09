import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ssh2/ssh2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echogit Mobile',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ProjectListScreen(),
    );
  }
}

class ProjectProvider extends ChangeNotifier {
  List<String> _projects = [];
  SSHClient? _client;
  String _log = '';

  List<String> get projects => _projects;
  String get log => _log;

  void connect(String host, String username, String privateKey) async {
    _client = SSHClient(
      host: host,
      port: 22,
      username: username,
      privateKey: privateKey,
    );

    try {
      String result = await _client!.connect();
      if (result == 'session_connected') {
        _log += 'Connected to $host\n';
        _discoverProjects();
      }
    } catch (e) {
      _log += 'Connection error: $e\n';
    }

    notifyListeners();
  }

  void _discoverProjects() async {
    if (_client == null) return;

    try {
      // Discover projects with .echogit folder
      String result = await _client!.execute(
          'find /path/to/scan -type d -name ".echogit" -exec dirname {} \\;');
      _projects = result.split('\n').where((dir) => dir.isNotEmpty).toList();
      _log += 'Discovered projects: ${_projects.join(', ')}\n';
    } catch (e) {
      _log += 'Error discovering projects: $e\n';
    }

    notifyListeners();
  }

  void syncProject(String projectPath) async {
    if (_client == null) return;

    try {
      // Sync commands
      await _client!.execute('cd $projectPath && git add -A .');
      await _client!.execute('cd $projectPath && git commit -m "Sync from echogit mobile"');
      await _client!.execute('cd $projectPath && git push');
      await _client!.execute('cd $projectPath && git pull');
      _log += 'Synced project: $projectPath\n';
    } catch (e) {
      _log += 'Error syncing project $projectPath: $e\n';
    }

    notifyListeners();
  }
}

class ProjectListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: provider.projects.length,
        itemBuilder: (context, index) {
          final project = provider.projects[index];
          return ListTile(
            title: Text(project),
            onTap: () => provider.syncProject(project),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => provider._discoverProjects(), // Manual refresh
        child: Icon(Icons.refresh),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _privateKeyController = TextEditingController();

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
                controller: _privateKeyController,
                decoration: InputDecoration(labelText: 'Private Key Path'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  provider.connect(
                    _hostController.text,
                    _usernameController.text,
                    _privateKeyController.text,
                  );
                  Navigator.pop(context);
                },
                child: Text('Save & Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
