import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfferDetailScreen extends StatefulWidget {
  final Map<String, dynamic> offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool isTaken = false;

  @override
  void initState() {
    super.initState();
    isTaken = widget.offer["status"] == "taken";
  }

  // 🗺 OPEN GOOGLE MAPS
  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // 🔥 CLAIM OFFER
  Future<void> claimOffer() async {
    final docRef = FirebaseFirestore.instance
        .collection("items")
        .doc(widget.offer["id"]);

    final doc = await docRef.get();

    if (!mounted) return;

    if (doc["status"] == "taken") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already taken")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    await docRef.update({
      "status": "taken",
      "claimedAt": FieldValue.serverTimestamp(),
      "claimedBy": user?.uid,
    });

    if (!mounted) return;

    setState(() => isTaken = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Offer claimed")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED LOCATION
    final GeoPoint? geo = widget.offer["location"];
    final double lat = geo?.latitude ?? 0;
    final double lng = geo?.longitude ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offer["name"] ?? "Offer Details"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // 📸 IMAGE
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.network(widget.offer["imageUrl"] ?? ""),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.offer["imageUrl"] ?? "",
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            widget.offer["name"] ?? "Unknown",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: (widget.offer["condition"] ?? "") == "Fresh"
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(widget.offer["condition"] ?? "Unknown"),
              const SizedBox(width: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTaken ? Colors.grey : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTaken ? "Taken" : "Available",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text("Quantity: ${widget.offer["quantity"] ?? "-"} kg"),
          Text("CO₂: ${widget.offer["emission"] ?? "-"} kg"),

          Text(
            "Distance: ${widget.offer["calculatedDistance"]?.toStringAsFixed(1) ?? widget.offer["distance"] ?? "-"} km",
          ),

          const SizedBox(height: 12),

          Text("📞 ${widget.offer["contact"] ?? "-"}"),

          const SizedBox(height: 16),

          // 📍 MAP
          if (lat != 0 && lng != 0)
            SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("item"),
                    position: LatLng(lat, lng),
                  ),
                },
              ),
            ),

          const SizedBox(height: 16),

          // 🚗 NAVIGATION
          if (lat != 0 && lng != 0)
            ElevatedButton.icon(
              onPressed: () => openGoogleMaps(lat, lng),
              icon: const Icon(Icons.navigation),
              label: const Text("Open in Google Maps"),
            ),

          const SizedBox(height: 10),

          // 🔥 CLAIM BUTTON
          ElevatedButton(
            onPressed: isTaken ? null : claimOffer,
            child: Text(isTaken ? "Already Taken" : "Claim Offer"),
          ),
        ],
      ),
    );
  }
}