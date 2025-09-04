import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class HeartbeatCard extends StatefulWidget {
  const HeartbeatCard({super.key});

  @override
  State<HeartbeatCard> createState() => _HeartbeatCardState();
}

class _HeartbeatCardState extends State<HeartbeatCard>
    with SingleTickerProviderStateMixin {
  int _heartRate = 70;
  late Timer _timer;

  late AnimationController _beatController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Heartbeat animation
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _beatController, curve: Curves.easeInOut),
    );

    _beatController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _beatController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _beatController.forward();
      }
    });

    _beatController.forward();

    // Fake heart rate data
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _heartRate = 60 + Random().nextInt(40); // 60-100 bpm
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _beatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: const Icon(Icons.favorite, size: 80, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          Text(
            '$_heartRate bpm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Heart Rate',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
