// lib/screens/medical_record_edit_screen.dart
import 'package:flutter/material.dart';
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
  
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record.title);
    _noteController = TextEditingController(text: widget.record.metadata.notes ?? '');
    
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
  
  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _service.updateRecord(
        widget.userId,
        widget.record.familyMemberId,
        widget.record.id,
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
      );
      
      // Success animation
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
      
      Navigator.pop(context, true); // Return with success flag
      
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
                        
                        // Editable Fields Section
                        _buildEditableSection(),
                        
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
  
  Widget _buildEditableSection() {
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
                  'Editable Fields',
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