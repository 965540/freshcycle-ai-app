import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'offer_detail_screen.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  // 📍 GET USER LOCATION
  Future<void> getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    if (!mounted) return;
    setState(() => userPosition = pos);
  }

  // 📏 CALCULATE DISTANCE
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // 🔔 OFFER TILE
  Widget buildTile(Map<String, dynamic> offer) {
    final bool isTaken = offer["status"] == "taken";

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isTaken ? Colors.grey : Colors.green,
        child: const Icon(Icons.local_offer, color: Colors.white),
      ),
      title: Text(
        offer["name"] ?? "Item",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "${offer["quantity"] ?? "-"} kg • "
        "${offer["calculatedDistance"]?.toStringAsFixed(1) ?? "-"} km",
      ),
      trailing: Text(
        isTaken ? "Taken" : "New",
        style: TextStyle(
          color: isTaken ? Colors.grey : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfferDetailScreen(offer: offer),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offers"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection("items").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final DateTime now = DateTime.now();

          final List<Map<String, dynamic>> filtered = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            // ✅ GET LOCATION (GeoPoint)
            final GeoPoint? geo = data["location"];
            if (geo == null) continue;

            final double lat = geo.latitude;
            final double lng = geo.longitude;

            final double dist = calculateDistance(
              userPosition!.latitude,
              userPosition!.longitude,
              lat,
              lng,
            );

            // 📏 Distance filter
            if (dist > (data["distance"] ?? 5)) continue;

            // ❌ Hide taken after 5 minutes
            if (data["status"] == "taken") {
              final Timestamp? ts = data["claimedAt"];
              final DateTime? claimedAt = ts?.toDate();

              if (claimedAt != null &&
                  now.difference(claimedAt).inMinutes > 5) {
                continue;
              }
            }

            // ✅ Add extra fields
            data["id"] = doc.id;
            data["calculatedDistance"] = dist;

            filtered.add(data);
          }

          // 🔽 SORT BY DISTANCE
          filtered.sort((a, b) =>
              (a["calculatedDistance"] as double)
                  .compareTo(b["calculatedDistance"] as double));

          if (filtered.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return buildTile(filtered[index]);
            },
          );
        },
      ),
    );
  }
}