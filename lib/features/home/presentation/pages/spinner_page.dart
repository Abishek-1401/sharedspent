import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class SpinnerPage extends StatefulWidget {
  final List<Map<String, dynamic>> roommates;
  const SpinnerPage({super.key, required this.roommates});

  @override
  State<SpinnerPage> createState() => _SpinnerPageState();
}

class _SpinnerPageState extends State<SpinnerPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spin the Wheel!')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: FortuneWheel(
              selected: Stream<int>.value(_selectedIndex),
              items: [
                for (var roommate in widget.roommates)
                  FortuneItem(child: Text(roommate['username'] ?? '...')),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndex = Random().nextInt(widget.roommates.length);
              });
            },
            child: const Text('Spin!'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, widget.roommates[_selectedIndex]);
            },
            child: const Text('Select Winner'),
          ),
        ],
      ),
    );
  }
}
