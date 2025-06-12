import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme.dart';
import '../../providers/medical_record_provider.dart';
import '../../widgets/medical_record_widgets.dart';
import '../../models/family_member.dart';
//import '../../services/family_member_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Family member related variables
  final FamilyMemberService _familyMemberService = FamilyMemberService();
  List<FamilyMember> _familyMembers = [];
  FamilyMember? _selectedFamilyMember;
  bool _loadingFamilyMembers = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final members = await _familyMemberService.getAllFamilyMembers(user.uid);
        setState(() {
          _familyMembers = members;
          // Auto-select "Self" if available
          _selectedFamilyMember = members.isNotEmpty
              ? members.firstWhere(
                  (member) => member.relationship.toLowerCase() == 'self',
                  orElse: () => members.first,
                )
              : null;
          _loadingFamilyMembers = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingFamilyMembers = false;
      });
      _showErrorSnackBar('Failed to load family members: $e');
    }
  }

  void _showImageSourceDialog(MedicalRecordProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImageSourceDialog(
          onSourceSelected: (source) => _pickImage(provider, source),
        );
      },
    );
  }

  Future<void> _pickImage(
    MedicalRecordProvider provider,
    ImageSource source,
  ) async {
    try {
      await provider.pickImage(source);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _analyzeImage(MedicalRecordProvider provider) async {
    if (_selectedFamilyMember == null) {
      _showErrorSnackBar('Please select a family member');
      return;
    }
    try {
      await provider.analyzeImage(
        title: _titleController.text,
        note: _noteController.text,
        familyMember: _selectedFamilyMember!,
      );
      _showSuccessSnackBar('Medical record analyzed successfully!');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetForm(MedicalRecordProvider provider) {
    provider.resetForm();
    _titleController.clear();
    _noteController.clear();
  }

  // Fixed: Moved this method outside of the _buildInputForm method
  Widget _buildFamilyMemberSelector() {
    if (_loadingFamilyMembers) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_familyMembers.isEmpty) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: const Center(
          child: Text(
            'No family members found. Please add family members first.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FamilyMember>(
          value: _selectedFamilyMember,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Select family member'),
          ),
          items: _familyMembers.map((member) {
            return DropdownMenuItem<FamilyMember>(
              value: member,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      member.relationship.toLowerCase() == 'self'
                          ? Icons.person
                          : Icons.family_restroom,
                      size: 20,
                      color: member.relationship.toLowerCase() == 'self'
                          ? AppColors.primary
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${member.relationship} • ${member.age} years',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (FamilyMember? newValue) {
            setState(() {
              _selectedFamilyMember = newValue;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MedicalRecordProvider(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Consumer<MedicalRecordProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!provider.isAnalyzed) ...[
                          _buildInputForm(provider),
                        ] else ...[
                          AnalysisResultsWidget(
                            selectedImage: provider.selectedImage!,
                            title: _titleController.text,
                            type: provider.selectedType,
                            note: _noteController.text.isNotEmpty
                                ? _noteController.text
                                : null,
                            analysisResult: provider.analysisResult,
                            getTypeLabel: provider.getTypeLabel,
                            onReset: () => _resetForm(provider),
                            onDone: () => Navigator.pop(context),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Medical Records',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      actions: [
        Consumer<MedicalRecordProvider>(
          builder: (context, provider, child) {
            if (provider.isAnalyzed) {
              return IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: () => _resetForm(provider),
                tooltip: 'Start New Analysis',
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildInputForm(MedicalRecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Selection Section
        const SectionTitle('Select Image'),
        const SizedBox(height: 16),
        ImageSelectionWidget(
          selectedImage: provider.selectedImage,
          onTap: () => _showImageSourceDialog(provider),
        ),

        const SizedBox(height: 32),

        // Family Member Selection
        const SectionTitle('Select Family Member'),
        const SizedBox(height: 16),
        _buildFamilyMemberSelector(),

        const SizedBox(height: 32),

        // Record Type Selection - Fixed version
        const SectionTitle('Record Type'),
        const SizedBox(height: 16),
        
        // Fixed: Simplified record type selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedType,
              isExpanded: true,
              hint: const Text('Select record type'),
              items: provider.recordTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type.value,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  provider.setSelectedType(newValue);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title Input
        const SectionTitle('Title'),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _titleController,
          hintText: 'Enter record title',
        ),

        const SizedBox(height: 24),

        // Note Input
        const SectionTitle('Note (Optional)'),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _noteController,
          hintText: 'Add any additional notes...',
          maxLines: 3,
        ),

        const SizedBox(height: 32),

        // Analyze Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : () => _analyzeImage(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined),
                      SizedBox(width: 8),
                      Text(
                        'Analyze Medical Record',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}