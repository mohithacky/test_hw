import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deploy App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(body: Center(child: DeployButton())),
    );
  }
}

class DeployButton extends StatefulWidget {
  const DeployButton({super.key});

  @override
  State<DeployButton> createState() => _DeployButtonState();
}

class _DeployButtonState extends State<DeployButton> {
  bool _loading = false;
  String _message = "Ready to deploy!";
  Timer? _pollTimer;

  Future<void> _triggerDeploy() async {
    setState(() {
      _loading = true;
      _message = "🚀 Starting deployment...";
    });
    print("--- TRIGGERING DEPLOYMENT ---");

    try {
      final deployUri = Uri.parse("https://api-5sqqk2n6ra-uc.a.run.app/deploy");
      final response = await http.post(
        deployUri,
        headers: {"x-deploy-key": "super_secret_key"},
      );
      print(
        "Deploy trigger response: ${response.statusCode} - ${response.body}",
      );
      _startPollingStatus();
    } catch (e) {
      print("Error triggering deploy: $e");
      setState(() {
        _loading = false;
        _message = "❌ Failed to trigger deploy.";
      });
    }
  }

  void _startPollingStatus() {
    print("--- STARTING STATUS POLLING ---");
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      print("Polling for status...");
      try {
        final statusUri = Uri.parse(
          "https://api-5sqqk2n6ra-uc.a.run.app/deploy-status",
        );
        final response = await http.get(statusUri);
        print(
          "Deploy status response: ${response.statusCode} - ${response.body}",
        );

        final data = jsonDecode(response.body);
        final status = data['status'];
        final conclusion = data['conclusion'];

        print("Current status: $status, Conclusion: $conclusion");

        setState(() {
          if (status == "queued" || status == "in_progress") {
            _message = "⚙️ Building and deploying...";
          } else if (status == "completed" && conclusion == "success") {
            _message = "✅ Deployment successful!";
            _loading = false;
            _pollTimer?.cancel();
            print("--- POLLING STOPPED (SUCCESS) ---");
          } else if (status == "completed" && conclusion != "success") {
            _message = "❌ Deployment failed.";
            _loading = false;
            _pollTimer?.cancel();
            print("--- POLLING STOPPED (FAILURE) ---");
          }
        });
      } catch (e) {
        print("Error polling status: $e");
        setState(() {
          _message = "❌ Error fetching status.";
          _loading = false;
          _pollTimer?.cancel();
          print("--- POLLING STOPPED (ERROR) ---");
        });
      }
    });
  }

  @override
  void dispose() {
    print("--- DISPOSING WIDGET, CANCELLING TIMER ---");
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _triggerDeploy,
          icon: const Icon(Icons.cloud_upload),
          label: Text(_loading ? "Deploying..." : "Host Website"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        Text(_message, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
