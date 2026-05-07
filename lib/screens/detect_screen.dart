import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  File? image;
  String result = "";
  bool loading = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => openCamera());
  }

  Future<void> openCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        result = "";
      });
      await sendToAPI();
    } else {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> sendToAPI() async {
    if (image == null) return;

    setState(() => loading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Config.baseUrl}/predict"),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', image!.path),
      );

      var response = await request.send().timeout(
        const Duration(seconds: 15),
      );

      var res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        var data = json.decode(res.body);

        if (!mounted) return;

        setState(() {
          result =
              "${data['prediction']} (${(data['confidence'] * 100).toStringAsFixed(1)}%)";
        });
      } else {
        throw "Server error";
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = "⚠️ Failed to detect. Try again.";
      });
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detect Mode"),
        backgroundColor: Colors.green,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF2C5364),
              Color(0xFF00C853),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text(
                  "Scan Result",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                if (image != null)
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(image!, height: 260),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          result.isEmpty ? "Processing..." : result,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),

                const SizedBox(height: 30),

                if (loading)
                  const CircularProgressIndicator(),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: openCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Scan Again"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}