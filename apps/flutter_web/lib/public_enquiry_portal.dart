import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/theme.dart';
import 'core/services/api_service.dart';
import 'core/services/file_helper.dart';
import 'core/services/gps_resolver.dart';
import 'core/widgets/drawing_canvases.dart';
import 'core/widgets/custom_widgets.dart';
import 'package:file_picker/file_picker.dart';

class PublicEnquiryPortalPage extends StatefulWidget {
  final String token;
  const PublicEnquiryPortalPage({Key? key, required this.token}) : super(key: key);

  @override
  State<PublicEnquiryPortalPage> createState() => _PublicEnquiryPortalPageState();
}

class _PublicEnquiryPortalPageState extends State<PublicEnquiryPortalPage> {
  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic>? _linkInfo;
  Timer? _autosaveTimer;

  // Header Details
  final String _estTime = '8 Minutes';

  // Section 1: Client Information
  final _clientNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _preferredContactTimeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ').first);

  // Section 2: Site Details
  final _siteAddressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _talukCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Tamil Nadu');
  final _pincodeCtrl = TextEditingController();

  // Site Facing Compass Details
  String? _selectedSiteFacing;

  // Section 3: Building Type
  final List<String> _selectedBuildingTypes = [];

  // Section 4: Local Authority
  String? _selectedLocalAuthority;

  // Section 5: Road Details
  final _roadWidthCtrl = TextEditingController();
  final _frontRoadWidthCtrl = TextEditingController();
  final _mainRoadWidthCtrl = TextEditingController();
  final _connectingRoadWidthCtrl = TextEditingController();

  // Section 6: Site Soil Condition
  final List<String> _selectedSiteConditions = [];
  final _siteConditionOtherCtrl = TextEditingController();

  // Section 7: Water Condition
  final List<String> _waterCondition = [];
  bool _boreAvailable = false;
  final _boreDepthCtrl = TextEditingController();
  final _waterLevelCtrl = TextEditingController();
  final _waterRemarksCtrl = TextEditingController();

  // Section 8: EB Connection
  String? _electricityConnection;
  final _ebDistanceCtrl = TextEditingController();
  final _ebRemarksCtrl = TextEditingController();

  // Section 9: Drainage
  String? _drainageType;
  final _drainageRemarksCtrl = TextEditingController();

  // Section 10: Underground Sump
  bool _undergroundSump = false;
  final _sumpCapacityCtrl = TextEditingController();
  final _sumpRemarksCtrl = TextEditingController();

  // Section 11: Road to Plinth Level
  String? _roadToPlinth;
  final _roadToPlinthRemarksCtrl = TextEditingController();

  // Section 12: Site Level from Road
  String? _siteLevel;
  final _siteLevelRemarksCtrl = TextEditingController();

  // Section 13: Parking
  int _parkingCars = 0;
  int _parkingBikes = 0;
  final _parkingRemarksCtrl = TextEditingController();

  // Section 14: Water Tank
  String? _waterTankCapacity;
  final _customWaterTankCtrl = TextEditingController();

  // Section 15: Purpose of Building
  String? _buildingPurpose;

  // Section 16: Staircase
  String? _staircaseDesign;

  // Section 17: Terrace Access
  String? _terraceAccess;
  final _terraceRemarksCtrl = TextEditingController();

  // Section 18: Existing Site Context
  String? _contextNorth;
  final _contextNorthRemarksCtrl = TextEditingController();
  String? _contextSouth;
  final _contextSouthRemarksCtrl = TextEditingController();
  String? _contextEast;
  final _contextEastRemarksCtrl = TextEditingController();
  String? _contextWest;
  final _contextWestRemarksCtrl = TextEditingController();

  // Section 19: Client Requirements
  final _requirementsCtrl = TextEditingController();

  // Section 20: Site Layout Upload Preview States
  Map<String, dynamic>? _siteLayoutFile;
  double _layoutScale = 1.0;
  double _layoutRotation = 0.0;

  // Section 21: Notes (Voice Dictation support mock)
  final _notesCtrl = TextEditingController();
  bool _isDictating = false;

  // Section 22: Conceptual Ideas attachments list
  final List<Map<String, dynamic>> _conceptualIdeasFiles = [];

  // Section 23: Attachments Upload List
  final List<Map<String, dynamic>> _attachmentsList = [];

  // Section 24: Client Confirmation
  final _confirmNameCtrl = TextEditingController();
  String? _relationship;
  bool _confirmCheckbox = false;

