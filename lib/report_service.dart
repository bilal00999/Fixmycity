import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_made_easy/cloudinary_made_easy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CloudinaryService _cloudinary = CloudinaryService(
    cloudName: 'xhwcujrl', // 👈 Replace with your Cloudinary cloud name
    uploadPreset:
        'fixmycity_upload', // 👈 Replace with your unsigned preset name
  );

  /// Uploads an [XFile] to Cloudinary and returns the secure URL.
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final String? url = await _cloudinary.uploadFile(imageFile);
      debugPrint('✅ Cloudinary upload success: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  /// Uploads the image, then saves the report document to Firestore.
  Future<bool> submitReport({
    required XFile imageFile,
    required double latitude,
    required double longitude,
    required String category,
    required String description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      // 1. Upload photo to Cloudinary
      final imageUrl = await uploadImage(imageFile);
      if (imageUrl == null) throw 'Image upload failed';

      // 2. Save report to Firestore
      await _firestore.collection('reports').add({
        'uid': user.uid,
        'username': user.displayName ?? 'Anonymous',
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'description': description,
        'status': 'pending',
        'upvotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Report submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Report submission error: $e');
      return false;
    }
  }
}
