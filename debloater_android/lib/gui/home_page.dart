import 'package:flutter/material.dart';
import 'package:debloater_android/core/debloater_service.dart';
import 'package:device_apps/device_apps.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DebloaterService debloaterService = DebloaterService();
  List<Application> installedApps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    installedApps = await debloaterService.listInstalledApps();
    setState(() {
      isLoading = false; // Stop loading
    });
  }

  void _debloatApp(String packageName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Debloat'),
          content: Text('Are you sure you want to debloat this application?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Debloat'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await debloaterService.debloatApp(packageName);
      _loadInstalledApps(); // Refresh the list after debloating
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debloater Android')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: installedApps.length,
                itemBuilder: (context, index) {
                  final app = installedApps[index];
                  return ListTile(
                    title: Text(app.appName),
                    subtitle: Text(app.packageName),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _debloatApp(app.packageName),
                      tooltip: 'Debloat',
                    ),
                  );
                },
              ),
    );
  }
}
