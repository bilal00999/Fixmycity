import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'submit_report_screen.dart';

// ---------- Design tokens ----------
class AppColors {
  static const Color primaryTeal = Color(0xFF009688);
  static const Color darkTeal = Color(0xFF008577);
  static const Color lightTeal = Color(0xFFE0F2F1);
  static const Color background = Color(
    0xFFFDF6F7,
  ); // soft off-white w/ pink tint
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .get(),
          builder: (context, snapshot) {
            // ---------- Resolve username dynamically ----------
            String username = user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!
                : (user?.email?.split('@').first ?? 'User');

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              username =
                  (data['username'] as String?)?.trim().isNotEmpty == true
                  ? data['username']
                  : username;
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- 1. Welcome Section ----------
                  _WelcomeSection(
                    username: username,
                    email: user?.email ?? '',
                    photoUrl: user?.photoURL,
                  ),
                  const SizedBox(height: 32),

                  // ---------- 2. Primary Action: Report an Issue ----------
                  _ReportIssueCard(onTap: () => _openReportScreen(context)),
                  const SizedBox(height: 20),

                  // ---------- 3. Info Card ----------
                  const _InfoCard(),
                  const SizedBox(height: 28),

                  // ---------- 4. Secondary Action ----------
                  _SubmitComplaintButton(
                    onTap: () => _openReportScreen(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- App bar ----------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      titleSpacing: 20,
      title: const Row(
        children: [
          Icon(Icons.location_city, size: 24),
          SizedBox(width: 10),
          Text(
            'FixMyCity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22),
          tooltip: 'Logout',
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---------------- Logout ----------------
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
    }
  }

  // ---------------- Navigation ----------------
  void _openReportScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubmitReportScreen()),
    );
  }
}

// ============================================================
// 1. WELCOME SECTION
// ============================================================
class _WelcomeSection extends StatelessWidget {
  final String username;
  final String email;
  final String? photoUrl;

  const _WelcomeSection({
    required this.username,
    required this.email,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Column(
      children: [
        // Avatar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryTeal, AppColors.darkTeal],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.lightTeal,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTeal,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // Welcome heading
        Text(
          'Welcome back,',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          username,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),

        // Email
        Text(
          email,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

// ============================================================
// 2. PRIMARY "REPORT AN ISSUE" CARD
// ============================================================
class _ReportIssueCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportIssueCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primaryTeal.withOpacity(0.12),
        highlightColor: AppColors.primaryTeal.withOpacity(0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.lightTeal,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Camera icon tile
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),

                // Text content
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Report an Issue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTeal,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Spot a problem? Snap a photo and submit it in seconds.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Arrow indicator
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. INFO CARD
// ============================================================
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightTeal, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.lightTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.darkTeal,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'FixMyCity',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help make your city better. Report potholes, broken streetlights, '
            'garbage overflow, water leaks and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. BOTTOM ACTION (Secondary "Submit a Complaint")
// ============================================================
class _SubmitComplaintButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SubmitComplaintButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.report_problem_rounded, size: 22),
        label: const Text(
          'Submit a Complaint',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
