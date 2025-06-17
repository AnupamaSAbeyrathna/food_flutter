// lib/screens/medical_record_edit_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/medical_record_display_model.dart';
import '../../services/medical_record_display_service.dart';

class MedicalRecordEditScreen extends StatefulWidget {
  final String userId;
  final MedicalRecordDisplay record;
  
  const MedicalRecordEditScreen({
    Key? key,
    required this.userId,
    required this.record,
  }) : super(key: key);
  
  @override
  State<MedicalRecordEditScreen> createState() => _MedicalRecordEditScreenState();
}

class _MedicalRecordEditScreenState extends State<MedicalRecordEditScreen>
    with SingleTickerProviderStateMixin {
  final MedicalRecordsService _service = MedicalRecordsService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Dynamic AI Analysis data
  Map<String, dynamic> _aiAnalysisData = {};
  final Map<String, TextEditingController> _aiControllers = {};
  
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _showRawJson = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record.title);
    _noteController = TextEditingController(text: widget.record.metadata.notes ?? '');
    
    // Initialize AI Analysis data
    _aiAnalysisData = widget.record.metadata.aiAnalysis != null 
        ? Map<String, dynamic>.from(widget.record.metadata.aiAnalysis!)
        : {};
    _initializeAIControllers();
    
    // Animation setup
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Listen for changes
    _titleController.addListener(_onFieldChanged);
    _noteController.addListener(_onFieldChanged);
    
    _animationController.forward();
  }
  
  void _initializeAIControllers() {
    _aiControllers.clear();
    _createControllersRecursively(_aiAnalysisData);
  }
  
  void _createControllersRecursively(Map<String, dynamic> data, [String prefix = '']) {
    data.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      
      if (value is Map<String, dynamic>) {
        _createControllersRecursively(value, fullKey);
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final itemKey = '$fullKey[$i]';
          if (value[i] is Map<String, dynamic>) {
            _createControllersRecursively(value[i] as Map<String, dynamic>, itemKey);
          } else {
            _aiControllers[itemKey] = TextEditingController(text: value[i]?.toString() ?? '');
            _aiControllers[itemKey]!.addListener(_onFieldChanged);
          }
        }
      } else {
        _aiControllers[fullKey] = TextEditingController(text: value?.toString() ?? '');
        _aiControllers[fullKey]!.addListener(_onFieldChanged);
      }
    });
  }
  
  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _aiControllers.values.forEach((controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }
  
  Map<String, dynamic> _buildUpdatedAIAnalysis() {
    Map<String, dynamic> result = {};
    
    _aiControllers.forEach((path, controller) {
      final value = controller.text.trim();
      if (value.isNotEmpty) {
        _setNestedValue(result, path, value);
      }
    });
    
    return result;
  }
  
  void _setNestedValue(Map<String, dynamic> map, String path, String value) {
    final parts = path.split('.');
    Map<String, dynamic> current = map;
    
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      
      if (part.contains('[') && part.contains(']')) {
        // Handle array notation like "medications[0]"
        final arrayKey = part.substring(0, part.indexOf('['));
        final indexStr = part.substring(part.indexOf('[') + 1, part.indexOf(']'));
        final index = int.tryParse(indexStr) ?? 0;
        
        if (!current.containsKey(arrayKey)) {
          current[arrayKey] = <Map<String, dynamic>>[];
        }
        
        final list = current[arrayKey] as List;
        while (list.length <= index) {
          list.add(<String, dynamic>{});
        }
        
        current = list[index] as Map<String, dynamic>;
      } else {
        if (!current.containsKey(part)) {
          current[part] = <String, dynamic>{};
        }
        current = current[part] as Map<String, dynamic>;
      }
    }
    
    final lastPart = parts.last;
    if (lastPart.contains('[') && lastPart.contains(']')) {
      final arrayKey = lastPart.substring(0, lastPart.indexOf('['));
      final indexStr = lastPart.substring(lastPart.indexOf('[') + 1, lastPart.indexOf(']'));
      final index = int.tryParse(indexStr) ?? 0;
      
      if (!current.containsKey(arrayKey)) {
        current[arrayKey] = <String>[];
      }
      
      final list = current[arrayKey] as List;
      while (list.length <= index) {
        list.add('');
      }
      
      list[index] = value;
    } else {
      current[lastPart] = value;
    }
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updatedAiAnalysis = _buildUpdatedAIAnalysis();

      await _service.updateRecordForMember(
        widget.userId,
        widget.record.familyMemberId,
        widget.record.id,
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        aiAnalysis: updatedAiAnalysis.isNotEmpty ? updatedAiAnalysis : null,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Record updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pop(context, true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error updating record: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unsaved Changes'),
          ],
        ),
        content: Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Leave'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  Widget _buildDynamicAIField(String key, dynamic value, [String fullPath = '']) {
    final currentPath = fullPath.isEmpty ? key : '$fullPath.$key';
    
    if (value is Map<String, dynamic>) {
      return _buildNestedSection(key, value, currentPath);
    } else if (value is List) {
      return _buildListSection(key, value, currentPath);
    } else {
      return _buildSimpleField(key, currentPath);
    }
  }
  
  Widget _buildNestedSection(String title, Map<String, dynamic> data, String path) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.folder, color: Colors.blue[600]),
        title: Text(
          _formatFieldName(title),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: data.entries.map((entry) {
                return _buildDynamicAIField(entry.key, entry.value, path);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListSection(String title, List<dynamic> data, String path) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.list, color: Colors.green[600]),
        title: Text(
          '${_formatFieldName(title)} (${data.length} items)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                
                if (value is Map<String, dynamic>) {
                  return _buildNestedSection('Item ${index + 1}', value, '$path[$index]');
                } else {
                  return _buildSimpleField('Item ${index + 1}', '$path[$index]');
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleField(String fieldName, String path) {
    final controller = _aiControllers[path];
    if (controller == null) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: _formatFieldName(fieldName),
          hintText: 'Enter ${_formatFieldName(fieldName).toLowerCase()}',
          prefixIcon: Icon(_getIconForField(fieldName)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: _isLongTextField(fieldName) ? 3 : 1,
      ),
    );
  }
  
  String _formatFieldName(String fieldName) {
    // Remove array notation and convert camelCase to Title Case
    String cleaned = fieldName.replaceAll(RegExp(r'\[\d+\]'), '');
    return cleaned.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ').trim();
  }
  
  IconData _getIconForField(String fieldName) {
    final lower = fieldName.toLowerCase();
    if (lower.contains('name')) return Icons.person;
    if (lower.contains('date')) return Icons.calendar_today;
    if (lower.contains('doctor')) return Icons.local_hospital;
    if (lower.contains('medication')) return Icons.medication;
    if (lower.contains('dosage')) return Icons.local_pharmacy;
    if (lower.contains('frequency')) return Icons.schedule;
    if (lower.contains('instruction')) return Icons.info;
    if (lower.contains('diagnosis')) return Icons.medical_services;
    if (lower.contains('test')) return Icons.science;
    return Icons.edit;
  }
  
  bool _isLongTextField(String fieldName) {
    final lower = fieldName.toLowerCase();
    return lower.contains('instruction') || 
           lower.contains('note') || 
           lower.contains('description') ||
           lower.contains('comment');
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.primaryColor,
          title: Text(
            'Edit Record',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon: _isLoading 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.save),
                  label: Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Record Information Card
                        _buildInfoCard(),
                        
                        SizedBox(height: 24),
                        
                        // Basic Editable Fields Section
                        _buildBasicEditableSection(),
                        
                        SizedBox(height: 24),
                        
                        // AI Analysis Section
                        if (_aiAnalysisData.isNotEmpty) _buildAIAnalysisSection(),
                        
                        SizedBox(height: 24),
                        
                        // Images Section
                        if (widget.record.imageUrls.isNotEmpty)
                          _buildImagesSection(),
                        
                        // Extra padding at bottom for better scrolling
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _hasUnsavedChanges
            ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _saveChanges,
                backgroundColor: theme.primaryColor,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Record Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Type', widget.record.typeDisplayName, Icons.category),
            SizedBox(height: 8),
            _buildInfoRow(
              'Date',
              '${widget.record.date.day}/${widget.record.date.month}/${widget.record.date.year}',
              Icons.calendar_today,
            ),
            SizedBox(height: 8),
            _buildInfoRow(
              'Created',
              '${widget.record.createdAt.day}/${widget.record.createdAt.month}/${widget.record.createdAt.year}',
              Icons.schedule,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBasicEditableSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Colors.green[600],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter record title',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            
            SizedBox(height: 20),
            
            // Notes Field
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Add your notes here...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAIAnalysisSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.purple[600],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'AI Analysis Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showRawJson = !_showRawJson);
                  },
                  icon: Icon(_showRawJson ? Icons.visibility_off : Icons.code),
                  label: Text(_showRawJson ? 'Form View' : 'JSON View'),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            if (_showRawJson) 
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  JsonEncoder.withIndent('  ').convert(_buildUpdatedAIAnalysis()),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              )
            else
              Column(
                children: _aiAnalysisData.entries.map((entry) {
                  return _buildDynamicAIField(entry.key, entry.value);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: Colors.purple[600],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Attached Images',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                Chip(
                  label: Text('${widget.record.imageUrls.length}'),
                  backgroundColor: Colors.purple[100],
                  labelStyle: TextStyle(color: Colors.purple[800]),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                itemCount: widget.record.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.network(
                          widget.record.imageUrls[index],
                          height: 180,
                          width: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 140,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}