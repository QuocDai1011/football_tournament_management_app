import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../seed_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedScreen extends ConsumerStatefulWidget {
  const SeedScreen({super.key});

  @override
  ConsumerState<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends ConsumerState<SeedScreen> {
  bool _running = false;
  final List<String> _logs = [];

  void _append(String s) {
    setState(() => _logs.insert(0, '${DateTime.now().toIso8601String()} - $s'));
  }

  Future<void> _generate() async {
    setState(() => _running = true);
    final service = SeedService(firestore: FirebaseFirestore.instance);
    try {
      await service.generateFakeData(onLog: (s) => _append(s));
      _append('Generation finished');
    } catch (e) {
      _append('Error: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _running = true);
    final service = SeedService(firestore: FirebaseFirestore.instance);
    try {
      await service.resetDatabase(onLog: (s) => _append(s));
      _append('Reset finished');
    } catch (e) {
      _append('Error: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _reseed() async {
    setState(() => _running = true);
    final service = SeedService(firestore: FirebaseFirestore.instance);
    try {
      await service.reseed(onLog: (s) => _append(s));
      _append('Reseed finished');
    } catch (e) {
      _append('Error: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _running ? null : _generate,
                  child: const Text('Generate Fake Data'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _running ? null : _reset,
                  child: const Text('Reset Database'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _running ? null : _reseed,
                  child: const Text('Reseed'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_running) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, i) => Text(_logs[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
