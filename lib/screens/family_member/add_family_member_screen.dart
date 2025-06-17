import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/family_member.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  final String userId;
  final FamilyMember? existingMember;

  const AddFamilyMemberScreen({
    Key? key,
    required this.userId,
    this.existingMember,
  }) : super(key: key);

  @override
  _AddFamilyMemberScreenState createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Form controllers for better management
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _healthNotesController = TextEditingController();
  final _allergiesController = TextEditingController(); // Added allergies controller
  final _longTermMedicationsController = TextEditingController(); // Added medications controller

  String _selectedGender = 'Male';
  DateTime? _selectedBirthDate;

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _relationshipSuggestions = [
    'Parent',
    'Child',
    'Spouse',
    'Sibling',
    'Grandparent',
    'Grandchild',
    'Uncle/Aunt',
    'Cousin',
    'Other'
  ];

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

    _initializeForm();
    _animationController.forward();
  }

  void _initializeForm() {
    final member = widget.existingMember;
    if (member != null) {
      _nameController.text = member.name;
      _ageController.text = member.age > 0 ? member.age.toString() : '';
      _selectedGender = member.gender;
      _relationshipController.text = member.relationship;
      _healthNotesController.text = member.healthNotes;
      _allergiesController.text = member.allergies; // Initialize allergies
      _longTermMedicationsController.text = member.longTermMedications; // Initialize medications
    }

    // Add listeners for unsaved changes detection
    _nameController.addListener(_onFormChanged);
    _ageController.addListener(_onFormChanged);
    _relationshipController.addListener(_onFormChanged);
    _healthNotesController.addListener(_onFormChanged);
    _allergiesController.addListener(_onFormChanged); // Added listener
    _longTermMedicationsController.addListener(_onFormChanged); // Added listener
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Are you sure you want to leave?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _selectBirthDate() async {
    final initialDate = _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Birth Date',
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _ageController.text = _calculateAge(picked).toString();
        _onFormChanged();
      });
    }
  }

  void _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      _formKey.currentState!.save();

      final isEditing = widget.existingMember != null;
      final docRef = isEditing
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('family_members')
              .doc(widget.existingMember!.id)
          : FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('family_members')
              .doc();

      final member = FamilyMember(
        id: docRef.id,
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender,
        relationship: _relationshipController.text.trim(),
        healthNotes: _healthNotesController.text.trim(),
        allergies: _allergiesController.text.trim(), // Added allergies
        longTermMedications: _longTermMedicationsController.text.trim(), // Added medications
      );

      await docRef.set(member.toMap());

      if (mounted) {
        _showSuccessMessage(isEditing ? 'Member updated successfully!' : 'Member added successfully!');
        setState(() => _hasUnsavedChanges = false);
        Navigator.pop(context, member);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to save member. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _relationshipController.dispose();
    _healthNotesController.dispose();
    _allergiesController.dispose(); // Added disposal
    _longTermMedicationsController.dispose(); // Added disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMember != null;
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            isEditing ? 'Edit Family Member' : 'Add Family Member',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: Colors.orange,
                  size: 12,
                ),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            isEditing ? Icons.edit : Icons.person_add,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEditing ? 'Update member information' : 'Add a new family member',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildSectionCard(
                    'Personal Information',
                    Icons.person,
                    [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (val) => val?.isEmpty == true ? 'Please enter a name' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) {
                                if (val?.isEmpty == true) return 'Please enter age';
                                final age = int.tryParse(val!);
                                if (age == null || age < 0 || age > 150) {
                                  return 'Enter valid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              onPressed: _selectBirthDate,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _selectedBirthDate != null
                                    ? 'Born ${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                    : 'Select Birthday',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        value: _selectedGender,
                        label: 'Gender',
                        icon: Icons.wc,
                        items: _genderOptions,
                        onChanged: (val) {
                          setState(() => _selectedGender = val!);
                          _onFormChanged();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Relationship Section
                  _buildSectionCard(
                    'Relationship',
                    Icons.family_restroom,
                    [
                      _buildAutocompleteField(
                        controller: _relationshipController,
                        label: 'Relationship',
                        icon: Icons.family_restroom,
                        suggestions: _relationshipSuggestions,
                        validator: (val) => val?.isEmpty == true ? 'Please enter relationship' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Health Information Section - Updated with new fields
                  _buildSectionCard(
                    'Health Information',
                    Icons.health_and_safety,
                    [
                      _buildTextField(
                        controller: _allergiesController,
                        label: 'Allergies (Optional)',
                        icon: Icons.warning_amber_outlined,
                        maxLines: 2,
                        hint: 'Food allergies, drug allergies, environmental allergies...',
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _longTermMedicationsController,
                        label: 'Long-term Medications (Optional)',
                        icon: Icons.medication_outlined,
                        maxLines: 2,
                        hint: 'Current medications, dosages, frequency...',
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _healthNotesController,
                        label: 'Additional Health Notes (Optional)',
                        icon: Icons.medical_information_outlined,
                        maxLines: 3,
                        hint: 'Medical conditions, surgeries, family medical history...',
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(isEditing),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> suggestions,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return suggestions.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        this._relationshipController.text = controller.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: validator,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            this._relationshipController.text = value;
            _onFormChanged();
          },
        );
      },
      onSelected: (selection) {
        _relationshipController.text = selection;
        _onFormChanged();
      },
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMember,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.update : Icons.save),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Update Member' : 'Save Member',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}