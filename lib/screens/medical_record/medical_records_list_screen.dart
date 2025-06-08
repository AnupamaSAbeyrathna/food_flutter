// lib/screens/medical_record/medical_records_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/medical_record_display_model.dart';
import '../../services/medical_record_display_service.dart';
import 'medical_record_detail_screen.dart';

class MedicalRecordsListScreen extends StatefulWidget {
  final String userId;
  
  const MedicalRecordsListScreen({Key? key, required this.userId}) : super(key: key);
  
  @override
  State<MedicalRecordsListScreen> createState() => _MedicalRecordsListScreenState();
}

class _MedicalRecordsListScreenState extends State<MedicalRecordsListScreen>
    with TickerProviderStateMixin {
  final MedicalRecordsService _service = MedicalRecordsService();
  final TextEditingController _searchController = TextEditingController();
  
  List<MedicalRecordDisplay> _records = [];
  List<MedicalRecordDisplay> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = '';
  DateTimeRange? _dateRange;
  
  late AnimationController _listAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isFilterExpanded = false;
  
  final List<Map<String, dynamic>> _recordTypes = [
    {'value': '', 'label': 'All Types', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'value': 'prescription', 'label': 'Prescription', 'icon': Icons.medication, 'color': Colors.green},
    {'value': 'medication', 'label': 'Medication', 'icon': Icons.local_pharmacy, 'color': Colors.blue},
    {'value': 'lab_result', 'label': 'Lab Result', 'icon': Icons.science, 'color': Colors.orange},
  ];
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRecords();
  }
  
  void _setupAnimations() {
    _listAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOutCubic),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _listAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await _service.getUserRecords(widget.userId);
      setState(() {
        _records = records;
        _filteredRecords = records;
        _isLoading = false;
      });
      _listAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading records: $e');
    }
  }
  
  void _filterRecords() {
    setState(() {
      _filteredRecords = _records.where((record) {
        bool matchesSearch = _searchQuery.isEmpty ||
            record.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            record.typeDisplayName.toLowerCase().contains(_searchQuery.toLowerCase());
        
        bool matchesType = _selectedType.isEmpty || record.type == _selectedType;
        
        bool matchesDate = _dateRange == null ||
            (record.date.isAfter(_dateRange!.start.subtract(Duration(days: 1))) &&
             record.date.isBefore(_dateRange!.end.add(Duration(days: 1))));
        
        return matchesSearch && matchesType && matchesDate;
      }).toList();
    });
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue[600],
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _dateRange = picked);
      _filterRecords();
    }
  }
  
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = '';
      _dateRange = null;
      _filteredRecords = _records;
    });
    _searchController.clear();
  }
  
  void _toggleFilter() {
    setState(() => _isFilterExpanded = !_isFilterExpanded);
    if (_isFilterExpanded) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  Color _getTypeColor(String type) {
    return _recordTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => _recordTypes[0],
    )['color'];
  }
  
  IconData _getTypeIcon(String type) {
    return _recordTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => _recordTypes[0],
    )['icon'];
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Medical Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_filteredRecords.length} records found',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadRecords,
              ),
            ],
          ),
          
          // Statistics Cards
          if (!_isLoading && _records.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildStatisticsSection(),
            ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),
          
          // Filter Section
          SliverToBoxAdapter(
            child: _buildFilterSection(),
          ),
          
          // Records List
          _isLoading
              ? SliverToBoxAdapter(child: _buildLoadingSection())
              : _filteredRecords.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : _buildRecordsList(),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsSection() {
    final prescriptionCount = _records.where((r) => r.type == 'prescription').length;
    final medicationCount = _records.where((r) => r.type == 'medication').length;
    final labCount = _records.where((r) => r.type == 'lab_result').length;
    final criticalCount = _records.where((r) => r.hasCriticalResults).length;
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Prescriptions', prescriptionCount, Icons.medication, Colors.green)),
          SizedBox(width: 8),
          Expanded(child: _buildStatCard('Medications', medicationCount, Icons.local_pharmacy, Colors.blue)),
          SizedBox(width: 8),
          Expanded(child: _buildStatCard('Lab Results', labCount, Icons.science, Colors.orange)),
          if (criticalCount > 0) ...[
            SizedBox(width: 8),
            Expanded(child: _buildStatCard('Critical', criticalCount, Icons.warning, Colors.red)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search medical records...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery = '';
                      _filterRecords();
                    },
                  )
                : IconButton(
                    icon: Icon(
                      _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                      color: Colors.grey[400],
                    ),
                    onPressed: _toggleFilter,
                  ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _filterRecords();
          },
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isFilterExpanded ? 120 : 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Type Filter Chips
                Wrap(
                  spacing: 8,
                  children: _recordTypes.map((type) {
                    final isSelected = _selectedType == type['value'];
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type['icon'], size: 16, color: isSelected ? Colors.white : type['color']),
                          SizedBox(width: 4),
                          Text(type['label']),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type['value'] : '';
                        });
                        _filterRecords();
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: type['color'],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    );
                  }).toList(),
                ),
                
                SizedBox(height: 12),
                
                // Date Range and Clear Filters
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: Icon(Icons.date_range, size: 16),
                        label: Text(
                          _dateRange == null
                              ? 'Select Date Range'
                              : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedType.isNotEmpty || _dateRange != null) ...[
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text('Clear'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(5, (index) => _buildShimmerCard()),
      ),
    );
  }
  
  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, color: Colors.grey[300]),
                SizedBox(height: 8),
                Container(height: 12, width: 100, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_information_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Medical Records Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedType.isNotEmpty || _dateRange != null
                ? 'Try adjusting your filters'
                : 'Your medical records will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedType.isNotEmpty || _dateRange != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRecordsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final record = _filteredRecords[index];
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildRecordCard(record),
              ),
            ),
          );
        },
        childCount: _filteredRecords.length,
      ),
    );
  }
  
  Widget _buildRecordCard(MedicalRecordDisplay record) {
    final typeColor = _getTypeColor(record.type);
    final typeIcon = _getTypeIcon(record.type);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicalRecordDetailScreen(
                  userId: widget.userId,
                  recordId: record.id,
                ),
              ),
            );
            
            if (result == true) {
              _loadRecords();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Image or Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor.withOpacity(0.3), width: 2),
                  ),
                  child: record.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            record.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(typeIcon, color: typeColor, size: 24),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 24),
                        ),
                ),
                
                SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(typeIcon, size: 14, color: typeColor),
                          SizedBox(width: 4),
                          Text(
                            record.typeDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            '${record.date.day}/${record.date.month}/${record.date.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Trailing
                Column(
                  children: [
                    if (record.hasCriticalResults)
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning, color: Colors.red, size: 16),
                      )
                    else
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    
                    if (record.imageUrls.length > 1) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${record.imageUrls.length - 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}