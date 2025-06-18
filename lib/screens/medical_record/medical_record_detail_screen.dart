// lib/screens/medical_record/medical_record_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/medical_record_display_model.dart';
import '../../services/medical_record_display_service.dart';
import 'medical_record_edit_screen.dart';

class MedicalRecordDetailScreen extends StatefulWidget {
  final String userId;
  final String recordId;
  final String? familyMemberId;
  
  const MedicalRecordDetailScreen({
    Key? key,
    required this.userId,
    required this.recordId,
    this.familyMemberId,
  }) : super(key: key);
  
  @override
  State<MedicalRecordDetailScreen> createState() => _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen>
    with SingleTickerProviderStateMixin {
  final MedicalRecordsService _service = MedicalRecordsService();
  MedicalRecordDisplay? _record;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRecord();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRecord() async {
    setState(() => _isLoading = true);
    try {
      final record = widget.familyMemberId != null
          ? await _service.getRecordForMember(widget.userId, widget.familyMemberId!, widget.recordId)
          : await _service.getRecordById(widget.userId, widget.familyMemberId ?? '', widget.recordId);
      
      if (mounted) {
        setState(() {
          _record = record;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading record: $e');
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: _loadRecord,
        ),
      ),
    );
  }
  
  Future<void> _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Record'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this medical record?'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final success = widget.familyMemberId != null
            ? await _service.deleteRecordForMember(widget.userId, widget.familyMemberId!, widget.recordId)
            : await _service.deleteRecord(widget.userId, widget.familyMemberId ?? '', widget.recordId);
        if (success) {
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to delete record');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting record: $e');
      }
    }
  }
  
  Future<void> _editRecord() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalRecordEditScreen(
          userId: widget.userId,
          record: _record!,
        ),
      ),
    );
    
    if (result == true) {
      print('Edit successful, refreshing record data...');
      await Future.delayed(Duration(milliseconds: 300));
      await _loadRecord();
    }
  }
  
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (index) => Container(
            margin: EdgeInsets.only(bottom: 16),
            height: index == 0 ? 120 : 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecordTypeChip(String type) {
    Color chipColor;
    IconData chipIcon;
    
    switch (type.toLowerCase()) {
      case 'prescription':
        chipColor = Colors.blue;
        chipIcon = Icons.medication;
        break;
      case 'test result':
        chipColor = Colors.green;
        chipIcon = Icons.analytics;
        break;
      case 'diagnosis':
        chipColor = Colors.orange;
        chipIcon = Icons.medical_services;
        break;
      case 'vaccination':
        chipColor = Colors.purple;
        chipIcon = Icons.vaccines;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.description;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: chipColor),
          SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeroSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _record!.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildRecordTypeChip(_record!.typeDisplayName),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                '${_record!.date.day}/${_record!.date.month}/${_record!.date.year}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Spacer(),
              Icon(Icons.access_time, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                'Created ${_record!.createdAt.day}/${_record!.createdAt.month}/${_record!.createdAt.year}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: icon != null
            ? Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor ?? Colors.blue, size: 20),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String? value, {IconData? icon}) {
    if (value == null || value.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageGallery() {
    if (_record!.imageUrls.isEmpty) return SizedBox.shrink();
    
    return _buildInfoCard(
      title: 'Images (${_record!.imageUrls.length})',
      icon: Icons.photo_library,
      iconColor: Colors.purple,
      children: [
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _record!.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageDialog(_record!.imageUrls[index]),
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Hero(
                    tag: 'image_$index',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _record!.imageUrls[index],
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                Text('Failed to load', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMedicationCard(Medication med) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.green[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  med.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (med.dosage != null)
            _buildMedDetailRow('Dosage', med.dosage!, Icons.local_pharmacy),
          if (med.frequency != null)
            _buildMedDetailRow('Frequency', med.frequency!, Icons.schedule),
          if (med.duration != null)
            _buildMedDetailRow('Duration', med.duration!, Icons.timer),
          if (med.instructions != null)
            _buildMedDetailRow('Instructions', med.instructions!, Icons.info_outline),
        ],
      ),
    );
  }
  
  Widget _buildMedDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.green[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestResultCard(TestResult result, {bool isCritical = false}) {
    Color statusColor = isCritical
        ? Colors.red
        : result.isAbnormal
            ? Colors.orange
            : Colors.green;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: isCritical ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical ? Icons.warning : Icons.analytics,
                color: statusColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.parameter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTestDetailItem(
                  'Value',
                  '${result.value} ${result.unit}',
                  Icons.straighten,
                ),
              ),
              Expanded(
                child: _buildTestDetailItem(
                  'Reference',
                  result.referenceRange,
                  Icons.tune,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  // Enhanced AI Analysis section to handle dynamic JSON
  Widget _buildAIAnalysisSection() {
    if (_record?.metadata.aiAnalysis == null) return SizedBox.shrink();
    
    final aiAnalysis = _record!.metadata.aiAnalysis!;
    return _buildInfoCard(
      title: 'AI Analysis',
      icon: Icons.psychology,
      iconColor: Colors.purple,
      children: [_buildDynamicJsonContent(aiAnalysis)],
    );
  }

  // Core method to handle dynamic JSON rendering
  Widget _buildDynamicJsonContent(Map<String, dynamic> data) {
    List<Widget> widgets = [];
    
    data.forEach((key, value) {
      if (value != null) {
        widgets.add(_buildJsonField(key, value));
      }
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildJsonField(String key, dynamic value) {
    // Handle different data types
    if (value is Map<String, dynamic>) {
      return _buildNestedObject(key, value);
    } else if (value is List) {
      return _buildJsonArray(key, value);
    } else {
      return _buildSimpleField(key, value);
    }
  }

  Widget _buildSimpleField(String key, dynamic value) {
    String displayValue = _formatValue(value);
    if (displayValue.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[25],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForField(key), size: 16, color: Colors.purple[600]),
          SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              _formatFieldName(key),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.purple[800],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNestedObject(String key, Map<String, dynamic> object) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.purple[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(_getIconForField(key), color: Colors.purple[600], size: 20),
        title: Text(
          _formatFieldName(key),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
            fontSize: 14,
          ),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildDynamicJsonContent(object),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonArray(String key, List array) {
    if (array.isEmpty) return SizedBox.shrink();
    
    // Special handling for medications
    if (key.toLowerCase().contains('medication') && array.isNotEmpty && array.first is Map) {
      return _buildMedicationsFromArray(key, array);
    }
    
    // Special handling for test results
    if ((key.toLowerCase().contains('test') || key.toLowerCase().contains('result')) 
        && array.isNotEmpty && array.first is Map) {
      return _buildTestResultsFromArray(key, array);
    }
    
    // Generic array handling
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.purple[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(_getIconForField(key), color: Colors.purple[600], size: 20),
        title: Text(
          '${_formatFieldName(key)} (${array.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
            fontSize: 14,
          ),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: array.asMap().entries.map((entry) {
                int index = entry.key;
                dynamic item = entry.value;
                
                if (item is Map<String, dynamic>) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildDynamicJsonContent(item),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    margin: EdgeInsets.only(bottom: 4),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '• ${_formatValue(item)}',
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsFromArray(String key, List medications) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.green[600], size: 20),
              SizedBox(width: 8),
              Text(
                '${_formatFieldName(key)} (${medications.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...medications.map((medData) {
            if (medData is Map<String, dynamic>) {
              // Try to create Medication object or display as generic data
              try {
                final medication = Medication.fromJson(medData);
                return _buildMedicationCard(medication);
              } catch (e) {
                return _buildGenericMedicationCard(medData);
              }
            }
            return SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGenericMedicationCard(Map<String, dynamic> medData) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.green[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  medData['name']?.toString() ?? 
                  medData['medication']?.toString() ??
                  medData['drug']?.toString() ??
                  'Medication',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildDynamicJsonContent(medData),
        ],
      ),
    );
  }

  Widget _buildTestResultsFromArray(String key, List results) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Text(
                '${_formatFieldName(key)} (${results.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...results.map((resultData) {
            if (resultData is Map<String, dynamic>) {
              try {
                final testResult = TestResult.fromJson(resultData);
                return _buildTestResultCard(testResult);
              } catch (e) {
                return _buildGenericTestResultCard(resultData);
              }
            }
            return SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

Widget _buildGenericTestResultCard(Map<String, dynamic> resultData) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  resultData['parameter']?.toString() ?? 
                  resultData['test']?.toString() ??
                  resultData['name']?.toString() ?? 
                  'Test Result',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildDynamicJsonContent(resultData),
        ],
      ),
    );
  }

  // Helper method to format field names for display
  String _formatFieldName(String fieldName) {
    // Convert camelCase/snake_case to readable format
    String formatted = fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .toLowerCase();
    
    // Capitalize first letter of each word
    return formatted.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // Helper method to format values for display
  String _formatValue(dynamic value) {
    if (value == null) return '';
    
    if (value is String) {
      return value.trim();
    } else if (value is num) {
      return value.toString();
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is DateTime) {
      return '${value.day}/${value.month}/${value.year}';
    } else if (value is List) {
      if (value.isEmpty) return '';
      return value.map((item) => _formatValue(item)).join(', ');
    } else if (value is Map) {
      return value.toString();
    }
    
    return value.toString();
  }

  // Helper method to get appropriate icons for different field types
  IconData _getIconForField(String fieldName) {
    String lowerField = fieldName.toLowerCase();
    
    if (lowerField.contains('patient') || lowerField.contains('name')) {
      return Icons.person;
    } else if (lowerField.contains('doctor') || lowerField.contains('physician')) {
      return Icons.person_pin;
    } else if (lowerField.contains('date') || lowerField.contains('time')) {
      return Icons.calendar_today;
    } else if (lowerField.contains('medication') || lowerField.contains('drug')) {
      return Icons.medication;
    } else if (lowerField.contains('test') || lowerField.contains('result')) {
      return Icons.analytics;
    } else if (lowerField.contains('diagnosis') || lowerField.contains('condition')) {
      return Icons.medical_services;
    } else if (lowerField.contains('facility') || lowerField.contains('hospital')) {
      return Icons.local_hospital;
    } else if (lowerField.contains('dose') || lowerField.contains('dosage')) {
      return Icons.local_pharmacy;
    } else if (lowerField.contains('frequency') || lowerField.contains('schedule')) {
      return Icons.schedule;
    } else if (lowerField.contains('duration') || lowerField.contains('period')) {
      return Icons.timer;
    } else if (lowerField.contains('instruction') || lowerField.contains('note')) {
      return Icons.info_outline;
    } else if (lowerField.contains('value') || lowerField.contains('amount')) {
      return Icons.straighten;
    } else if (lowerField.contains('reference') || lowerField.contains('range')) {
      return Icons.tune;
    } else if (lowerField.contains('status') || lowerField.contains('condition')) {
      return Icons.check_circle_outline;
    } else if (lowerField.contains('allergy') || lowerField.contains('reaction')) {
      return Icons.warning_amber;
    } else if (lowerField.contains('symptom') || lowerField.contains('complaint')) {
      return Icons.healing;
    } else if (lowerField.contains('vital') || lowerField.contains('sign')) {
      return Icons.favorite;
    } else if (lowerField.contains('weight') || lowerField.contains('height')) {
      return Icons.fitness_center;
    } else if (lowerField.contains('blood') || lowerField.contains('pressure')) {
      return Icons.opacity;
    } else if (lowerField.contains('temperature') || lowerField.contains('fever')) {
      return Icons.thermostat;
    } else if (lowerField.contains('pulse') || lowerField.contains('heart')) {
      return Icons.favorite;
    } else if (lowerField.contains('summary') || lowerField.contains('overview')) {
      return Icons.summarize;
    } else if (lowerField.contains('recommendation') || lowerField.contains('advice')) {
      return Icons.lightbulb_outline;
    } else if (lowerField.contains('follow') || lowerField.contains('next')) {
      return Icons.arrow_forward;
    }
    
    return Icons.info_outline;
  }

  // Add this method to complete the build method
  Widget _buildRecord() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            
            _buildImageGallery(),
            
            _buildInfoCard(
              title: 'Medical Details',
              icon: Icons.medical_information,
              iconColor: Colors.blue,
              children: [
                // _buildDetailRow('Doctor', _record!.metadata.doctorName, icon: Icons.person),
                // _buildDetailRow('Facility', _record!.metadata.facility, icon: Icons.local_hospital),
                // _buildDetailRow('Patient', _record!.metadata.patientName, icon: Icons.person_outline),
                // _buildDetailRow('Test Type', _record!.metadata.testType, icon: Icons.science),
                // _buildDetailRow('Test Date', _record!.metadata.testDate, icon: Icons.calendar_today),
                // _buildDetailRow('Diagnosis', _record!.metadata.diagnosis, icon: Icons.medical_services),
                _buildDetailRow('Notes', _record!.metadata.notes, icon: Icons.note),
              ],
            ),
            
            // Enhanced AI Analysis Section - This will now handle dynamic JSON
            _buildAIAnalysisSection(),
            
            // if (_record!.metadata.medications?.isNotEmpty == true)
            //   _buildInfoCard(
            //     title: 'Medications (${_record!.metadata.medications!.length})',
            //     icon: Icons.medication,
            //     iconColor: Colors.green,
            //     children: _record!.metadata.medications!
            //         .map((med) => _buildMedicationCard(med))
            //         .toList(),
            //   ),
            
            // if (_record!.metadata.criticalResults?.isNotEmpty == true)
            //   _buildInfoCard(
            //     title: 'Critical Results ⚠️',
            //     icon: Icons.warning,
            //     iconColor: Colors.red,
            //     children: _record!.metadata.criticalResults!
            //         .map((result) => _buildTestResultCard(result, isCritical: true))
            //         .toList(),
            //   ),
            
            // if (_record!.metadata.testResults?.isNotEmpty == true)
            //   _buildInfoCard(
            //     title: 'Test Results (${_record!.metadata.testResults!.length})',
            //     icon: Icons.analytics,
            //     iconColor: Colors.green,
            //     children: _record!.metadata.testResults!
            //         .map((result) => _buildTestResultCard(result))
            //         .toList(),
            //   ),
            
            SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Medical Record'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_record != null) ...[
            IconButton(
              icon: Icon(Icons.share_outlined),
              onPressed: () {
                // Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _record == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Record not found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadRecord,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildRecord(),
      floatingActionButton: _record != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "edit",
                  onPressed: _editRecord,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "delete",
                  onPressed: _deleteRecord,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }
}