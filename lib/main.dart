import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(NehalGame());
}

class NehalGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nehal's Game",
      theme: ThemeData.dark(),
      home: FlappyBirdGame(),
    );
  }
}

class FlappyBirdGame extends StatefulWidget {
  @override
  State<FlappyBirdGame> createState() => _FlappyBirdGameState();
}

class _FlappyBirdGameState extends State<FlappyBirdGame> {
  static const double gravity = 0.4;
  static const double jumpVelocity = -8;
  static const double birdSize = 40;
  static const double pipeWidth = 60;
  static const double gapHeight = 200;
  static const double pipeSpeed = 3;

  double birdY = 300;
  double velocity = 0;
  double pipeX = 400;
  double gapY = 250;
  bool isGameRunning = false;
  int score = 0;
  Timer? gameLoop;

  void startGame() {
    isGameRunning = true;
    birdY = 300;
    velocity = 0;
    pipeX = MediaQuery.of(context).size.width;
    gapY = Random().nextInt(250) + 150;
    score = 0;

    gameLoop?.cancel();
    gameLoop = Timer.periodic(Duration(milliseconds: 16), (_) {
      setState(() {
        velocity += gravity;
        birdY += velocity;
        pipeX -= pipeSpeed;

        if (pipeX < -pipeWidth) {
          pipeX = MediaQuery.of(context).size.width;
          gapY = Random().nextInt(250) + 150;
          score++;
        }

        if (checkCollision()) {
          gameLoop?.cancel();
          isGameRunning = false;
          logDeviceData(score); // Log to Firebase
        }
      });
    });
  }

  void jump() {
    if (!isGameRunning) {
      startGame();
    }
    setState(() {
      velocity = jumpVelocity;
    });
  }

  bool checkCollision() {
    final screenHeight = MediaQuery.of(context).size.height;
    if (birdY < 0 || birdY + birdSize > screenHeight) return true;
    if (pipeX < 100 && pipeX + pipeWidth > 60) {
      if (birdY < gapY || birdY + birdSize > gapY + gapHeight) {
        return true;
      }
    }
    return false;
  }

  Future<void> logDeviceData(int score) async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    await FirebaseFirestore.instance.collection('user_device_data').add({
      'score': score,
      'model': androidInfo.model,
      'manufacturer': androidInfo.manufacturer,
      'androidVersion': androidInfo.version.release,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Stack(
          children: [
            Positioned(
              left: 60,
              top: birdY,
              child: Container(
                width: birdSize,
                height: birdSize,
                decoration: BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              left: pipeX,
              top: 0,
              child: Container(
                width: pipeWidth,
                height: gapY,
                color: Colors.green,
              ),
            ),
            Positioned(
              left: pipeX,
              top: gapY + gapHeight,
              child: Container(
                width: pipeWidth,
                height: MediaQuery.of(context).size.height - gapY - gapHeight,
                color: Colors.green,
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'Score: $score',
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Text(
                "Nehal's Game",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
                },
                child: Text('About'),
              ),
            ),
            if (!isGameRunning)
              Center(
                child: Text(
                  'TAP TO START',
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text("About Nehal's Game"),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Developer', style: TextStyle(fontSize: 22, color: Colors.white70)),
            SizedBox(height: 8),
            Text('Nehal Sayyed', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Text('Game Title', style: TextStyle(fontSize: 22, color: Colors.white70)),
            SizedBox(height: 8),
            Text("Nehal's Game", style: TextStyle(fontSize: 24, color: Colors.white)),
            SizedBox(height: 24),
            Text('Description', style: TextStyle(fontSize: 22, color: Colors.white70)),
            SizedBox(height: 8),
            Text(
              'A simple Flappy Bird-style game built entirely with Flutter widgets. No images, no assets — just pure code and creativity!',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
