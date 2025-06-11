import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'meal_screen.dart';
import '../medical_record/medical_records_list_screen.dart';
import '../family_member/family_members_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isRefreshing = true;
    });
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Widget _buildBMICard(String? bmiString) {
    if (bmiString == null || bmiString.isEmpty) {
      return const SizedBox.shrink();
    }

    final double bmi = double.tryParse(bmiString) ?? 0;
    Color bmiColor;
    String bmiCategory;

    if (bmi < 18.5) {
      bmiColor = Colors.blue;
      bmiCategory = 'Underweight';
    } else if (bmi < 25) {
      bmiColor = Colors.green;
      bmiCategory = 'Normal';
    } else if (bmi < 30) {
      bmiColor = Colors.orange;
      bmiCategory = 'Overweight';
    } else {
      bmiColor = Colors.red;
      bmiCategory = 'Obese';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.monitor_weight, color: bmiColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'BMI Calculator',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BMI: ${bmi.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bmiCategory,
                  style: TextStyle(
                    color: bmiColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (bmi / 40).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(bmiColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      height: 80, // Fixed height for consistency
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDiseasesChips(String? diseases) {
    if (diseases == null || diseases.isEmpty) {
      return _buildInfoCard(
        icon: Icons.local_hospital,
        title: 'Special Diseases',
        value: 'None reported',
        iconColor: Colors.green,
      );
    }

    final diseaseList = diseases.split(',').map((e) => e.trim()).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Special Diseases',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: diseaseList.map((disease) => Chip(
              label: Text(
                disease,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.red.withOpacity(0.1),
              side: BorderSide(color: Colors.red.withOpacity(0.3)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180, // Increased height from 160 to 180
          padding: const EdgeInsets.all(16), // Reduced padding from 20 to 16
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12), // Reduced from 14 to 12
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24, // Reduced from 28 to 24
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 16 to 12
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15, // Reduced from 16 to 15
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12, // Reduced from 13 to 12
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12, // Reduced from 13 to 12
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: iconColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _fetchUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || _isRefreshing) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data?.data();
              final user = FirebaseAuth.instance.currentUser;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.blue,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _signOut,
                        tooltip: 'Sign Out',
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: user?.photoURL != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user!.photoURL!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.blue,
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userData?['name'] ?? user?.displayName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: userData == null || userData.isEmpty
                        ? _buildEmptyState(context)
                        : _buildProfileContent(userData),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditProfileScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

Widget _buildEmptyState(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.person_add,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your personal information to get personalized meal recommendations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              // First Row - Meal Data and Medical Records
              Row(
                children: [
                  _buildFeatureCard(
                    icon: Icons.restaurant_menu,
                    title: 'Meal Data',
                    subtitle: 'Track your meals and nutrition',
                    iconColor: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    icon: Icons.medical_information,
                    title: 'Medical Records',
                    subtitle: 'Manage your health records',
                    iconColor: Colors.red,
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalRecordsListScreen(userId: user.uid),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16), // Add spacing between rows
              // Second Row - Family Members (single card)
              Row(
                children: [
                  _buildFeatureCard(
                    icon: Icons.group,
                    title: 'Family Members',
                    subtitle: 'Manage your family information',
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FamilyMembersScreen(userId: user.uid),
                          ),
                        );
                      }
                    },
                    iconColor: Colors.blueAccent,
                  ),
                  const SizedBox(width: 16), // Add spacer
                  Expanded(child: Container()), // Fill remaining space
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildProfileContent(Map<String, dynamic> userData) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile completion indicator
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Profile Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '100%',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Personal Information Section
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildInfoCard(
          icon: Icons.person,
          title: 'Full Name',
          value: userData['name'] ?? '',
          iconColor: Colors.blue,
        ),
        const SizedBox(height: 12),
        
        _buildInfoCard(
          icon: Icons.cake,
          title: 'Age',
          value: userData['age']?.toString() ?? '',
          iconColor: Colors.purple,
        ),
        const SizedBox(height: 24),

        // Main Features Section
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // First Row - Meal Data and Medical Records
        Row(
          children: [
            _buildFeatureCard(
              icon: Icons.restaurant_menu,
              title: 'Meal Data',
              subtitle: 'Track your meals and nutrition',
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MealScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            _buildFeatureCard(
              icon: Icons.medical_information,
              title: 'Medical Records',
              subtitle: 'Manage your health records',
              iconColor: Colors.red,
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicalRecordsListScreen(userId: user.uid),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row - Family Members
        Row(
          children: [
            _buildFeatureCard(
              icon: Icons.group,
              title: 'Family Members',
              subtitle: 'Manage your family information',
              iconColor: Colors.blueAccent,
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilyMembersScreen(userId: user.uid),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(child: Container()), // Fill remaining space
          ],
        ),
        const SizedBox(height: 24),

        // Health Metrics Section
        const Text(
          'Health Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.monitor_weight,
                title: 'Weight',
                value: userData['weight'] != null 
                    ? '${userData['weight']} kg' 
                    : '',
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.height,
                title: 'Height',
                value: userData['height'] != null 
                    ? '${userData['height']} cm' 
                    : '',
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Enhanced BMI Card
        _buildBMICard(userData['bmi']?.toString()),

        // Special Diseases
        _buildSpecialDiseasesChips(userData['specialDiseases']?.toString()),
        const SizedBox(height: 100), // Space for FAB
      ],
    ),
  );
}
}