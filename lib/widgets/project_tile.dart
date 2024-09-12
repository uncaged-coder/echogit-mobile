import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echogit_mobile/providers/project_provider.dart';

class ProjectTile extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectTile({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: project['isLocal'] ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: project['isLocal'] ? Colors.blue : Colors.green,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          project['name'],
          style: TextStyle(
            color: project['isLocal'] ? Colors.blue[900] : Colors.green[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(
          project['isLocal'] ? Icons.computer : Icons.cloud,
          color: project['isLocal'] ? Colors.blue : Colors.green,
        ),
        trailing: project['isLocal']
            ? null
            : IconButton(
                icon: Icon(Icons.download, color: Colors.green[700]),
                onPressed: () {
                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  provider.cloneProject(project['name']);
                },
              ),
        onTap: () {
          // Additional actions on tap can be defined here
        },
      ),
    );
  }
}