  @override
  void initState() {
    super.initState();
    _fetchLinkInfo();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLinkInfo() async {
    final res = await ApiService.getEnquiryLink(widget.token);
    if (res['success'] == true) {
      setState(() {
        _linkInfo = res['link'];
        _loading = false;
      });
      // Restore draft if any
      if (res['draft'] != null) {
        _loadFormFromDraft(res['draft']);
      }
      // Start 30 seconds autosave timer
      _autosaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _triggerAutosave();
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Invalid enquiry token';
        _loading = false;
      });
    }
  }

  void _loadFormFromDraft(Map<String, dynamic> draft) {
    _clientNameCtrl.text = draft['clientName'] ?? '';
    _mobileCtrl.text = draft['contactNumber'] ?? '';
    _whatsappCtrl.text = draft['whatsappNumber'] ?? '';
    _emailCtrl.text = draft['email'] ?? '';
    _occupationCtrl.text = draft['occupation'] ?? '';
    _preferredContactTimeCtrl.text = draft['preferredContactTime'] ?? '';
    _siteAddressCtrl.text = draft['siteAddress'] ?? '';
    _landmarkCtrl.text = draft['nearLandmark'] ?? '';
    _latCtrl.text = draft['latitude'] ?? '';
    _lngCtrl.text = draft['longitude'] ?? '';
    _villageCtrl.text = draft['village'] ?? '';
    _talukCtrl.text = draft['taluk'] ?? '';
    _districtCtrl.text = draft['district'] ?? '';
    _stateCtrl.text = draft['state'] ?? 'Tamil Nadu';
    _pincodeCtrl.text = draft['pincode'] ?? '';
    _selectedSiteFacing = draft['siteFacing'];
    
    if (draft['buildingType'] != null && (draft['buildingType'] as String).isNotEmpty) {
      _selectedBuildingTypes.clear();
      _selectedBuildingTypes.addAll((draft['buildingType'] as String).split(', '));
    }
    _selectedLocalAuthority = draft['localAuthority'];
    _roadWidthCtrl.text = draft['roadWidth'] ?? '';
    _frontRoadWidthCtrl.text = draft['frontRoadWidth'] ?? '';
    _mainRoadWidthCtrl.text = draft['mainRoadWidth'] ?? '';
    _connectingRoadWidthCtrl.text = draft['connectingRoadWidth'] ?? '';

    if (draft['siteCondition'] != null && (draft['siteCondition'] as String).isNotEmpty) {
      _selectedSiteConditions.clear();
      _selectedSiteConditions.addAll((draft['siteCondition'] as String).split(', '));
    }
    _siteConditionOtherCtrl.text = draft['siteConditionOther'] ?? '';
    if (draft['waterCondition'] != null && (draft['waterCondition'] as String).isNotEmpty) {
      _waterCondition.clear();
      _waterCondition.addAll((draft['waterCondition'] as String).split(', '));
    }
    _boreAvailable = draft['boreAvailable'] == true;
    _boreDepthCtrl.text = draft['boreDepth'] ?? '';
    _waterLevelCtrl.text = draft['waterLevel'] ?? '';
    _waterRemarksCtrl.text = draft['waterRemarks'] ?? '';
    _electricityConnection = draft['electricity'];
    _ebDistanceCtrl.text = draft['ebDistance'] ?? '';
    _ebRemarksCtrl.text = draft['electricityRemarks'] ?? '';
    _drainageType = draft['drainage'];
    _drainageRemarksCtrl.text = draft['drainageRemarks'] ?? '';
    _undergroundSump = draft['undergroundSump'] == true;
    _sumpCapacityCtrl.text = draft['undergroundSumpCapacity'] ?? '';
    _sumpRemarksCtrl.text = draft['undergroundSumpRemarks'] ?? '';
    _roadToPlinth = draft['roadToPlinth'];
    _roadToPlinthRemarksCtrl.text = draft['roadToPlinthRemarks'] ?? '';
    _siteLevel = draft['siteLevel'];
    _siteLevelRemarksCtrl.text = draft['siteLevelRemarks'] ?? '';
    _parkingCars = draft['parkingCars'] ?? 0;
    _parkingBikes = draft['parkingBikes'] ?? 0;
    _parkingRemarksCtrl.text = draft['parkingRemarks'] ?? '';
    _waterTankCapacity = draft['waterTankCapacity'];
    _buildingPurpose = draft['buildingPurpose'];
    _staircaseDesign = draft['staircase'];
    _terraceAccess = draft['terraceAccess'];
    _terraceRemarksCtrl.text = draft['terraceRemarks'] ?? '';
    _contextNorth = draft['northContextType'];
    _contextNorthRemarksCtrl.text = draft['northContext'] ?? '';
    _contextSouth = draft['southContextType'];
    _contextSouthRemarksCtrl.text = draft['southContext'] ?? '';
    _contextEast = draft['eastContextType'];
    _contextEastRemarksCtrl.text = draft['eastContext'] ?? '';
    _contextWest = draft['westContextType'];
    _contextWestRemarksCtrl.text = draft['westContext'] ?? '';

    _requirementsCtrl.text = draft['clientRequirements'] ?? '';
    _notesCtrl.text = draft['notes'] ?? '';
    _confirmNameCtrl.text = draft['confirmFullName'] ?? '';
    _relationship = draft['relationship'];
    _confirmCheckbox = draft['confirmCheckbox'] == true;

    if (draft['attachments'] != null) {
      _attachmentsList.clear();
      _attachmentsList.addAll(List<Map<String, dynamic>>.from(draft['attachments']));
    }
    if (draft['conceptualIdeas'] != null) {
      _conceptualIdeasFiles.clear();
      _conceptualIdeasFiles.addAll(List<Map<String, dynamic>>.from(draft['conceptualIdeas']));
    }
    if (draft['siteLayout'] != null) {
      _siteLayoutFile = Map<String, dynamic>.from(draft['siteLayout']);
    }
  }

  Map<String, dynamic> _compileFormState() {
    return {
      'clientName': _clientNameCtrl.text,
      'contactNumber': _mobileCtrl.text,
      'whatsappNumber': _whatsappCtrl.text,
      'email': _emailCtrl.text,
      'occupation': _occupationCtrl.text,
      'preferredContactTime': _preferredContactTimeCtrl.text,
      'date': _dateCtrl.text,
      'siteAddress': _siteAddressCtrl.text,
      'nearLandmark': _landmarkCtrl.text,
      'latitude': _latCtrl.text,
      'longitude': _lngCtrl.text,
      'village': _villageCtrl.text,
      'taluk': _talukCtrl.text,
      'district': _districtCtrl.text,
      'state': _stateCtrl.text,
      'pincode': _pincodeCtrl.text,
      'siteFacing': _selectedSiteFacing,
      'buildingType': _selectedBuildingTypes.join(', '),
      'localAuthority': _selectedLocalAuthority,
      'roadWidth': _roadWidthCtrl.text,
      'frontRoadWidth': _frontRoadWidthCtrl.text,
      'mainRoadWidth': _mainRoadWidthCtrl.text,
      'connectingRoadWidth': _connectingRoadWidthCtrl.text,
      'siteCondition': _selectedSiteConditions.join(', '),
      'siteConditionOther': _siteConditionOtherCtrl.text,
      'waterCondition': _waterCondition.join(', '),
      'boreAvailable': _boreAvailable,
      'boreDepth': _boreDepthCtrl.text,
      'waterLevel': _waterLevelCtrl.text,
      'waterRemarks': _waterRemarksCtrl.text,
      'electricity': _electricityConnection,
      'ebDistance': _ebDistanceCtrl.text,
      'electricityRemarks': _ebRemarksCtrl.text,
      'drainage': _drainageType,
      'drainageRemarks': _drainageRemarksCtrl.text,
      'undergroundSump': _undergroundSump,
      'undergroundSumpCapacity': _sumpCapacityCtrl.text,
      'undergroundSumpRemarks': _sumpRemarksCtrl.text,
      'roadToPlinth': _roadToPlinth,
      'roadToPlinthRemarks': _roadToPlinthRemarksCtrl.text,
      'siteLevel': _siteLevel,
      'siteLevelRemarks': _siteLevelRemarksCtrl.text,
      'parkingCars': _parkingCars,
      'parkingBikes': _parkingBikes,
      'parkingRemarks': _parkingRemarksCtrl.text,
      'waterTankCapacity': _waterTankCapacity,
      'buildingPurpose': _buildingPurpose,
      'staircase': _staircaseDesign,
      'terraceAccess': _terraceAccess,
      'terraceRemarks': _terraceRemarksCtrl.text,
      'northContextType': _contextNorth,
      'northContext': _contextNorthRemarksCtrl.text,
      'southContextType': _contextSouth,
      'southContext': _contextSouthRemarksCtrl.text,
      'eastContextType': _contextEast,
      'eastContext': _contextEastRemarksCtrl.text,
      'westContextType': _contextWest,
      'westContext': _contextWestRemarksCtrl.text,
      'clientRequirements': _requirementsCtrl.text,
      'notes': _notesCtrl.text,
      'confirmFullName': _confirmNameCtrl.text,
      'relationship': _relationship,
      'confirmCheckbox': _confirmCheckbox,
      'attachments': _attachmentsList,
      'conceptualIdeas': _conceptualIdeasFiles,
      'siteLayout': _siteLayoutFile
    };
  }

  Future<void> _triggerAutosave() async {
    final formState = _compileFormState();
    await ApiService.saveEnquiryDraft(widget.token, formState);
  }

  Future<void> _handleFileUpload(String category) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'dwg', 'heic'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > 25 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File exceeds 25 MB size limit.'))
      );
      return;
    }

    final List<int> bytes = file.bytes ?? <int>[];
    if (bytes.isEmpty) return;

    final res = await ApiService.uploadEnquiryAttachment(file.name, bytes);
    if (res['success'] == true) {
      setState(() {
        final docPayload = {
          'fileName': file.name,
          'fileUrl': res['fileUrl'],
          'fileSize': file.size,
          'fileType': category
        };

        if (category == 'Layout') {
          _siteLayoutFile = docPayload;
          _layoutScale = 1.0;
          _layoutRotation = 0.0;
        } else if (category == 'Conceptual') {
          _conceptualIdeasFiles.add(docPayload);
        } else {
          _attachmentsList.add(docPayload);
        }
      });
      _triggerAutosave();
    }
  }

  Future<void> _submitForm() async {
    if (_clientNameCtrl.text.isEmpty || _mobileCtrl.text.isEmpty || _siteAddressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields (*).'))
      );
      return;
    }
    if (!_confirmCheckbox || _confirmNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please review electronic signature and check "I Agree".'))
      );
      return;
    }

    setState(() => _loading = true);
    final payload = _compileFormState();
    final res = await ApiService.submitEnquiry(widget.token, payload);
    if (res['success'] == true) {
      context.go('/enquiry-success/${res['referenceNumber']}');
    } else {
      setState(() {
        _loading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${res['message']}'))
        );
      });
    }
  }

  double _calculateCompletion() {
    int total = 7;
    int completed = 0;
    if (_clientNameCtrl.text.isNotEmpty) completed++;
    if (_mobileCtrl.text.isNotEmpty) completed++;
    if (_siteAddressCtrl.text.isNotEmpty) completed++;
    if (_selectedBuildingTypes.isNotEmpty) completed++;
    if (_confirmNameCtrl.text.isNotEmpty) completed++;
    if (_confirmCheckbox) completed++;
    if (_requirementsCtrl.text.isNotEmpty) completed++;
    return completed / total;
  }

  void _mockVoiceDictation() {
    setState(() => _isDictating = true);
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isDictating = false;
        _notesCtrl.text += ' (Dictated: Premium glassmorphism design layouts with double floor height in living areas required.)';
      });
      _triggerAutosave();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: VianTheme.primaryGold)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: VianTheme.danger),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
        ),
      );
    }

    final progress = _calculateCompletion();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Glassmorphism
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E26),
                border: Border(bottom: BorderSide(color: VianTheme.primaryGold, width: 2)),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      const Icon(Icons.architecture, size: 56, color: VianTheme.primaryGold),
                      const SizedBox(height: 12),
                      Text(
                        'VIAN ARCHITECTS',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: VianTheme.primaryGold,
                          letterSpacing: 2.5
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'NEW CLIENT ENQUIRY FORM',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome to VIAN Architects & Interior Designers. Estimated Time: $_estTime',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: VianTheme.lightText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E1E26),
              valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
              minHeight: 6,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // Section 1: Client Information
                      _buildSectionCard('Section 1: Client Information', [
                        _buildTextField('Client Name *', _clientNameCtrl),
                        _buildTextField('Contact Number *', _mobileCtrl, keyboardType: TextInputType.phone),
                        _buildTextField('WhatsApp Number', _whatsappCtrl, keyboardType: TextInputType.phone),
                        _buildTextField('Email Address', _emailCtrl, keyboardType: TextInputType.emailAddress),
                        _buildTextField('Occupation', _occupationCtrl),
                        _buildTextField('Preferred Contact Time', _preferredContactTimeCtrl),
                        _buildTextField('Submission Date (Auto Filled)', _dateCtrl, readOnly: true),
                      ]),

                      // Section 2: Site Details
                      _buildSectionCard('Section 2: Site Details', [
                        _buildTextField('Site Address *', _siteAddressCtrl, maxLines: 2),
                        _buildTextField('Near Landmark', _landmarkCtrl),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Latitude', _latCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Longitude', _lngCtrl)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Village / City', _villageCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Taluk', _talukCtrl)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('District', _districtCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('State', _stateCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Pincode', _pincodeCtrl)),
                          ],
                        ),
                      ]),

                      // Site Facing Compass
                      _buildSectionCard('Site Facing (Compass Direction)', [
                        const Text('Select property frontage facing:', style: TextStyle(color: VianTheme.lightText, fontSize: 13)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ['North', 'South', 'East', 'West', 'North East', 'North West', 'South East', 'South West'].map((face) {
                            final sel = _selectedSiteFacing == face;
                            return ChoiceChip(
                              label: Text(face),
                              selected: sel,
                              onSelected: (val) {
                                if (val) setState(() => _selectedSiteFacing = face);
                              },
                            );
                          }).toList(),
                        ),
                      ]),

                      // Section 3: Building Type
                      _buildSectionCard('Section 3: Building Type', [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildSelectionCard('🏠 Residential', 'Residential'),
                            _buildSelectionCard('🏢 Commercial', 'Commercial'),
                            _buildSelectionCard('🏗 New Building', 'New Building'),
                            _buildSelectionCard('🔨 Renovation', 'Renovation'),
                            _buildSelectionCard('🏚 Built After Demolition', 'Built After Demolition'),
                          ],
                        ),
                      ]),

                      // Section 4: Local Authority
                      _buildSectionCard('Section 4: Local Authority', [
                        _buildDropdown('Local Authority', ['Panchayat', 'Taluk', 'Municipality', 'Corporation'], _selectedLocalAuthority, (val) {
                          setState(() => _selectedLocalAuthority = val);
                        }),
                      ]),

                      // Section 5: Road Details
                      _buildSectionCard('Section 5: Road Width & Details', [
                        _buildTextField('Road Width (Feet)', _roadWidthCtrl, keyboardType: TextInputType.number),
                        _buildTextField('Front Road Width (Feet)', _frontRoadWidthCtrl, keyboardType: TextInputType.number),
                        _buildTextField('Main Road Width (Feet)', _mainRoadWidthCtrl, keyboardType: TextInputType.number),
                        _buildTextField('Connecting Road Width (Feet)', _connectingRoadWidthCtrl, keyboardType: TextInputType.number),
                      ]),

                      // Section 6: Site Soil Condition
                      _buildSectionCard('Section 6: Site Condition', [
                        Wrap(
                          spacing: 8,
                          children: ['Clay', 'Sand', 'Farm Land', 'Rock', 'Filled Land', 'Other'].map((cond) {
                            final selected = _selectedSiteConditions.contains(cond);
                            return FilterChip(
                              selected: selected,
                              label: Text(cond),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedSiteConditions.add(cond);
                                  } else {
                                    _selectedSiteConditions.remove(cond);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (_selectedSiteConditions.contains('Other')) ...[
                          const SizedBox(height: 12),
                          _buildTextField('If Other (Please describe)', _siteConditionOtherCtrl),
                        ]
                      ]),

                      // Section 7: Water Condition
                      _buildSectionCard('Section 7: Water Condition', [
                        Wrap(
                          spacing: 16,
                          children: ['Salty', 'Yellowish', 'White'].map((w) {
                            final checked = _waterCondition.contains(w);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: checked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _waterCondition.add(w);
                                      } else {
                                        _waterCondition.remove(w);
                                      }
                                    });
                                  },
                                ),
                                Text(w),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _boreAvailable,
                              onChanged: (val) => setState(() => _boreAvailable = val ?? false),
                            ),
                            const Text('Borewell Available'),
                          ],
                        ),
                        if (_boreAvailable) ...[
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Bore Depth (Feet)', _boreDepthCtrl, keyboardType: TextInputType.number)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('Water Level (Feet)', _waterLevelCtrl, keyboardType: TextInputType.number)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildTextField('Remarks', _waterRemarksCtrl),
                      ]),

                      // Section 8: EB Connection
                      _buildSectionCard('Section 8: EB Connection', [
                        _buildRadioGroup('Connection Type', ['New', 'Existing'], _electricityConnection, (val) {
                          setState(() => _electricityConnection = val);
                        }),
                        _buildTextField('EB Pole Distance (Meters)', _ebDistanceCtrl, keyboardType: TextInputType.number),
                        _buildTextField('Remarks', _ebRemarksCtrl),
                      ]),

                      // Section 9: Drainage
                      _buildSectionCard('Section 9: Drainage', [
                        _buildRadioGroup('Type', ['Government', 'Septic Tank', 'Manual', 'Bio Septic'], _drainageType, (val) {
                          setState(() => _drainageType = val);
                        }),
                        _buildTextField('Remarks', _drainageRemarksCtrl),
                      ]),

                      // Section 10: Underground Sump
                      _buildSectionCard('Section 10: Underground Sump', [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sump Needed?', style: TextStyle(fontWeight: FontWeight.bold)),
                            Switch(
                              value: _undergroundSump,
                              onChanged: (val) => setState(() => _undergroundSump = val),
                            ),
                          ],
                        ),
                        if (_undergroundSump) ...[
                          _buildTextField('Capacity (Liters)', _sumpCapacityCtrl, keyboardType: TextInputType.number),
                        ],
                        _buildTextField('Remarks', _sumpRemarksCtrl),
                      ]),

                      // Section 11: Road to Plinth Level
                      _buildSectionCard('Section 11: Road to Plinth Level', [
                        _buildDropdown('Height', ['1.6 ft', '2.0 ft', '2.6 ft', '3.0 ft', '3.6 ft'], _roadToPlinth, (val) {
                          setState(() => _roadToPlinth = val);
                        }),
                        _buildTextField('Remarks', _roadToPlinthRemarksCtrl),
                      ]),

                      // Section 12: Site Level from Road
                      _buildSectionCard('Section 12: Site Level from Road', [
                        _buildDropdown('Offset', ['6"', '1\'-0"', '1\'-6"', '2\'-0"', '2\'-6"'], _siteLevel, (val) {
                          setState(() => _siteLevel = val);
                        }),
                        _buildTextField('Remarks', _siteLevelRemarksCtrl),
                      ]),

                      // Section 13: Parking
                      _buildSectionCard('Section 13: Parking Requirements', [
                        _buildStepper('Cars slots', _parkingCars, (val) => setState(() => _parkingCars = val)),
                        const SizedBox(height: 16),
                        _buildStepper('Bikes slots', _parkingBikes, (val) => setState(() => _parkingBikes = val)),
                        const SizedBox(height: 12),
                        _buildTextField('Remarks', _parkingRemarksCtrl),
                      ]),

                      // Section 14: Water Tank
                      _buildSectionCard('Section 14: Water Tank', [
                        Wrap(
                          spacing: 12,
                          children: ['500', '750', '1000', '1500', '2000', 'Custom'].map((cap) {
                            final sel = _waterTankCapacity == cap;
                            return ChoiceChip(
                              label: Text(cap),
                              selected: sel,
                              onSelected: (val) {
                                if (val) setState(() => _waterTankCapacity = cap);
                              },
                            );
                          }).toList(),
                        ),
                        if (_waterTankCapacity == 'Custom') ...[
                          const SizedBox(height: 12),
                          _buildTextField('Custom Capacity', _customWaterTankCtrl),
                        ]
                      ]),

                      // Section 15: Purpose of Building
                      _buildSectionCard('Section 15: Purpose of Building', [
                        _buildRadioGroup('Purpose', ['Personal', 'Rental', 'Both'], _buildingPurpose, (val) {
                          setState(() => _buildingPurpose = val);
                        }),
                      ]),

                      // Section 16: Staircase
                      _buildSectionCard('Section 16: Staircase', [
                        _buildRadioGroup('Staircase Type', ['Internal', 'External', 'Concrete', 'Steel', 'Floating Stair', 'Spiral Stair'], _staircaseDesign, (val) {
                          setState(() => _staircaseDesign = val);
                        }),
                      ]),

                      // Section 17: Terrace Access
                      _buildSectionCard('Section 17: Terrace Access', [
                        _buildRadioGroup('Access Type', ['Concrete Staircase', 'Steel Staircase', 'Other'], _terraceAccess, (val) {
                          setState(() => _terraceAccess = val);
                        }),
                        _buildTextField('Remarks', _terraceRemarksCtrl),
                      ]),

                      // Section 18: Existing Site Context
                      _buildSectionCard('Section 18: Existing Site Context', [
                        const Text('Describe property boundary neighbors:', style: TextStyle(color: VianTheme.lightText, fontSize: 13)),
                        const SizedBox(height: 16),
                        _buildContextCard('North Neighbor', _contextNorth, (val) => setState(() => _contextNorth = val), _contextNorthRemarksCtrl),
                        _buildContextCard('South Neighbor', _contextSouth, (val) => setState(() => _contextSouth = val), _contextSouthRemarksCtrl),
                        _buildContextCard('East Neighbor', _contextEast, (val) => setState(() => _contextEast = val), _contextEastRemarksCtrl),
                        _buildContextCard('West Neighbor', _contextWest, (val) => setState(() => _contextWest = val), _contextWestRemarksCtrl),
                      ]),

                      // Section 19: Client Requirements
                      _buildSectionCard('Section 19: Client Requirements', [
                        _buildTextField(
                          'Floor layout room requirements spec',
                          _requirementsCtrl,
                          maxLines: 10,
                          hintText: 'Example:\nGround Floor: 2 BHK, Pooja, Sitout\nFirst Floor: 2 Bedrooms, Gym, Home Theatre, Swimming Pool\nSpecial Requirements: Smart home integration, floating stairs',
                        ),
                      ]),

                      // Section 20: Site Layout Upload & Custom Scale/Rotate Preview
                      _buildSectionCard('Section 20: Site Layout Document (Max 25MB)', [
                        if (_siteLayoutFile != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(_siteLayoutFile!['fileName'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.zoom_in, color: VianTheme.primaryGold),
                                          onPressed: () => setState(() => _layoutScale += 0.25),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.zoom_out, color: VianTheme.primaryGold),
                                          onPressed: () => setState(() => _layoutScale = _layoutScale > 0.5 ? _layoutScale - 0.25 : 0.5),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.rotate_right, color: VianTheme.primaryGold),
                                          onPressed: () => setState(() => _layoutRotation += 90.0),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: VianTheme.danger),
                                          onPressed: () => setState(() => _siteLayoutFile = null),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Preview Container
                                Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                                  clipBehavior: Clip.hardEdge,
                                  child: Center(
                                    child: Transform.rotate(
                                      angle: _layoutRotation * 3.1415926535 / 180,
                                      child: Transform.scale(
                                        scale: _layoutScale,
                                        child: _siteLayoutFile!['fileName'].toString().toLowerCase().endsWith('.pdf')
                                            ? const Icon(Icons.picture_as_pdf, size: 80, color: Colors.white)
                                            : Image.network(_siteLayoutFile!['fileUrl'], errorBuilder: (c, o, s) => const Icon(Icons.insert_drive_file, size: 80)),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                            onPressed: () => _handleFileUpload('Layout'),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Site Layout'),
                          ),
                        ],
                      ]),

                      // Section 21: Notes with dictation support
                      _buildSectionCard('Section 21: Additional Notes', [
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Notes', _notesCtrl, maxLines: 4)),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(_isDictating ? Icons.mic : Icons.mic_none, color: _isDictating ? VianTheme.danger : VianTheme.primaryGold, size: 28),
                              onPressed: _mockVoiceDictation,
                              tooltip: 'Mock Voice Dictation',
                            ),
                          ],
                        ),
                      ]),

                      // Section 22: Conceptual Ideas
                      _buildSectionCard('Section 22: Conceptual Ideas & Sketches', [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E26), foregroundColor: VianTheme.primaryGold),
                          onPressed: () => _handleFileUpload('Conceptual'),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Reference Images / Sketches'),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _conceptualIdeasFiles.length,
                          itemBuilder: (context, index) {
                            final f = _conceptualIdeasFiles[index];
                            return ListTile(
                              leading: const Icon(Icons.image, color: VianTheme.primaryGold),
                              title: Text(f['fileName']),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: VianTheme.danger),
                                onPressed: () => setState(() => _conceptualIdeasFiles.removeAt(index)),
                              ),
                            );
                          },
                        ),
                      ]),

                      // Section 23: Attachments
                      _buildSectionCard('Section 23: Document Attachments', [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E26), foregroundColor: VianTheme.primaryGold),
                          onPressed: () => _handleFileUpload('Attachment'),
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Upload Aadhaar, PAN, Patta, EC...'),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attachmentsList.length,
                          itemBuilder: (context, index) {
                            final f = _attachmentsList[index];
                            return ListTile(
                              leading: const Icon(Icons.file_present, color: VianTheme.primaryGold),
                              title: Text(f['fileName']),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: VianTheme.danger),
                                onPressed: () => setState(() => _attachmentsList.removeAt(index)),
                              ),
                            );
                          },
                        ),
                      ]),

                      // Section 24: Client Confirmation
                      _buildSectionCard('Section 24: Confirmation & Sign-off', [
                        const Text(
                          'I confirm that the information entered above is correct to the best of my knowledge.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Full Name (Electronic Signature) *', _confirmNameCtrl),
                        _buildDropdown('Relationship to property owner', ['Owner', 'Family Member', 'Builder', 'Contractor', 'Representative', 'Other'], _relationship, (val) {
                          setState(() => _relationship = val);
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _confirmCheckbox,
                              onChanged: (val) => setState(() => _confirmCheckbox = val ?? false),
                            ),
                            const Expanded(child: Text('I Agree and submit.')),
                          ],
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Submit Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: _triggerAutosave,
                            child: const Text('Save Draft'),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: VianTheme.danger, side: const BorderSide(color: VianTheme.danger)),
                            onPressed: () {
                              setState(() {
                                _selectedBuildingTypes.clear();
                                _selectedSiteConditions.clear();
                                _attachmentsList.clear();
                                _conceptualIdeasFiles.clear();
                                _siteLayoutFile = null;
                                _confirmCheckbox = false;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VianTheme.primaryGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                            ),
                            onPressed: _submitForm,
                            child: const Text('Submit Enquiry'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: double.infinity,
      child: VianCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: VianTheme.primaryGold,
              ),
            ),
            const Divider(color: Color(0xFF2C2C35), height: 24),
            ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? hintText, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 13),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF70707C), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E1E26),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      dropdownColor: const Color(0xFF1E1E26),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E1E26),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSelectionCard(String label, String value) {
    final selected = _selectedBuildingTypes.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedBuildingTypes.remove(value);
          } else {
            _selectedBuildingTypes.add(value);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? VianTheme.primaryGold.withOpacity(0.1) : const Color(0xFF1E1E26),
          border: Border.all(color: selected ? VianTheme.primaryGold : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: selected ? VianTheme.primaryGold : Colors.white, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildRadioGroup(String label, List<String> options, String? currentValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: options.map((opt) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: opt,
                  groupValue: currentValue,
                  activeColor: VianTheme.primaryGold,
                  onChanged: onChanged,
                ),
                Text(opt),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepper(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 13)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: VianTheme.primaryGold),
              onPressed: () => onChanged(value > 0 ? value - 1 : 0),
            ),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: VianTheme.primaryGold),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextCard(String direction, String? contextType, ValueChanged<String?> onChanged, TextEditingController controller) {
    final list = ['House', 'Apartment', 'Shop', 'Commercial Building', 'School', 'Temple', 'Road', 'Vacant Land', 'Agriculture', 'Lake', 'River', 'Hospital', 'Factory', 'Other'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(direction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.primaryGold)),
          const SizedBox(height: 8),
          _buildDropdown('Structure Category', list, contextType, onChanged),
          const SizedBox(height: 8),
          _buildTextField('Remarks/Notes', controller),
        ],
      ),
    );
  }
}

