import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';


void main() {
  runApp(const SleepDetectionApp());
}

class SleepDetectionApp extends StatelessWidget {
  const SleepDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleep / Pupil Detection',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String status = "Stopped";
  int framesLost = 0;
  bool alarmOn = false;
  bool isMuted = false;

  Timer? pollTimer;

  @override
  void initState() {
    super.initState();

    // Poll backend every second
    pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final data = await ApiService.getState();
      setState(() {
        status = data["status"];
        framesLost = data["framesLost"];
        alarmOn = data["alarmOn"];
        isMuted = data["muted"];
      });
    });
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sleep / Pupil Detection"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔴 VIDEO STREAM
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Mjpeg(
                  stream: "http://127.0.0.1:8000/video",
                  isLive: true,
                  fit: BoxFit.cover,
                  error: (context, error, stack) {
                    return const Center(
                      child: Text(
                        "Video stream not available",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),


            const SizedBox(height: 20),

            // 🔹 STATUS
            Text(
              "Status: $status",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 8),

            Text(
              "Frames Lost: $framesLost",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              alarmOn ? "Alarm: ON" : "Alarm: OFF",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: alarmOn ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 25),

            // 🔘 BUTTONS ROW 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: ApiService.start,
                  child: const Text("Start"),
                ),
                ElevatedButton(
                  onPressed: ApiService.stop,
                  child: const Text("Stop"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => framesLost = 0);
                  },
                  child: const Text("Reset"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔘 BUTTONS ROW 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: ApiService.mute,
                  child: Text(isMuted ? "Unmute Alarm" : "Mute Alarm"),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text("Info"),
                        content: Text(
                          "Sleep / Pupil Detection System\nVersion 1.0\nPython + Flutter",
                        ),
                      ),
                    );
                  },
                  child: const Text("Info"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Quit"),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
