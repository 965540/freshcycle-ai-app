import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class SuggestScreen extends StatefulWidget {
  const SuggestScreen({super.key});

  @override
  State<SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {

  File? image;
  String prediction = "";
  String suggestion = "";
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
        prediction = "";
        suggestion = "";
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

        String pred = data['prediction'];
        double conf = data['confidence'];

        if (!mounted) return;

        setState(() {
          prediction =
              "$pred (${(conf * 100).toStringAsFixed(1)}%)";
          suggestion = getSuggestion(pred, conf);
        });
      } else {
        throw "Server error";
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        prediction = "⚠️ Error";
        suggestion = "Failed to get suggestion. Try again.";
      });
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  String getSuggestion(String pred, double conf) {
    if (conf < 0.6) {
      return "⚠️ Uncertain result. Please scan again.";
    }
    if (pred == "Fresh") {
      return "✅ Good quality.\n➡️ Sell or donate.";
    }
    if (pred == "Spoiled") {
      return "⚠️ Not suitable.\n➡️ Compost or animal feed.";
    }
    return "No suggestion available.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suggest Mode"),
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
                  "Suggestion Result",
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
                        child: Column(
                          children: [
                            Text(
                              prediction.isEmpty ? "Processing..." : prediction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              suggestion,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
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