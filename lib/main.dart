import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echogit_mobile/providers/project_provider.dart';
import 'package:echogit_mobile/screens/project_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProjectProvider(),
      child: MaterialApp(
        title: 'Echogit Mobile',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ProjectListScreen(),
      ),
    );
  }
}
