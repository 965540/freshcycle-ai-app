import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<Map<String, dynamic>> fetchData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return {};

    final snapshot = await FirebaseFirestore.instance
        .collection("items")
        .get();

    int donated = 0;
    int claimed = 0;
    int fresh = 0;
    int spoiled = 0;
    double co2 = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // 🟢 DONATED ITEMS
      if (data["userId"] == user.uid) {
        donated++;

        if ((data["condition"] ?? "") == "Fresh") {
          fresh++;
        } else {
          spoiled++;
        }

        co2 += double.tryParse(data["emission"].toString()) ?? 0;
      }

      // 🟡 CLAIMED ITEMS
      if (data["claimedBy"] == user.uid) {
        claimed++;
      }
    }

    return {
      "donated": donated,
      "claimed": claimed,
      "fresh": fresh,
      "spoiled": spoiled,
      "co2": co2,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final data = snapshot.data!;

          if (data.isEmpty ||
              (data["donated"] == 0 && data["claimed"] == 0)) {
            return const Center(
              child: Text("No activity yet"),
            );
          }

          // 🌱 Activity Level
          String level = "Beginner";
          if (data["donated"] > 5) level = "Contributor";
          if (data["donated"] > 10) level = "Eco Hero 🌱";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // 📊 CARDS
                buildCard(
                    "Donated Items", data["donated"].toString(), Icons.upload, Colors.green),
                buildCard(
                    "Accepted Items", data["claimed"].toString(), Icons.shopping_cart, Colors.orange),
                buildCard(
                    "Fresh Items", data["fresh"].toString(), Icons.eco, Colors.lightGreen),
                buildCard(
                    "Spoiled Items", data["spoiled"].toString(), Icons.delete, Colors.redAccent),
                buildCard(
                    "CO₂ Saved",
                    "${data["co2"].toStringAsFixed(2)} kg",
                    Icons.cloud,
                    Colors.blue),

                const SizedBox(height: 20),

                // 🌟 IMPACT SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Impact 🌱",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "You donated ${data["donated"]} items and helped reduce ${data["co2"].toStringAsFixed(1)} kg CO₂.",
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "You also collected ${data["claimed"]} items for reuse.",
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Your Level: $level",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📦 CARD WIDGET
  Widget buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}