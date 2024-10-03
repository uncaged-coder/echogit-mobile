import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echogit_mobile/providers/project_provider.dart';

class DebugLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final log = Provider.of<ProjectProvider>(context).log;

    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Log'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(log),
      ),
    );
  }
}
