import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker picker = ImagePicker();
  File? image;

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final emissionController = TextEditingController();
  final contactController = TextEditingController();

  String condition = "Fresh";
  double distance = 5;

  double? latitude;
  double? longitude;

  bool loading = false;

  // 📸 PICK IMAGE
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  // 📍 GET LOCATION
  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission required")),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      latitude = pos.latitude;
      longitude = pos.longitude;
    });
  }

  // 🌱 EMISSION
  void calculateEmission(String value) {
    double kg = double.tryParse(value) ?? 0;
    double factor = condition == "Fresh" ? 2.0 : 3.0;
    emissionController.text = (kg * factor).toStringAsFixed(2);
  }

  // 🚀 UPLOAD DATA
  Future<void> uploadData() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (image == null || latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      // 🔥 UPLOAD IMAGE TO FLASK
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://192.168.208.164:5000/upload"), // CHANGE IP IF NEEDED
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', image!.path),
      );

      var response = await request.send();
      var res = await http.Response.fromStream(response);
      var data = json.decode(res.body);

      if (data["imageUrl"] == null) {
        throw "Image upload failed";
      }

      String imageUrl = data["imageUrl"];

      // 🔥 SAVE TO FIRESTORE
      await FirebaseFirestore.instance.collection("items").add({
        "name": nameController.text.trim(),
        "condition": condition,
        "quantity": double.tryParse(quantityController.text) ?? 0,
        "emission": double.tryParse(emissionController.text) ?? 0,
        "contact": contactController.text.trim(),
        "location": GeoPoint(latitude!, longitude!),
        "distance": distance.toInt(),
        "imageUrl": imageUrl,
        "status": "available",
        "userId": user.uid,
        "claimedBy": null,
        "claimedAt": null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploaded successfully")),
      );

      setState(() {
        image = null;
        nameController.clear();
        quantityController.clear();
        emissionController.clear();
        contactController.clear();
        latitude = null;
        longitude = null;
        distance = 5;
      });

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    emissionController.dispose();
    contactController.dispose();
    super.dispose();
  }

  // 🧩 INPUT FIELD
  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Waste"),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // 📸 IMAGE
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            field(
              controller: nameController,
              label: "Item Name",
              icon: Icons.fastfood,
              validator: (v) =>
                  v == null || v.isEmpty ? "Enter item name" : null,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: condition,
              items: const [
                DropdownMenuItem(value: "Fresh", child: Text("Fresh")),
                DropdownMenuItem(value: "Spoiled", child: Text("Spoiled")),
              ],
              onChanged: (v) {
                setState(() => condition = v!);
                calculateEmission(quantityController.text);
              },
            ),

            const SizedBox(height: 12),

            field(
              controller: quantityController,
              label: "Quantity (kg)",
              icon: Icons.scale,
              validator: (v) =>
                  v == null || double.tryParse(v) == null
                      ? "Enter valid number"
                      : null,
              onChanged: calculateEmission,
            ),

            const SizedBox(height: 12),

            field(
              controller: emissionController,
              label: "CO2 Emission",
              icon: Icons.eco,
              readOnly: true,
            ),

            const SizedBox(height: 12),

            field(
              controller: contactController,
              label: "Contact",
              icon: Icons.phone,
              validator: (v) =>
                  v == null || v.length < 10
                      ? "Enter valid phone"
                      : null,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: getLocation,
              child: const Text("Get Location"),
            ),

            if (latitude != null)
              Text("Lat: $latitude\nLng: $longitude"),

            const SizedBox(height: 16),

            Text("Distance: ${distance.toInt()} km"),

            Slider(
              value: distance,
              min: 5,
              max: 20,
              divisions: 15,
              onChanged: (v) => setState(() => distance = v),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : uploadData,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}