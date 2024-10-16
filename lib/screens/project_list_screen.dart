import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echogit_mobile/providers/project_provider.dart';
import 'package:echogit_mobile/screens/settings_screen.dart';
import 'package:echogit_mobile/screens/debug_log_screen.dart';
import 'package:echogit_mobile/widgets/project_tile.dart';

class ProjectListScreen extends StatefulWidget {
  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    // Load local projects at startup
    provider.loadProjects(true);
  }

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
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DebugLogScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: provider.allProjects.length,
        itemBuilder: (context, index) {
          final project = provider.allProjects[index];
          return ProjectTile(project: project);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            _isSyncing = true;
          });

          await provider.sync();

          setState(() {
            _isSyncing = false;
          });
        },
        // Show a progress indicator when syncing
        child: _isSyncing
            ? CircularProgressIndicator(
                color: Colors.white,
              )
            : Icon(Icons.sync),
        tooltip: _isSyncing ? 'Syncing...' : 'Sync All Projects',
      ),
    );
  }
}