class PublicEnquirySuccessPage extends StatelessWidget {
  final String refCode;
  const PublicEnquirySuccessPage({Key? key, required this.refCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: VianCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 80, color: VianTheme.success),
                const SizedBox(height: 24),
                Text(
                  'Thank You!',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: VianTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your enquiry has been successfully submitted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Text('Reference Number', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        refCode,
                        style: const TextStyle(color: VianTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Our team will contact you shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: VianTheme.lightText, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnquiryInboxTab extends StatefulWidget {
  const EnquiryInboxTab({Key? key}) : super(key: key);

  @override
  State<EnquiryInboxTab> createState() => _EnquiryInboxTabState();
}

class _EnquiryInboxTabState extends State<EnquiryInboxTab> {
  List<dynamic> _submissions = [];
  bool _loading = true;
  String _selectedStatus = 'New';
  Map<String, dynamic>? _selectedSubmission;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    final list = await ApiService.getEnquiryInbox();
    setState(() {
      _submissions = list;
      _loading = false;
      if (_selectedSubmission != null) {
        final match = list.where((s) => s['id'] == _selectedSubmission!['id']).toList();
        _selectedSubmission = match.isNotEmpty ? match.first : null;
      }
    });
  }

  Future<void> _updateStatus(String status) async {
    if (_selectedSubmission == null) return;
    final res = await ApiService.updateEnquiryStatus(_selectedSubmission!['id'], status);
    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status'))
      );
      _fetchInbox();
    }
  }

  Future<void> _addNote() async {
    if (_selectedSubmission == null || _noteCtrl.text.trim().isEmpty) return;
    final res = await ApiService.addEnquiryNote(_selectedSubmission!['id'], _noteCtrl.text.trim());
    if (res) {
      _noteCtrl.clear();
      _fetchInbox();
    }
  }

  Future<void> _approveAndConvert() async {
    if (_selectedSubmission == null) return;
    setState(() => _loading = true);
    final res = await ApiService.approveEnquiry(_selectedSubmission!['id']);
    if (res['success'] == true) {
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text('Enquiry Converted!', style: TextStyle(color: VianTheme.primaryGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The client and project records have been created successfully:'),
              const SizedBox(height: 12),
              Text('Project ID: ${res['project']['projectId']}', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              const SizedBox(height: 4),
              Text('Project Name: ${res['project']['name']}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              const Text('The following defaults have been seeded:\n- 1 Initial Site Visit\n- 8 Construction stages & payment milestones\n- 1 Standard construction estimate with material, labour & BOQ lines\n- 1 Initial Task list item'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchInbox();
              },
              child: const Text('OK', style: TextStyle(color: VianTheme.primaryGold)),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _loading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: ${res['message']}'))
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: VianTheme.primaryGold));
    }

    final filteredList = _submissions.where((s) => s['status'] == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121317),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANE 1: Channels (220px)
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.03))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'CHANNELS',
                    style: GoogleFonts.outfit(
                      color: VianTheme.primaryGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _channelTile(Icons.mail_outline, 'Direct Email', _submissions.length.toString(), true),
                _channelTile(Icons.chat_bubble_outline, 'WhatsApp', '4', false),
                _channelTile(Icons.language, 'Web Form', '0', false),
                _channelTile(Icons.hub_outlined, 'ArchDaily', '1', false),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'STATUS',
                    style: GoogleFonts.outfit(
                      color: VianTheme.lightText,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...['New', 'In Review', 'Approved', 'Rejected', 'Converted'].map((status) {
                  final active = _selectedStatus == status;
                  final count = _submissions.where((s) => s['status'] == status).length;
                  return InkWell(
                    onTap: () => setState(() => _selectedStatus = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      color: active ? Colors.white.withOpacity(0.02) : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active ? VianTheme.primaryGold : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            status,
                            style: GoogleFonts.inter(
                              color: active ? Colors.white : VianTheme.lightText,
                              fontSize: 13,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            count.toString(),
                            style: GoogleFonts.poppins(
                              color: active ? VianTheme.primaryGold : Colors.white24,
                              fontSize: 11,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // PANE 2: Conversations List (360px)
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0E12),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONVERSATIONS',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${filteredList.length} Items',
                        style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Text(
                            'No enquiries found.',
                            style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredList.length,
                          separatorBuilder: (context, idx) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, idx) {
                            final sub = filteredList[idx];
                            final isSel = _selectedSubmission != null && _selectedSubmission!['id'] == sub['id'];

                            return InkWell(
                              onTap: () => setState(() => _selectedSubmission = sub),
                              child: Container(
                                color: isSel ? Colors.white.withOpacity(0.02) : Colors.transparent,
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          sub['clientName'] ?? 'Unknown Client',
                                          style: GoogleFonts.inter(
                                            color: isSel ? VianTheme.primaryGold : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        Text(
                                          sub['date'] ?? '',
                                          style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sub['buildingType'] ?? 'Residential',
                                      style: GoogleFonts.outfit(
                                        color: VianTheme.lightText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      sub['clientRequirements'] ?? sub['notes'] ?? 'No requirements specified.',
                                      style: GoogleFonts.inter(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // PANE 3: Conversation View (Fluid)
          Expanded(
            child: _selectedSubmission == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, size: 48, color: Colors.white12),
                        const SizedBox(height: 16),
                        Text(
                          'SELECT AN ENQUIRY TO REVIEW DETAILS',
                          style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: const Color(0xFF121317),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: VianTheme.primaryGold.withOpacity(0.1),
                                child: Text(
                                  ((_selectedSubmission!['clientName']?.toString() ?? '').isNotEmpty) ? _selectedSubmission!['clientName'].toString().substring(0, 1).toUpperCase() : 'C',
                                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedSubmission!['clientName'] ?? '',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedSubmission!['email'] ?? "No Email"} • ${_selectedSubmission!['contactNumber'] ?? "No Phone"}',
                                      style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              if (_selectedSubmission!['status'] != 'Converted') ...[
                                if (_selectedSubmission!['status'] == 'New') ...[
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: VianTheme.primaryGold,
                                      side: const BorderSide(color: VianTheme.primaryGold),
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    ),
                                    onPressed: () => _updateStatus('In Review'),
                                    child: const Text('MARK IN REVIEW'),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                if (_selectedSubmission!['status'] != 'Approved') ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: VianTheme.primaryGold,
                                      foregroundColor: Colors.black,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    ),
                                    onPressed: _approveAndConvert,
                                    child: const Text('APPROVE & CONVERT'),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),

                        // Detail view and note list
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quote Block
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: VianTheme.primaryGold, width: 2)),
                                  ),
                                  padding: const EdgeInsets.only(left: 20.0, top: 4, bottom: 4),
                                  child: Text(
                                    '"${_selectedSubmission!['clientRequirements'] ?? _selectedSubmission!['notes'] ?? "No initial description provided."}"',
                                    style: GoogleFonts.bodoniModa(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Structured Info tables
                                _buildDetailGroup('Client & Location', {
                                  'Client Name': _selectedSubmission!['clientName'],
                                  'Phone': _selectedSubmission!['contactNumber'],
                                  'Email': _selectedSubmission!['email'] ?? 'N/A',
                                  'Site Address': _selectedSubmission!['siteAddress'],
                                  'Taluk': _selectedSubmission!['taluk'] ?? 'N/A',
                                  'Road Width': '${_selectedSubmission!['roadWidth'] ?? "N/A"} Feet',
                                  'Site facing': _selectedSubmission!['siteFacing'] ?? 'N/A',
                                }),

                                _buildDetailGroup('Structural Configuration', {
                                  'Building Type': _selectedSubmission!['buildingType'],
                                  'Local Authority': _selectedSubmission!['localAuthority'] ?? 'N/A',
                                  'Soil Condition': _selectedSubmission!['siteCondition'] ?? 'N/A',
                                  'EB Connection': _selectedSubmission!['electricity'] ?? 'N/A',
                                }),
                                const SizedBox(height: 24),

                                // Attachments
                                Text(
                                  'ATTACHMENTS',
                                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 12),
                                _buildAttachmentsList(),
                                const SizedBox(height: 32),

                                // Internal notes
                                Text(
                                  'INTERNAL REVIEW NOTES',
                                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 16),
                                _buildNotesThread(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _noteCtrl,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Enter review comment...',
                                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                          filled: true,
                                          fillColor: const Color(0xFF1C1D21),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.zero,
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.zero,
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.zero,
                                            borderSide: BorderSide(color: VianTheme.primaryGold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.send, color: VianTheme.primaryGold),
                                      onPressed: _addNote,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),

                        // Compose / Reply Area
                        Container(
                          color: VianTheme.cardColor,
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF13131A),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: const TextField(
                                    style: TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Write a response correspondence to client...',
                                      hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VianTheme.primaryGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Correspondence sent successfully!'), backgroundColor: VianTheme.success),
                                  );
                                },
                                child: Text('SEND', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _channelTile(IconData icon, String title, String count, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: active ? Colors.white.withOpacity(0.02) : Colors.transparent,
      child: Row(
        children: [
          Icon(icon, color: active ? VianTheme.primaryGold : VianTheme.lightText, size: 18),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: active ? Colors.white : VianTheme.lightText,
              fontSize: 13.5,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (count != '0')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: active ? VianTheme.primaryGold.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              child: Text(
                count,
                style: GoogleFonts.poppins(color: active ? VianTheme.primaryGold : VianTheme.lightText, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailGroup(String title, Map<String, String?> details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.primaryGold)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: const Color(0xFF262630), width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
            },
            children: details.entries.map((e) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(e.key, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(e.value ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList() {
    final docs = _selectedSubmission!['documents'] as List<dynamic>? ?? [];
    if (docs.isEmpty) return const Text('No documents uploaded.');
    return Column(
      children: docs.map((doc) {
        return Card(
          color: const Color(0xFF1E1E26),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file, color: VianTheme.primaryGold),
            title: Text(doc['fileName']),
            subtitle: Text('Category: ${doc['fileType']} | Size: ${(doc['fileSize'] / 1024).toStringAsFixed(1)} KB'),
            trailing: const Icon(Icons.arrow_downward, color: VianTheme.primaryGold),
            onTap: () => openUrl(doc['fileUrl']),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesThread() {
    final notes = _selectedSubmission!['submissionNotes'] as List<dynamic>? ?? [];
    if (notes.isEmpty) return const Text('No review notes recorded.');
    return Column(
      children: notes.map((n) {
        return Card(
          color: const Color(0xFF1E1E26),
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: VianTheme.primaryGold,
                  radius: 16,
                  child: Text(n['author'][0].toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['author'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(n['noteText'], style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
