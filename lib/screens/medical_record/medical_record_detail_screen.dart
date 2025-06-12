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
      setState(() {
        _record = record;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading record: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalRecordEditScreen(
          userId: widget.userId,
          record: _record!,
          //familyMemberId: widget.familyMemberId,
        ),
      ),
    );
    
    if (result == true) {
      _loadRecord();
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
              : FadeTransition(
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
                            _buildDetailRow('Doctor', _record!.metadata.doctorName, icon: Icons.person),
                            _buildDetailRow('Facility', _record!.metadata.facility, icon: Icons.local_hospital),
                            _buildDetailRow('Patient', _record!.metadata.patientName, icon: Icons.person_outline),
                            _buildDetailRow('Test Type', _record!.metadata.testType, icon: Icons.science),
                            _buildDetailRow('Test Date', _record!.metadata.testDate, icon: Icons.calendar_today),
                            _buildDetailRow('Diagnosis', _record!.metadata.diagnosis, icon: Icons.medical_services),
                            _buildDetailRow('Notes', _record!.metadata.notes, icon: Icons.note),
                          ],
                        ),
                        
                        if (_record!.metadata.medications?.isNotEmpty == true)
                          _buildInfoCard(
                            title: 'Medications (${_record!.metadata.medications!.length})',
                            icon: Icons.medication,
                            iconColor: Colors.green,
                            children: _record!.metadata.medications!
                                .map((med) => _buildMedicationCard(med))
                                .toList(),
                          ),
                        
                        if (_record!.metadata.criticalResults?.isNotEmpty == true)
                          _buildInfoCard(
                            title: 'Critical Results ⚠️',
                            icon: Icons.warning,
                            iconColor: Colors.red,
                            children: _record!.metadata.criticalResults!
                                .map((result) => _buildTestResultCard(result, isCritical: true))
                                .toList(),
                          ),
                        
                        if (_record!.metadata.testResults?.isNotEmpty == true)
                          _buildInfoCard(
                            title: 'Test Results (${_record!.metadata.testResults!.length})',
                            icon: Icons.analytics,
                            iconColor: Colors.green,
                            children: _record!.metadata.testResults!
                                .map((result) => _buildTestResultCard(result))
                                .toList(),
                          ),
                        
                        SizedBox(height: 80), // Space for FAB
                      ],
                    ),
                  ),
                ),
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