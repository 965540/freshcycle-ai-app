import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'scan_screen.dart';
import 'upload_screen.dart';
import 'offer_screen.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🔥 GET USER NAME
  String getUserName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return "User";

    // Try displayName first, fallback to email
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    return user.email?.split('@')[0] ?? "User";
  }

  // 🔄 NAVIGATION
  void navigate(BuildContext context, String type) {
    switch (type) {
      case "scan":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        break;

      case "upload":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const UploadScreen()));
        break;

      case "offer":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const OfferScreen()));
        break;

      case "dashboard":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()));
        break;
    }
  }

  // 🔓 LOGOUT
  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  // 🔘 BUTTON
  Widget buildButton(
      BuildContext context, String text, IconData icon, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => navigate(context, type),
          icon: Icon(icon, color: Colors.black),
          label: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = getUserName();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF43A047),
              Color(0xFFA5D6A7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // 🔝 TOP BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "FreshCycle",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => logout(context),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 👋 USER NAME
              Text(
                "Welcome, $userName 👋",
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Choose an option to continue",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 40),

              // 🔥 BUTTONS
              buildButton(context, "Scan", Icons.camera_alt, "scan"),
              buildButton(context, "Upload", Icons.upload, "upload"),
              buildButton(context, "Live Offers", Icons.local_offer, "offer"),
              buildButton(context, "Dashboard", Icons.bar_chart, "dashboard"),
            ],
          ),
        ),
      ),
    );
  }
}