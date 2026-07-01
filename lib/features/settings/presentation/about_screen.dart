import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About this app'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Version',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                return Text(
                  'Gwen - v$version',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Your data is saved locally on your phone and never shared with anyone. Your safety is our absolute priority.',
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Who built this app?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This app is for anxiety relief. It was built by me. I am a software engineer and a mental health advocate. I built this app to help people like you manage anxiety and find relief.',
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
