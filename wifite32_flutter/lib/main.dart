import 'package:flutter/material.dart';

void main() {
  runApp(const Wifite32App());
}

class Wifite32App extends StatelessWidget {
  const Wifite32App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wifite32',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ScanTab(),
    AttackTab(),
    LogTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wifite32')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Attack'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Log'),
        ],
      ),
    );
  }
}

class ScanTab extends StatelessWidget {
  const ScanTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Scan Networks\n(Connect USB device)'));
  }
}

class AttackTab extends StatelessWidget {
  const AttackTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Attack Screen'));
  }
}

class LogTab extends StatelessWidget {
  const LogTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Log Screen'));
  }
}