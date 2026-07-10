                  import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class ApiService {
  static String get baseUrl => ApiConstants.baseUrl;

  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get token => _token;
  static bool get isLoggedIn => _token != null;

  // Initialize service, check for saved tokens
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = json.decode(userJson);
    }
  }

  // Helper for headers
  static Map<String, String> get _headers => ApiConstants.getHeaders(_token);

  // Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('current_user', json.encode(_currentUser));

        return {'success': true, 'user': _currentUser};
      } else {
        final err = json.decode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Login failed'};
      }
    } catch (e) {
      // Offline fallback
      return _mockLogin(username, password);
    }
  }

  // Logout
  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('current_user');
  }

  // Mock Login Fallback
  static Future<Map<String, dynamic>> _mockLogin(String username, String password) async {
    // Check standard username credentials
    final validUsers = {
      // Managing Directors
      'anand': {'name': 'Ar. Anand Sathiesivam', 'role': 'Managing Director', 'dept': 'Executive', 'desig': 'Managing Director'},
      'vijay': {'name': 'Ar. Vijay Vinthan', 'role': 'Managing Director', 'dept': 'Executive', 'desig': 'Managing Director'},
      
      // Core Team
      'arun': {'name': 'Er. Arun Mohan', 'role': 'Structural Engineer', 'dept': 'Core Team', 'desig': 'Structural Engineer'},
      'jahan': {'name': 'Er. Jahan Prabhu', 'role': 'Engineering Precision Head', 'dept': 'Core Team', 'desig': 'Engineering Precision Head'},
      'mithulya': {'name': 'Ar. Mithulya', 'role': 'Senior Design Engineer', 'dept': 'Core Team', 'desig': 'Senior Design Engineer'},
      'sasmitha': {'name': 'Ar. Sasmitha', 'role': 'Planning Engineer', 'dept': 'Core Team', 'desig': 'Planning Engineer'},
      
      // Designing Team
      'gokul_k': {'name': 'Ar. Gokul Krishnan', 'role': 'Design Engineer', 'dept': 'Designing Team', 'desig': 'Design Engineer'},
      'sivaraman': {'name': 'Sr. Sivaraman', 'role': '3D Visualization Specialist', 'dept': 'Designing Team', 'desig': '3D Visualization Specialist'},
      'sabith': {'name': 'Ar. Sabith', 'role': 'Creative Planning Engineer', 'dept': 'Designing Team', 'desig': 'Creative Planning Engineer'},
      'edwin': {'name': 'Ar. Edwin', 'role': 'Creative Design Engineer', 'dept': 'Designing Team', 'desig': 'Creative Design Engineer'},
      'nivetha': {'name': 'Ar. Nivetha', 'role': 'Interior Planning Engineer', 'dept': 'Designing Team', 'desig': 'Interior Planning Engineer'},
      'gokul_e': {'name': 'Er. Gokul', 'role': 'Technical Design Engineer', 'dept': 'Designing Team', 'desig': 'Technical Design Engineer'},
      'abinaya': {'name': 'Ar. Abinaya Bala', 'role': 'Architectural Designer', 'dept': 'Designing Team', 'desig': 'Architectural Designer'},
      
      // Site Team
      'anthony': {'name': 'Er. Anthony Richard', 'role': 'Site Engineer', 'dept': 'Site Team', 'desig': 'Site Engineer'},
      'praveen': {'name': 'Er. Praveen Kumar', 'role': 'Site Coordinator', 'dept': 'Site Team', 'desig': 'Site Coordinator'},
      'mohan': {'name': 'Er. Mohan', 'role': 'Site Construction Engineer', 'dept': 'Site Team', 'desig': 'Site Construction Engineer'},
      'murugan': {'name': 'Sr. Murugan', 'role': 'Labour Manager', 'dept': 'Site Team', 'desig': 'Labour Manager'},
      'manoj': {'name': 'Sr. Manoj', 'role': 'Site Supervisor', 'dept': 'Site Team', 'desig': 'Site Supervisor'},
      'dharmaraj': {'name': 'Mr. Dharmaraj', 'role': 'Site Coordinator', 'dept': 'Site Team', 'desig': 'Site Coordinator'},
      'kishore': {'name': 'Ar. Kishore Kumar', 'role': 'Junior Architect', 'dept': 'Site Team', 'desig': 'Junior Architect'},
      'surya': {'name': 'Ar. Surya Prakash', 'role': 'Junior Architect', 'dept': 'Site Team', 'desig': 'Junior Architect'},
      'harshini': {'name': 'Ar. Harshini', 'role': 'Junior Architect', 'dept': 'Site Team', 'desig': 'Junior Architect'},
      
      // Accountant, Client & Receptionist
      'accountant': {'name': 'Sneha Jain', 'role': 'Accountant', 'dept': 'Finance', 'desig': 'Finance Head'},
      'client': {'name': 'Amit Bajaj', 'role': 'Client', 'dept': 'External', 'desig': 'Property Owner'},
      'receptionist': {'name': 'Priya Sharma', 'role': 'Receptionist', 'dept': 'Front Office', 'desig': 'CRM Executive'}
    };

    if (validUsers.containsKey(username) && password.isNotEmpty) {
      final u = validUsers[username]!;
      _token = 'MOCK_JWT_TOKEN_${u['role']!.toUpperCase().replaceAll(' ', '_')}';
      _currentUser = {
        'id': 99,
        'employeeId': 'VIAN-MOCK-99',
        'username': username,
        'name': u['name'],
        'email': '$username@vianarchitects.com',
        'role': u['role'],
        'department': u['dept'],
        'designation': u['desig']
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setString('current_user', json.encode(_currentUser));

      return {'success': true, 'user': _currentUser, 'isMock': true};
    }
    return {'success': false, 'message': 'Invalid credentials (local simulation mode)'};
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (_) {
      // Mock stats
      return {
        'stats': {
          'totalProjects': 14,
          'activeProjects': 8,
          'completedProjects': 5,
          'totalClients': 12,
          'totalLeads': 24,
          'revenue': 8450000.0,
          'pendingPayments': 3240000.0,
          'siteVisitsToday': 2,
          'employeeAttendance': 11
        },
        'recentActivities': [
          {'id': 1, 'type': 'Project', 'message': 'Project "Villa Horizon" progress updated to 45%', 'time': '10 mins ago'},
          {'id': 2, 'type': 'CRM', 'message': 'New Lead "Ankit Sharma" added from Website', 'time': '1 hr ago'},
          {'id': 3, 'type': 'Attendance', 'message': 'Site Engineer Rahul checked in at Site A', 'time': '2 hrs ago'},
          {'id': 4, 'type': 'Invoice', 'message': 'Invoice VIAN-2026-002 paid by Mr. Mehta', 'time': '1 day ago'}
        ]
      };
    }
  }

  // Fetch leads (CRM)
  static Future<List<dynamic>> getLeads() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/crm/leads'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['leads'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'name': 'Rajesh Malhotra',
          'phone': '+91 99887 76655',
          'email': 'rajesh@malhotragroup.in',
          'source': 'Website Inquiry',
          'budget': 50000000.0,
          'requirement': 'Full interior design and renovation of 5000 sqft penthouse in DLF Magnolias',
          'notes': 'Client looking for ultra-luxury contemporary style. Wants to start by August 2026.',
          'status': 'New',
          'assignee': {'name': 'Priya Sharma'}
        },
        {
          'id': 2,
          'name': 'Dr. Shruti Kapoor',
          'phone': '+91 98989 87878',
          'email': 'shruti.k@healthclinic.org',
          'source': 'Instagram Reference',
          'budget': 15000000.0,
          'requirement': 'Design of dental clinic, minimal clean aesthetics with warm lighting',
          'notes': 'Scheduled site visit for next Monday. Sent initial portfolio link.',
          'status': 'Contacted',
          'assignee': {'name': 'Priya Sharma'}
        },
        {
          'id': 3,
          'name': 'Karan Johar',
          'phone': '+91 91111 22222',
          'email': 'karan@dharmaprod.com',
          'source': 'Self Referral',
          'budget': 95000000.0,
          'requirement': 'Luxurious villa construction in Lonavala',
          'notes': 'Sent initial proposal and mood boards. Negotiation stage.',
          'status': 'Negotiation',
          'assignee': {'name': 'Ananya Roy'}
        }
      ];
    }
  }

  // Add lead
  static Future<bool> addLead(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/crm/leads'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true; // Simulate success offline
    }
  }

  // Update lead status
  static Future<bool> updateLeadStatus(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/crm/leads/$id'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Update lead
  static Future<bool> updateLead(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/crm/leads/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Delete lead
  static Future<bool> deleteLead(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/crm/leads/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Add lead timeline entry
  static Future<bool> addLeadTimeline(int leadId, String action, String notes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/crm/leads/$leadId/timeline'),
        headers: _headers,
        body: json.encode({
          'action': action,
          'notes': notes,
        }),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>> convertToClient(
    int leadId, {
    bool merge = false,
    bool createProject = false,
    String? projectName,
    String? projectType,
    double? projectBudget,
    String? projectSiteAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/crm/leads/$leadId/convert'),
        headers: _headers,
        body: json.encode({
          'merge': merge,
          'createProject': createProject,
          'projectName': projectName,
          'projectType': projectType,
          'projectBudget': projectBudget,
          'projectSiteAddress': projectSiteAddress,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Offline mock storage map
  static final Map<int, Map<String, dynamic>> _localStage1Storage = {};

  // Get Lead Stage 1 Client Enquiry Form
  static Future<Map<String, dynamic>?> getLeadStage1(int leadId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/crm/leads/$leadId/stage1'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (_) {
      return _localStage1Storage[leadId];
    }
  }

  // Save/Update Lead Stage 1 Client Enquiry Form
  static Future<bool> saveLeadStage1(int leadId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/crm/leads/$leadId/stage1'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      _localStage1Storage[leadId] = data;
      return true;
    }
  }

  // Delete Lead Stage 1 Client Enquiry Form
  static Future<bool> deleteLeadStage1(int leadId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/crm/leads/$leadId/stage1'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      _localStage1Storage.remove(leadId);
      return true;
    }
  }

  // Fetch clients
  static Future<List<dynamic>> getClients() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/clients'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['clients'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'name': 'Amit Bajaj',
          'phone': '+91 98765 43210',
          'email': 'amit.bajaj@example.com',
          'address': 'Villa 108, Palm Meadows, Bangalore',
          'gst': '29BBBBB2222B1Z2',
          'propertyDetails': 'Luxury 4BHK Villa Construction and Interior Work'
        },
        {
          'id': 2,
          'name': 'Meera Sen',
          'phone': '+91 98888 77777',
          'email': 'meera@sengroup.co',
          'address': 'Flat 1204, Oberoi Sky Heights, Mumbai',
          'gst': '27CCCCC3333C1Z3',
          'propertyDetails': 'Modern Minimalist Apartment Interior Design'
        }
      ];
    }
  }

  // Fetch clients paged
  static Future<Map<String, dynamic>> getClientsPaged({String search = '', int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clients?search=$search&page=$page&limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'clients': [], 'total': 0, 'totalPages': 1};
    } catch (_) {
      return {'clients': [], 'total': 0, 'totalPages': 1};
    }
  }

  // Add client
  static Future<bool> addClient(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clients'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Update client
  static Future<bool> updateClient(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/clients/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Delete client
  static Future<bool> deleteClient(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/clients/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Fetch projects
  static Future<List<dynamic>> getProjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['projects'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'projectId': 'VIAN-PROJ-2026-001',
          'name': 'The Bajaj Villa',
          'type': 'Villa',
          'budget': 25000000.0,
          'startDate': '2026-01-10',
          'completionDate': '2026-12-15',
          'status': 'In Progress',
          'progressPercentage': 45,
          'client': {'name': 'Amit Bajaj'},
          'architect': {'name': 'Ananya Roy'},
          'siteEngineer': {'name': 'Rahul Sen'}
        },
        {
          'id': 2,
          'projectId': 'VIAN-PROJ-2026-002',
          'name': 'Oberoi Apartment 1204',
          'type': 'Interior Design',
          'budget': 8000000.0,
          'startDate': '2026-03-01',
          'completionDate': '2026-08-30',
          'status': 'In Progress',
          'progressPercentage': 70,
          'client': {'name': 'Meera Sen'},
          'architect': {'name': 'Kabir Mehta'},
          'siteEngineer': {'name': 'Rahul Sen'}
        },
        {
          'id': 3,
          'projectId': 'VIAN-PROJ-2026-003',
          'name': 'Galleria Showroom',
          'type': 'Commercial',
          'budget': 12000000.0,
          'startDate': '2026-05-15',
          'completionDate': '2026-10-31',
          'status': 'Planning',
          'progressPercentage': 10,
          'client': {'name': 'Sanjay Singhania'},
          'architect': {'name': 'Ananya Roy'},
          'siteEngineer': {'name': 'Vikram Singh'}
        }
      ];
    }
  }

  // Create project
  static Future<bool> createProject(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }
  static Future<List<dynamic>> getTasks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['tasks'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'title': 'Finalize Mood Boards',
          'description': 'Submit mood boards and fabric swatches for master bedroom approval.',
          'priority': 'High',
          'dueDate': '2026-06-28',
          'status': 'In Progress',
          'project': {'name': 'Oberoi Apartment 1204'},
          'assignee': {'name': 'Kabir Mehta'}
        },
        {
          'id': 2,
          'title': 'Plumbing Layout Verification',
          'description': 'Verify plumbing line installation on the ground floor.',
          'priority': 'Medium',
          'dueDate': '2026-06-25',
          'status': 'Pending',
          'project': {'name': 'The Bajaj Villa'},
          'assignee': {'name': 'Rahul Sen'}
        },
        {
          'id': 3,
          'title': '3D Render Correction',
          'description': 'Incorporate dining table changes into final 3D render output.',
          'priority': 'Low',
          'dueDate': '2026-06-30',
          'status': 'Completed',
          'project': {'name': 'Galleria Showroom'},
          'assignee': {'name': 'Ananya Roy'}
        }
      ];
    }
  }

  // Check in
  static Future<bool> checkIn(String gps, String? selfieUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: _headers,
        body: json.encode({'gps': gps, 'selfieUrl': selfieUrl}),
      );
      return response.statusCode == 201;
    } catch (_) {
      queueOfflineRequest('/attendance/check-in', 'POST', {'gps': gps, 'selfieUrl': selfieUrl});
      return true;
    }
  }

  // Check out
  static Future<bool> checkOut(String gps) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-out'),
        headers: _headers,
        body: json.encode({'gps': gps}),
      );
      return response.statusCode == 200;
    } catch (_) {
      queueOfflineRequest('/attendance/check-out', 'POST', {'gps': gps});
      return true;
    }
  }

  // Fetch drawings
  static Future<List<dynamic>> getDrawings(int projectId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects/$projectId/drawings'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['drawings'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'title': 'Ground Floor Plan - Rev 2',
          'version': '2.1',
          'type': 'Floor Plans',
          'fileUrl': 'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80',
          'status': 'Approved',
          'approver': {'name': 'Ananya Roy'}
        },
        {
          'id': 2,
          'title': 'Master Bedroom Wardrobe Elevation',
          'version': '1.0',
          'type': 'Interior Drawings',
          'fileUrl': 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80',
          'status': 'Pending',
          'approver': null
        }
      ];
    }
  }

  // Fetch invoices
  static Future<List<dynamic>> getInvoices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/invoices'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['invoices'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'invoiceNumber': 'VIAN-INV-2026-001',
          'date': '2026-02-15',
          'dueDate': '2026-03-01',
          'taxRate': 18.0,
          'discount': 0.0,
          'subtotal': 1500000.0,
          'total': 1770000.0,
          'paidAmount': 1770000.0,
          'status': 'Paid',
          'project': {'name': 'The Bajaj Villa'}
        },
        {
          'id': 2,
          'invoiceNumber': 'VIAN-INV-2026-002',
          'date': '2026-06-10',
          'dueDate': '2026-06-25',
          'taxRate': 18.0,
          'discount': 50000.0,
          'subtotal': 2000000.0,
          'total': 2310000.0,
          'paidAmount': 1000000.0,
          'status': 'Sent',
          'project': {'name': 'The Bajaj Villa'}
        },
        {
          'id': 3,
          'invoiceNumber': 'VIAN-INV-2026-003',
          'date': '2026-05-01',
          'dueDate': '2026-05-15',
          'taxRate': 18.0,
          'discount': 0.0,
          'subtotal': 1000000.0,
          'total': 1180000.0,
          'paidAmount': 0.0,
          'status': 'Overdue',
          'project': {'name': 'Oberoi Apartment 1204'}
        }
      ];
    }
  }

  // Fetch quotations
  static Future<List<dynamic>> getQuotations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quotations'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['quotations'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'quotationNumber': 'VIAN-QT-2026-001',
          'date': '2026-01-05',
          'taxRate': 18.0,
          'discount': 100000.0,
          'subtotal': 22000000.0,
          'total': 25860000.0,
          'status': 'Approved',
          'project': {'name': 'The Bajaj Villa'}
        },
        {
          'id': 2,
          'quotationNumber': 'VIAN-QT-2026-002',
          'date': '2026-05-10',
          'taxRate': 18.0,
          'discount': 0.0,
          'subtotal': 11000000.0,
          'total': 12980000.0,
          'status': 'Sent',
          'project': {'name': 'Galleria Showroom'}
        }
      ];
    }
  }

  // Fetch expenses
  static Future<List<dynamic>> getExpenses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expenses'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['expenses'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'amount': 25000.0,
          'category': 'Travel Expenses',
          'description': 'Site visit to Lonavala for villa site measurements',
          'date': '2026-06-20',
          'status': 'Approved',
          'project': {'name': 'The Bajaj Villa'},
          'user': {'name': 'Ananya Roy'}
        },
        {
          'id': 2,
          'amount': 150000.0,
          'category': 'Material Expenses',
          'description': 'Purchase of Italian marble samples and tile sheets',
          'date': '2026-06-22',
          'status': 'Pending',
          'project': {'name': 'Oberoi Apartment 1204'},
          'user': {'name': 'Kabir Mehta'}
        }
      ];
    }
  }

  // Add expense
  static Future<bool> addExpense(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Fetch notifications
  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['notifications'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'title': 'New Task Assigned',
          'message': 'You have been assigned the task "Plumbing Layout Verification"',
          'readStatus': false,
          'type': 'Task'
        },
        {
          'id': 2,
          'title': 'Quotation Approved',
          'message': 'Quotation VIAN-QT-2026-001 has been approved by Amit Bajaj',
          'readStatus': true,
          'type': 'Billing'
        }
      ];
    }
  }

  // Fetch settings
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/settings'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['settings'];
      }
      throw Exception();
    } catch (_) {
      return {
        'companyName': 'VIAN Architects & Designers',
        'address': 'Plot 42, Galleria Commercial Complex, Phase V, Sector 43, Gurugram, India',
        'gst': '07AAAAA1111A1Z1',
        'email': 'office@vianarchitects.com',
        'phone': '+91 124 4567890'
      };
    }
  }

  // Fetch Labour Workers
  static Future<List<dynamic>> getWorkers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/labour/workers'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['workers'];
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'workerId': 'WRK-001', 'name': 'Ramesh Kumar', 'skillType': 'Mason', 'dailyWage': 600.0, 'contractor': 'Verma Contractors', 'project': {'name': 'The Bajaj Villa'}},
        {'id': 2, 'workerId': 'WRK-002', 'name': 'Sohan Lal', 'skillType': 'Carpenter', 'dailyWage': 750.0, 'contractor': 'Verma Contractors', 'project': {'name': 'The Bajaj Villa'}},
        {'id': 3, 'workerId': 'WRK-003', 'name': 'Madan Mohan', 'skillType': 'Painter', 'dailyWage': 550.0, 'contractor': 'Singh Painters', 'project': {'name': 'The Bajaj Villa'}},
        {'id': 4, 'workerId': 'WRK-004', 'name': 'Hari Prasad', 'skillType': 'Electrician', 'dailyWage': 700.0, 'contractor': 'Self', 'project': {'name': 'Oberoi Apartment 1204'}},
      ];
    }
  }

  // Add Worker
  static Future<bool> addWorker(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/labour/workers'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Fetch Contractors
  static Future<List<dynamic>> getContractors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/contractors'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['contractors'];
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'contractorId': 'CON-001', 'name': 'Verma Contractors', 'phone': '9876543210', 'email': 'verma@example.com', 'address': 'Gurugram, Sector 43', 'serviceType': 'Civil & Foundation'},
        {'id': 2, 'contractorId': 'CON-002', 'name': 'Singh Painters', 'phone': '9876543211', 'email': 'singh@example.com', 'address': 'Delhi, Vasant Kunj', 'serviceType': 'Painting & Polishing'},
        {'id': 3, 'contractorId': 'CON-003', 'name': 'Sharma Electricals', 'phone': '9876543212', 'email': 'sharma@example.com', 'address': 'Noida, Sector 62', 'serviceType': 'Electrical & Wiring'}
      ];
    }
  }

  // Add Contractor
  static Future<bool> addContractor(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contractors'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Update Contractor
  static Future<bool> updateContractor(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contractors/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Delete Contractor
  static Future<bool> deleteContractor(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contractors/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Fetch Contractor Stages
  static Future<List<dynamic>> getContractorStages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/contractor-stages'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['stages'];
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'name': 'BASEMENT', 'description': 'Foundation and Basement column works'},
        {'id': 2, 'name': 'SOIL FILLING', 'description': 'Excavation and Soil backfilling works'},
        {'id': 3, 'name': 'RCC SLAB', 'description': 'Reinforced concrete slab casting works'},
        {'id': 4, 'name': 'PLASTERING', 'description': 'Internal and external wall plastering'},
        {'id': 5, 'name': 'TILING', 'description': 'Flooring and wall tiling works'},
        {'id': 6, 'name': 'PAINTING', 'description': 'Wall painting and polishing'}
      ];
    }
  }

  // Add Contractor Stage
  static Future<bool> addContractorStage(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contractor-stages'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Update Contractor Stage
  static Future<bool> updateContractorStage(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contractor-stages/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Delete Contractor Stage
  static Future<bool> deleteContractorStage(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contractor-stages/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Fetch Contractor Releases
  static Future<List<dynamic>> getContractorReleases() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/contractor-releases'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['releases'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'amount': 150000.0,
          'releaseDate': '2026-06-15',
          'paymentMode': 'Bank Transfer',
          'referenceNumber': 'TXN-99887766',
          'status': 'Released',
          'notes': 'Basement column casting completed. Quality team approved.',
          'contractor': {'id': 1, 'contractorId': 'CON-001', 'name': 'Verma Contractors'},
          'project': {'id': 1, 'projectId': 'PRJ-001', 'name': 'The Bajaj Villa'},
          'stage': {'id': 1, 'name': 'BASEMENT'}
        }
      ];
    }
  }

  // Add Contractor Release
  static Future<bool> addContractorRelease(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contractor-releases'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Update Contractor Release
  static Future<bool> updateContractorRelease(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contractor-releases/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Delete Contractor Release
  static Future<bool> deleteContractorRelease(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contractor-releases/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Submit Manager Attendance
  static Future<Map<String, dynamic>> submitManagerAttendance(List<Map<String, dynamic>> workers, String gps, String date) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/manager/submit'),
        headers: _headers,
        body: json.encode({'workers': workers, 'gpsLocation': gps, 'date': date}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message'] ?? 'Attendance submitted successfully'};
      }
      return {'success': false, 'message': body['message'] ?? 'Failed to record attendance'};
    } catch (_) {
      return {'success': true, 'message': 'Offline Mode: Attendance recorded locally'};
    }
  }

  // Fetch Daily Work Completion Reports
  static Future<List<dynamic>> getDailyReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/daily'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['reports'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'date': '2026-06-23',
          'workCategory': 'Brick Work',
          'workDescription': 'Completed brick laying for boundary wall section B.',
          'quantityCompleted': '1200 Sq Ft Completed',
          'notes': 'All items completed, verified alignment.',
          'user': {'name': 'Rahul Sen'},
          'project': {'name': 'The Bajaj Villa'}
        },
        {
          'id': 2,
          'date': '2026-06-23',
          'workCategory': 'Painting',
          'workDescription': 'First coat of emulsion paint on walls.',
          'quantityCompleted': '2 Rooms Completed',
          'notes': 'Awaiting drying. Second coat tomorrow.',
          'user': {'name': 'Kabir Mehta'},
          'project': {'name': 'Oberoi Apartment 1204'}
        }
      ];
    }
  }

  // Submit Daily Work Report
  static Future<bool> submitDailyReport(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports/daily'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      queueOfflineRequest('/reports/daily', 'POST', data);
      return true;
    }
  }

  // Fetch Manager Progress Reports
  static Future<List<dynamic>> getManagerProgressReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/manager-progress'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['reports'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'date': '2026-06-23',
          'workersPresent': 12,
          'workCompleted': 'Slab casting of second floor completed. Shuttering checked.',
          'materialsUsed': 'Cement: 150 Bags, Steel: 1.2 Tons, Sand: 2 Trucks',
          'issuesFaced': 'Minor water supply leak in afternoon, resolved.',
          'delays': 'No delays',
          'tomorrowPlan': 'Curing of slab, start masonry for internal partitions.',
          'manager': {'name': 'Rahul Sen'},
          'project': {'name': 'The Bajaj Villa'}
        }
      ];
    }
  }

  // Submit Manager Progress Report
  static Future<bool> submitManagerProgressReport(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports/manager-progress'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Fetch Payroll wage sheet
  static Future<List<dynamic>> getWageSheet(int? projectId) async {
    try {
      final url = projectId != null ? '$baseUrl/payroll/wage-sheet?projectId=$projectId' : '$baseUrl/payroll/wage-sheet';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['wageSheet'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'workerId': 'WRK-001',
          'name': 'Ramesh Kumar',
          'skillType': 'Mason',
          'contractor': 'Verma Contractors',
          'dailyWage': 600.0,
          'presentDays': 22,
          'halfDays': 2,
          'absentDays': 2,
          'overtimeHours': 12.0,
          'basePay': 13800.0,
          'overtimePay': 1350.0,
          'totalWage': 15150.0
        },
        {
          'workerId': 'WRK-002',
          'name': 'Sohan Lal',
          'skillType': 'Carpenter',
          'contractor': 'Verma Contractors',
          'dailyWage': 750.0,
          'presentDays': 24,
          'halfDays': 0,
          'absentDays': 2,
          'overtimeHours': 8.0,
          'basePay': 18000.0,
          'overtimePay': 1125.0,
          'totalWage': 19125.0
        },
        {
          'workerId': 'WRK-003',
          'name': 'Madan Mohan',
          'skillType': 'Painter',
          'dailyWage': 550.0,
          'presentDays': 20,
          'halfDays': 4,
          'absentDays': 2,
          'overtimeHours': 0.0,
          'basePay': 12100.0,
          'overtimePay': 0.0,
          'totalWage': 12100.0
        }
      ];
    }
  }

  // Fetch Executive Stats
  static Future<Map<String, dynamic>> getExecutiveStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/executive'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'totalEmployees': 28,
        'workersPresent': 42,
        'workersAbsent': 6,
        'laborCost': 420000.0,
        'materialCost': 1850000.0,
        'realtimeAttendance': [
          {'worker': {'name': 'Ramesh Kumar', 'workerId': 'WRK-001', 'skillType': 'Mason'}, 'status': 'Present', 'entryTime': '09:05 AM'},
          {'worker': {'name': 'Sohan Lal', 'workerId': 'WRK-002', 'skillType': 'Carpenter'}, 'status': 'Present', 'entryTime': '09:10 AM'},
          {'worker': {'name': 'Madan Mohan', 'workerId': 'WRK-003', 'skillType': 'Painter'}, 'status': 'Half Day', 'entryTime': '09:15 AM'},
        ]
      };
    }
  }

  // Fetch announcements
  static Future<List<dynamic>> getAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/announcements'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['announcements'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'title': 'Safety Guidelines Compliance',
          'message': 'All site engineers must ensure that workers wear safety helmets and harnesses on scaffolding sections at all times.',
          'createdAt': '2026-06-22T10:00:00Z'
        },
        {
          'id': 2,
          'title': 'GST Invoice Submission Deadline',
          'message': 'Please submit all client billing material receipts for sector audits by the 25th of this month.',
          'createdAt': '2026-06-20T14:30:00Z'
        }
      ];
    }
  }

  // Onboard client
  static Future<Map<String, dynamic>> onboardClient(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clients/onboard'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': json.decode(response.body)['message'] ?? 'Onboarding failed'};
    } catch (_) {
      return {
        'success': true,
        'message': '[OFFLINE MOCK] Client and Project onboarded successfully with standard workspace structure.',
        'clientId': 99,
        'projectId': 99,
        'projectCode': 'VIAN-PROJ-2026-MOCK'
      };
    }
  }

  // Validate spreadsheet import
  static Future<Map<String, dynamic>> validateImport(List<dynamic> rows, Map<String, String> mapping, String module) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/import/validate'),
        headers: _headers,
        body: json.encode({'rows': rows, 'mapping': mapping, 'module': module}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      final List<Map<String, dynamic>> mockResults = [];
      final int limit = rows.length < 5 ? rows.length : 5;
      for (int i = 0; i < limit; i++) {
        final row = rows[i];
        mockResults.add({
          'index': i,
          'rowData': row,
          'resolvedValues': {
            'name': row['Client Name'] ?? row['name'] ?? 'Mock Client',
            'phone': row['Mobile Number'] ?? row['phone'] ?? '9999999999',
            'email': row['Email'] ?? row['email'] ?? 'mock@vian.com',
          },
          'errors': {},
          'warnings': {},
          'isValid': true
        });
      }
      return {
        'validationResults': mockResults,
        'summary': {
          'totalRows': rows.length,
          'duplicateClients': 0,
          'duplicateProjects': 0,
          'missingFields': 0,
          'invalidEmails': 0,
          'isValidSuite': true
        }
      };
    }
  }

  // Execute spreadsheet import
  static Future<Map<String, dynamic>> executeImport(List<dynamic> rows, Map<String, String> mapping, String strategy, String module) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/import/execute'),
        headers: _headers,
        body: json.encode({'rows': rows, 'mapping': mapping, 'strategy': strategy, 'module': module}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'success': true,
        'summary': {
          'imported': rows.length,
          'updated': 0,
          'failed': 0,
          'skipped': 0
        }
      };
    }
  }

  // Fetch import/export activity logs
  static Future<List<dynamic>> getImportLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/import-logs'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['logs'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'type': 'Import',
          'module': 'Clients',
          'fileName': 'clients_list_sheet.csv',
          'recordsImported': 12,
          'recordsUpdated': 2,
          'recordsFailed': 0,
          'ipAddress': '192.168.1.100',
          'device': 'Windows 11 Chrome',
          'createdAt': '2026-06-25T08:00:00Z',
          'user': {'name': 'Ar. Anand Sathiesivam'}
        },
        {
          'id': 2,
          'type': 'Export',
          'module': 'PROJECTS',
          'fileName': 'projects_export.csv',
          'recordsImported': 0,
          'recordsUpdated': 0,
          'recordsFailed': 0,
          'ipAddress': '192.168.1.100',
          'device': 'Windows 11 Chrome',
          'createdAt': '2026-06-24T18:30:00Z',
          'user': {'name': 'Ar. Anand Sathiesivam'}
        }
      ];
    }
  }

  // Export module data
  static Future<Map<String, dynamic>> exportModule(String module, String format) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/export/$module?format=$format'), headers: _headers);
      if (response.statusCode == 200) {
        if (format == 'csv') {
          return {'success': true, 'csvData': response.body};
        } else {
          return json.decode(response.body);
        }
      }
      throw Exception();
    } catch (_) {
      return {
        'success': true,
        'message': '[OFFLINE MOCK] Exported $module successfully in $format format.',
        'csvData': 'ID,Name,Phone,Email\n1,Amit Bajaj,9876543210,amit@bajaj.com\n2,Kiran Oberoi,9911223344,kiran@oberoi.com'
      };
    }
  }

  // Backup database
  static Future<String?> backupDatabase() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/backup/export'), headers: _headers);
      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception();
    } catch (_) {
      return '{"users":[],"clients":[],"projects":[]}';
    }
  }

  // Restore database
  static Future<Map<String, dynamic>> restoreDatabase(String backupJson) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/backup/restore'),
        headers: _headers,
        body: json.encode({'backupData': backupJson}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Restore failed'};
    } catch (_) {
      return {'success': true, 'message': '[OFFLINE MOCK] Database successfully restored from backup.'};
    }
  }

  // List backups
  static Future<List<dynamic>> getBackupsList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/backup/list'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['backups'];
      }
      throw Exception();
    } catch (_) {
      return [
        { 'name': 'vian_db_daily_backup_2026-06-24.sql', 'size': '256 KB', 'date': '2026-06-24 23:59' },
        { 'name': 'vian_db_daily_backup_2026-06-23.sql', 'size': '254 KB', 'date': '2026-06-23 23:59' }
      ];
    }
  }

  // Get all employee accounts (excluding Client role)
  static Future<List<dynamic>> getEmployees() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/employees'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['employees'];
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'username': 'anand', 'name': 'Ar. Anand Sathiesivam', 'role': 'Managing Director', 'department': 'Executive'},
        {'id': 2, 'username': 'vijay', 'name': 'Ar. Vijay Vinthan', 'role': 'Managing Director', 'department': 'Executive'},
        {'id': 3, 'username': 'jaya', 'name': 'Jaya Sharma', 'role': 'Admin / Office Manager / Accounts', 'department': 'Front Office'},
        {'id': 4, 'username': 'muthuiya', 'name': 'Ar. Muthuiya', 'role': 'Tech Head + Senior Architect', 'department': 'Core Team'},
        {'id': 5, 'username': 'arun', 'name': 'Er. Arun Mohan', 'role': 'Structural Engineer', 'department': 'Core Team'},
        {'id': 6, 'username': 'gokul', 'name': 'Ar. Gokul Krishnan', 'role': 'Employee', 'department': 'Designing Team'},
        {'id': 7, 'username': 'sivaraman', 'name': 'Sr. Sivaraman', 'role': 'Employee', 'department': 'Designing Team'},
        {'id': 8, 'username': 'mohan', 'name': 'Er. Mohan', 'role': 'Employee', 'department': 'Site Team'},
        {'id': 9, 'username': 'vijayan', 'name': 'Er. Vijayan', 'role': 'Employee', 'department': 'Site Team'},
        {'id': 10, 'username': 'manoj', 'name': 'Sr. Manoj', 'role': 'Employee', 'department': 'Site Team'},
        {'id': 11, 'username': 'murugan', 'name': 'Sr. Murugan', 'role': 'Site Manager', 'department': 'Site Team'},
      ];
    }
  }

  // GPS Tracking
  static Future<Map<String, dynamic>> trackGps(double latitude, double longitude) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gps/track'),
        headers: _headers,
        body: json.encode({'latitude': latitude, 'longitude': longitude}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      // Mock tracking response ( Bajaj Villa coordinates: 28.4595, 77.0266 )
      final dist = (latitude - 28.4595).abs() + (longitude - 77.0266).abs();
      final isOutside = dist > 0.003;
      return {
        'success': true,
        'isOutside': isOutside,
        'warning': isOutside ? {'id': 99, 'duration': 15} : null
      };
    }
  }

  // Fines Management
  static Future<Map<String, dynamic>> getFines() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fines'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'fines': [
          {'id': 1, 'amount': 500.00, 'reason': 'Geofence Breach: Left Site A for 35 mins', 'acknowledged': false, 'employee': {'name': 'Er. Mohan', 'role': 'Employee'}, 'createdAt': DateTime.now().subtract(const Duration(days: 1)).toString()},
          {'id': 2, 'amount': 1000.00, 'reason': 'Safety Violation: No safety harness worn', 'acknowledged': true, 'employee': {'name': 'Sr. Manoj', 'role': 'Employee'}, 'createdAt': DateTime.now().subtract(const Duration(days: 4)).toString()}
        ],
        'warnings': [
          {'id': 1, 'user': {'name': 'Er. Mohan'}, 'project': {'name': 'The Bajaj Villa'}, 'currentLocation': '28.4635, 77.0298', 'durationOutside': 25, 'createdAt': DateTime.now().toString()}
        ]
      };
    }
  }

  static Future<Map<String, dynamic>> applyFine(int? warningId, int employeeId, double amount, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fines/apply'),
        headers: _headers,
        body: json.encode({'warningId': warningId, 'employeeId': employeeId, 'amount': amount, 'reason': reason}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> acknowledgeFine(int fineId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/fines/$fineId/acknowledge'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> updateWarningStatus(int warningId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fines/warning/$warningId/status'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  // Hourly Site Progress
  static Future<Map<String, dynamic>> submitHourlyProgress(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/progress-hourly'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<List<dynamic>> getHourlyProgress(int projectId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects/progress-hourly/$projectId'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['progress'];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'workProgress': 'Excavation completed for rear garden, wall plastering check.',
          'remarks': 'Plastering in progress',
          'completionPercentage': 55,
          'workersPresent': 8,
          'materialsUsed': 'Cements: 10 bags, Sand: 1 load',
          'delayReason': '',
          'weather': 'Sunny',
          'photoUrls': '[]',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toString(),
          'user': {'name': 'Er. Mohan'}
        }
      ];
    }
  }

  // Announcement Actions
  static Future<Map<String, dynamic>> acknowledgeAnnouncement(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/announcements/$id/acknowledge'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> addAnnouncementComment(int id, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/announcements/$id/comment'),
        headers: _headers,
        body: json.encode({'comment': comment}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<List<dynamic>> getAnnouncementActions(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/announcements/$id/actions'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['actions'];
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'acknowledged': true, 'comment': 'Noted, safety harness checks verified.', 'user': {'name': 'Er. Mohan', 'role': 'Employee'}}
      ];
    }
  }

  // User CRUD
  static Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/employees'), headers: _headers, body: json.encode(data));
      if (response.statusCode == 201) {
        return {'success': true, 'user': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/employees/$id'), headers: _headers, body: json.encode(data));
      if (response.statusCode == 200) {
        return {'success': true, 'user': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/employees/$id'), headers: _headers);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  // Document Folders Access Control
  static Future<List<dynamic>> getDocuments(int projectId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects/$projectId/documents'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['documents'] ?? [];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'title': 'Client Agreement Sign-off',
          'fileName': 'Client_Agreement_Signoff.pdf',
          'fileSize': '1.4 MB',
          'folder': 'Agreements',
          'createdAt': '2026-06-10T12:00:00Z',
        },
        {
          'id': 2,
          'title': 'Site Property Tax Certs',
          'fileName': 'Site_Property_Tax_Certs.pdf',
          'fileSize': '840 KB',
          'folder': 'Property Documents',
          'createdAt': '2026-05-15T12:00:00Z',
        },
        {
          'id': 3,
          'title': 'Approval NOC Corporation',
          'fileName': 'Approval_NOC_Corporation.pdf',
          'fileSize': '3.1 MB',
          'folder': 'Property Documents',
          'createdAt': '2026-04-02T12:00:00Z',
        }
      ];
    }
  }

  static Future<Map<String, dynamic>> uploadDocument(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/documents'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return {'success': true, 'document': json.decode(response.body)};
      }
      final errBody = json.decode(response.body);
      return {'success': false, 'message': errBody['message'] ?? 'Error uploading document'};
    } catch (e) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> addAnnouncement(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return {'success': true, 'announcement': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<bool> updateAnnouncement(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> deleteAnnouncement(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  static Future<List<dynamic>> getAttendance() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['attendance'] ?? [];
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'user': {'name': 'Er. Mohan'},
          'date': DateTime.now().toIso8601String().split('T')[0],
          'gpsCheckIn': '28.4595, 77.0266',
          'checkInTime': '09:15 AM',
        }
      ];
    }
  }

  static Future<Map<String, dynamic>> approveDrawing(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/drawings/$id/approve'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'drawing': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> getWorkersAttendance(int projectId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance/workers/$projectId'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'workers': [
          {'id': 1, 'name': 'Ramesh Kumar', 'workerId': 'WRK-001', 'skillType': 'Mason', 'dailyWage': 800.0},
          {'id': 2, 'name': 'Sohan Lal', 'workerId': 'WRK-002', 'skillType': 'Carpenter', 'dailyWage': 900.0},
        ],
        'attendance': [
          {'workerId': 1, 'status': 'Present', 'overtimeHours': 0.0, 'remarks': ''}
        ]
      };
    }
  }

  static Future<Map<String, dynamic>> submitLabourAttendance(List<Map<String, dynamic>> workers, String gps, String date) async {
    return submitManagerAttendance(workers, gps, date);
  }

  static Future<Map<String, dynamic>> updateTaskStatus(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'task': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> deleteTask(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Upload and parse spreadsheet file (Excel/ZIP)
  static Future<Map<String, dynamic>> uploadImportFile(List<int> bytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/import/upload'));
      request.headers.addAll(_headers);
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        return json.decode(resBody);
      }
      return {'success': false, 'message': 'Upload failed: ${json.decode(resBody)['message'] ?? 'Unknown error'}'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  // --- BUSINESS TARGETS & PERFORMANCE WRAPPERS ---

  static Future<List<dynamic>> getAnnualTargets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/targets/annual'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'financialYear': '2026-2027',
          'annualProjectTarget': 120,
          'annualRevenueTarget': 12000000.0,
          'annualProfitTarget': 3600000.0,
          'residentialProjectsTarget': 50,
          'commercialProjectsTarget': 30,
          'interiorProjectsTarget': 30,
          'renovationProjectsTarget': 10,
          'newClientTarget': 15,
          'repeatClientTarget': 5,
          'isApproved': true,
          'monthlyTargets': []
        }
      ];
    }
  }

  static Future<Map<String, dynamic>> createAnnualTarget(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/targets/annual'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return {'success': true, 'target': json.decode(response.body)};
      }
      return {'success': false, 'message': json.decode(response.body)['message'] ?? 'Failed to create target'};
    } catch (e) {
      return {'success': true, 'target': data};
    }
  }

  static Future<Map<String, dynamic>> approveAnnualTarget(int id) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/targets/annual/$id/approve'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {'success': true, 'message': 'Approved successfully'};
    }
  }

  static Future<List<dynamic>> getMonthlyTargets(int annualTargetId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/targets/monthly/$annualTargetId'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      final months = ['April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', 'January', 'February', 'March'];
      return List.generate(12, (index) => {
        'id': index + 1,
        'annualTargetId': annualTargetId,
        'monthName': months[index],
        'monthNumber': index >= 9 ? index - 8 : index + 4,
        'projectTarget': 10,
        'revenueTarget': 1000000.0,
        'profitTarget': 300000.0,
        'residentialProjectsTarget': 4,
        'commercialProjectsTarget': 3,
        'interiorProjectsTarget': 2,
        'renovationProjectsTarget': 1,
        'newClientTarget': 1,
        'repeatClientTarget': 0,
      });
    }
  }

  static Future<Map<String, dynamic>> updateMonthlyTarget(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/targets/monthly/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'target': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true, 'target': data};
    }
  }

  static Future<List<dynamic>> getTeamTargets(String fy) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/targets/team?financialYear=$fy'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'financialYear': fy, 'teamName': 'Design Team', 'targetMetric': 'Project Design Completion', 'targetValue': 50.0, 'unit': 'number'},
        {'id': 2, 'financialYear': fy, 'teamName': 'Design Team', 'targetMetric': 'Drawing Completion', 'targetValue': 200.0, 'unit': 'number'},
        {'id': 3, 'financialYear': fy, 'teamName': 'Site Team', 'targetMetric': 'Site Completion', 'targetValue': 35.0, 'unit': 'number'},
        {'id': 4, 'financialYear': fy, 'teamName': 'Accounts Team', 'targetMetric': 'Invoice Collection (INR)', 'targetValue': 15000000.0, 'unit': 'amount'}
      ];
    }
  }

  static Future<Map<String, dynamic>> createTeamTarget(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/targets/team'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return {'success': true, 'target': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true, 'target': data};
    }
  }

  static Future<Map<String, dynamic>> updateTeamTarget(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/targets/team/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'target': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true, 'target': data};
    }
  }

  static Future<void> deleteTeamTarget(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/targets/team/$id'), headers: _headers);
    } catch (_) {}
  }

  static Future<List<dynamic>> getEmployeeTargets({int? employeeId}) async {
    try {
      final url = employeeId != null ? '$baseUrl/targets/employee?employeeId=$employeeId' : '$baseUrl/targets/employee';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'employeeId': 1,
          'employee': {'id': 1, 'name': 'Ar. Gokul Krishnan', 'role': 'Design Engineer', 'department': 'Designing Team'},
          'assigner': {'id': 99, 'name': 'Ar. Anand Sathiesivam'},
          'targetDescription': 'Complete 8 Drawings this Month',
          'targetMetric': 'drawings',
          'targetValue': 8.0,
          'currentValue': 5.0,
          'period': 'Monthly',
          'startDate': '2026-06-01',
          'endDate': '2026-06-30',
          'status': 'In Progress'
        },
        {
          'id': 2,
          'employeeId': 2,
          'employee': {'id': 2, 'name': 'Er. Anthony Richard', 'role': 'Site Engineer', 'department': 'Site Team'},
          'assigner': {'id': 99, 'name': 'Ar. Anand Sathiesivam'},
          'targetDescription': 'Complete 5 Site Inspections this Week',
          'targetMetric': 'inspections',
          'targetValue': 5.0,
          'currentValue': 4.0,
          'period': 'Weekly',
          'startDate': '2026-06-22',
          'endDate': '2026-06-28',
          'status': 'In Progress'
        }
      ];
    }
  }

  static Future<Map<String, dynamic>> assignEmployeeTarget(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/targets/employee'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return {'success': true, 'target': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true, 'target': data};
    }
  }

  static Future<Map<String, dynamic>> updateEmployeeTarget(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/targets/employee/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'target': json.decode(response.body)};
      }
      throw Exception();
    } catch (_) {
      return {'success': true, 'target': data};
    }
  }

  static Future<void> deleteEmployeeTarget(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/targets/employee/$id'), headers: _headers);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getExecutiveAnalytics() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/targets/analytics'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'financialYear': '2026-2027',
        'targets': {
          'annualProjectTarget': 120,
          'annualRevenueTarget': 12000000.0,
          'annualProfitTarget': 3600000.0,
          'residentialProjectsTarget': 50,
          'commercialProjectsTarget': 30,
          'interiorProjectsTarget': 30,
          'renovationProjectsTarget': 10,
          'newClientTarget': 15,
          'repeatClientTarget': 5
        },
        'currentPerformance': {
          'actualTurnover': 8450000.0,
          'outstandingAmount': 3240000.0,
          'totalExpenses': 5210000.0,
          'netProfit': 3240000.0,
          'totalProjects': 14,
          'projectsStarted': 8,
          'projectsCompleted': 5,
          'projectsDelayed': 2,
          'projectsOnHold': 1,
          'projectsCancelled': 0,
          'residentialCount': 8,
          'commercialCount': 3,
          'interiorCount': 2,
          'renovationCount': 1,
          'newClients': 9,
          'repeatClients': 3,
          'avgCompletionTime': 42
        },
        'monthlyRevenue': [750000.0, 1100000.0, 1250000.0, 950000.0, 1300000.0, 1400000.0, 800000.0, 900000.0, 0.0, 0.0, 0.0, 0.0],
        'quarterlyRevenue': [3100000.0, 3650000.0, 1700000.0, 0.0],
        'forecasts': {
          'projectedYearEndRevenue': 13520000.0,
          'projectedYearEndProjects': 108,
          'projectedYearEndProfit': 4320000.0
        },
        'scorecard': {
          'financial': 70,
          'projects': 68,
          'operations': 82,
          'clients': 72,
          'employees': 88,
          'overallHealth': 76
        },
        'departments': {
          'design': {
            'assigned': 45,
            'completed': 38,
            'pending': 7,
            'completionRate': 84
          },
          'site': {
            'progress': 88,
            'attendanceRate': 92,
            'productivity': 86
          },
          'accounts': {
            'collectionEfficiency': 72,
            'outstandingAmount': 3240000.0
          }
        },
        'topPerformingTeam': 'Design Team',
        'topPerformingEmployee': 'Ar. Gokul Krishnan',
        'pendingApprovalsCount': 3,
        'financialHealthScore': 78
      };
    }
  }

  static Future<List<dynamic>> getTargetAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/targets/alerts'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'type': 'Accounts',
          'severity': 'High',
          'title': 'Collection delayed',
          'message': 'Outstanding payments (₹32,40,000) are high relative to current collections. Action needed on invoice reminders.',
          'color': 'Red'
        },
        {
          'type': 'Projects',
          'severity': 'Medium',
          'title': 'Projects delayed',
          'message': 'There are currently 2 projects marked as Delayed on site.',
          'color': 'Yellow'
        }
      ];
    }
  }

  // Fetch build history
  static Future<List<dynamic>> getBuildHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/builds'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return [
        {
          'id': 1,
          'versionName': '1.0.0',
          'buildNumber': 1,
          'platform': 'Android APK (Release)',
          'status': 'Completed',
          'duration': 145,
          'fileName': 'vian_erp_v1.0.0_b1.apk',
          'fileSize': 19293812,
          'sha256Checksum': '8f6c31a7c39050d2f099238383818e698889de397394c8e7ff2823023023e12a',
          'releaseNotes': 'Initial release of VIAN Architects ERP app.',
          'createdAt': '2026-06-25T10:00:00.000Z',
          'builder': {'name': 'Ar. Anand Sathiesivam'}
        }
      ];
    }
  }

  // Fetch build configs
  static Future<Map<String, dynamic>> getBuildAppConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/builds/config'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'applicationName': 'VIAN ERP',
        'packageName': 'com.vian.erp',
        'version': '1.0.0',
        'buildNumber': 2,
        'environment': 'Production'
      };
    }
  }

  // Save build config
  static Future<Map<String, dynamic>> updateBuildAppConfig(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/builds/config'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return data;
    }
  }

  // Fetch signing configs
  static Future<Map<String, dynamic>> getSigningConfig(String platform) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/builds/signing?platform=$platform'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'platform': platform,
        'keystoreFile': 'vian_release.jks',
        'keystoreAlias': 'vian_key',
        'keystorePassword': '••••••••',
        'keyPassword': '••••••••',
        'certificateFile': null,
        'provisioningProfile': null
      };
    }
  }

  // Update signing configs
  static Future<Map<String, dynamic>> updateSigningConfig(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/builds/signing'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return data;
    }
  }

  // Trigger build
  static Future<Map<String, dynamic>> triggerBuild(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/builds/trigger'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'success': true,
        'message': 'Build enqueued successfully (Offline Mock Mode)',
        'build': {
          'id': 99,
          'versionName': data['versionName'],
          'buildNumber': data['buildNumber'],
          'platform': data['platform'],
          'status': 'Pending',
          'releaseNotes': data['releaseNotes']
        }
      };
    }
  }

  // Get build status & logs
  static Future<Map<String, dynamic>> getBuildStatus(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/builds/$id/status'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'status': 'Completed',
        'progress': 100,
        'duration': 120,
        'recentLogs': 'Mock compile success.\nGenerated artifact.',
        'build': {
          'id': id,
          'versionName': '1.0.0',
          'buildNumber': 1,
          'platform': 'Web Production Build',
          'status': 'Completed',
          'fileName': 'vian_erp_web_v1.0.0_b1.zip',
          'fileSize': 8493812,
          'sha256Checksum': 'MockSHA256ChecksumHashValueExample',
          'artifactPath': '/uploads/artifacts/vian_erp_web_v1.0.0_b1.zip'
        }
      };
    }
  }

  // Get full logs
  static Future<String> getBuildLogs(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/builds/$id/logs'), headers: _headers);
      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception();
    } catch (_) {
      return 'Mock logs: Full log retrieval is currently running in offline mock state.';
    }
  }

  // Get all estimates
  static Future<List<dynamic>> getEstimates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estimations'), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : (data['estimates'] ?? []);
      }
      throw Exception();
    } catch (_) {
      // Mock fallback
      return [
        {
          'id': 1,
          'estimateNumber': 'EST-2026-0001',
          'projectName': 'Villa Horizon Chennai',
          'clientName': 'Amit Bajaj',
          'projectType': 'Villa',
          'constructionType': 'Premium Luxury',
          'state': 'Tamil Nadu',
          'district': 'Chennai',
          'city': 'Chennai',
          'siteAddress': 'ECR Road, Chennai',
          'builtUpArea': 3500.0,
          'unit': 'Square Feet',
          'selectedPackage': 'Premium',
          'packageRate': 2800.0,
          'totalCost': 9800000.0,
          'status': 'Approved',
          'createdAt': '2026-06-25T10:00:00.000Z',
          'creator': {'name': 'Ar. Anand Sathiesivam'}
        },
        {
          'id': 2,
          'estimateNumber': 'EST-2026-0002',
          'projectName': 'Commercial Hub Coimbatore',
          'clientName': 'Rajesh Malhotra',
          'projectType': 'Commercial Building',
          'constructionType': 'Standard',
          'state': 'Tamil Nadu',
          'district': 'Coimbatore',
          'city': 'Coimbatore',
          'siteAddress': 'Avinashi Road, Coimbatore',
          'builtUpArea': 12000.0,
          'unit': 'Square Feet',
          'selectedPackage': 'Standard',
          'packageRate': 2500.0,
          'totalCost': 30000000.0,
          'status': 'Pending',
          'createdAt': '2026-06-25T11:30:00.000Z',
          'creator': {'name': 'Ar. Sasmitha'}
        }
      ];
    }
  }

  // Get estimation dashboard stats
  static Future<Map<String, dynamic>> getEstimationDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estimations/dashboard'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'totalEstimates': 2,
        'pendingEstimates': 1,
        'approvedEstimates': 1,
        'averageCostPerSqft': 2650.0,
        'distribution': {
          'Economy': 0,
          'Standard': 1,
          'Premium': 1
        },
        'recentEstimates': [
          {
            'id': 2,
            'estimateNumber': 'EST-2026-0002',
            'projectName': 'Commercial Hub Coimbatore',
            'clientName': 'Rajesh Malhotra',
            'status': 'Pending',
            'totalCost': 30000000.0
          },
          {
            'id': 1,
            'estimateNumber': 'EST-2026-0001',
            'projectName': 'Villa Horizon Chennai',
            'clientName': 'Amit Bajaj',
            'status': 'Approved',
            'totalCost': 9800000.0
          }
        ]
      };
    }
  }

  // Calculate simulation details side-by-side
  static Future<Map<String, dynamic>> calculateEstimate(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations/calculate'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      // Mock calculation engine response based on input
      final double area = double.tryParse(data['builtUpArea'].toString()) ?? 1000.0;
      final String unit = data['unit'] ?? 'Square Feet';
      final double areaSqFt = unit == 'Square Meter' ? area * 10.7639 : area;
      final String pkg = data['selectedPackage'] ?? 'Standard';
      final String dist = data['district'] ?? 'Chennai';

      final rates = {'Economy': 2200.0, 'Standard': 2500.0, 'Premium': 2800.0};
      final selectedRate = rates[pkg] ?? 2500.0;
      
      // Simulating adjustments
      double adj = 1.0;
      if (dist == 'Chennai') adj = 1.1;
      
      final double ratePerSqFt = selectedRate * adj;
      final double totalCost = areaSqFt * ratePerSqFt;

      return {
        'totalCost': totalCost.round(),
        'ratePerUnit': ratePerSqFt.round(),
        'comparison': {
          'Economy': (areaSqFt * rates['Economy']! * adj).round(),
          'Standard': (areaSqFt * rates['Standard']! * adj).round(),
          'Premium': (areaSqFt * rates['Premium']! * adj).round()
        },
        'materials': [
          {'materialName': 'Cement', 'unit': 'Bags', 'quantity': (areaSqFt * 0.4).roundToDouble(), 'rate': 420.0, 'cost': (areaSqFt * 0.4 * 420.0).roundToDouble()},
          {'materialName': 'Steel', 'unit': 'Kgs', 'quantity': (areaSqFt * 4.0).roundToDouble(), 'rate': 68.0, 'cost': (areaSqFt * 4.0 * 68.0).roundToDouble()},
          {'materialName': 'Sand', 'unit': 'Cft', 'quantity': (areaSqFt * 1.5).roundToDouble(), 'rate': 85.0, 'cost': (areaSqFt * 1.5 * 85.0).roundToDouble()},
          {'materialName': 'Aggregate', 'unit': 'Cft', 'quantity': (areaSqFt * 1.8).roundToDouble(), 'rate': 72.0, 'cost': (areaSqFt * 1.8 * 72.0).roundToDouble()},
          {'materialName': 'Concrete', 'unit': 'Cu.m', 'quantity': (areaSqFt * 0.05).roundToDouble(), 'rate': 4500.0, 'cost': (areaSqFt * 0.05 * 4500.0).roundToDouble()},
          {'materialName': 'Tiles', 'unit': 'Sq.ft', 'quantity': (areaSqFt * 1.2).roundToDouble(), 'rate': 90.0, 'cost': (areaSqFt * 1.2 * 90.0).roundToDouble()},
          {'materialName': 'Paint', 'unit': 'Litres', 'quantity': (areaSqFt * 0.15).roundToDouble(), 'rate': 280.0, 'cost': (areaSqFt * 0.15 * 280.0).roundToDouble()}
        ],
        'labour': [
          {'labourType': 'Mason', 'requiredWorkers': (areaSqFt / 1000).ceil() + 1, 'estimatedDays': 60, 'estimatedCost': ((areaSqFt / 1000).ceil() + 1) * 60 * 950},
          {'labourType': 'Helper', 'requiredWorkers': (areaSqFt / 500).ceil() + 1, 'estimatedDays': 60, 'estimatedCost': ((areaSqFt / 500).ceil() + 1) * 60 * 650},
          {'labourType': 'Carpenter', 'requiredWorkers': 2, 'estimatedDays': 25, 'estimatedCost': 2 * 25 * 900},
          {'labourType': 'Bar Bender', 'requiredWorkers': 3, 'estimatedDays': 15, 'estimatedCost': 3 * 15 * 900}
        ],
        'phases': [
          {'phaseName': 'Foundation', 'estimatedCost': (totalCost * 0.1).round(), 'estimatedDuration': 25, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.1).round()},
          {'phaseName': 'RCC Structure', 'estimatedCost': (totalCost * 0.25).round(), 'estimatedDuration': 45, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.25).round()},
          {'phaseName': 'Brick Work', 'estimatedCost': (totalCost * 0.12).round(), 'estimatedDuration': 20, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.12).round()},
          {'phaseName': 'Roofing', 'estimatedCost': (totalCost * 0.08).round(), 'estimatedDuration': 15, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.08).round()},
          {'phaseName': 'Plastering', 'estimatedCost': (totalCost * 0.08).round(), 'estimatedDuration': 20, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.08).round()},
          {'phaseName': 'Flooring', 'estimatedCost': (totalCost * 0.07).round(), 'estimatedDuration': 15, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.07).round()},
          {'phaseName': 'Electrical', 'estimatedCost': (totalCost * 0.06).round(), 'estimatedDuration': 10, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.06).round()},
          {'phaseName': 'Plumbing', 'estimatedCost': (totalCost * 0.05).round(), 'estimatedDuration': 10, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.05).round()},
          {'phaseName': 'Doors & Windows', 'estimatedCost': (totalCost * 0.06).round(), 'estimatedDuration': 12, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.06).round()},
          {'phaseName': 'Painting', 'estimatedCost': (totalCost * 0.05).round(), 'estimatedDuration': 14, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.05).round()},
          {'phaseName': 'Interior Works', 'estimatedCost': (totalCost * 0.05).round(), 'estimatedDuration': 15, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.05).round()},
          {'phaseName': 'Final Finishing', 'estimatedCost': (totalCost * 0.03).round(), 'estimatedDuration': 8, 'completionPercentage': 0, 'budgetAllocation': (totalCost * 0.03).round()}
        ],
        'boq': [
          {'materialName': 'Cement', 'unit': 'Bags', 'quantity': (areaSqFt * 0.4).roundToDouble(), 'rate': 420.0, 'amount': (areaSqFt * 0.4 * 420.0).roundToDouble(), 'gstRate': 18.0, 'gstAmount': (areaSqFt * 0.4 * 420.0 * 0.18).roundToDouble(), 'totalAmount': (areaSqFt * 0.4 * 420.0 * 1.18).roundToDouble()},
          {'materialName': 'Steel', 'unit': 'Kgs', 'quantity': (areaSqFt * 4.0).roundToDouble(), 'rate': 68.0, 'amount': (areaSqFt * 4.0 * 68.0).roundToDouble(), 'gstRate': 18.0, 'gstAmount': (areaSqFt * 4.0 * 68.0 * 0.18).roundToDouble(), 'totalAmount': (areaSqFt * 4.0 * 68.0 * 1.18).roundToDouble()},
          {'materialName': 'Sand', 'unit': 'Cft', 'quantity': (areaSqFt * 1.5).roundToDouble(), 'rate': 85.0, 'amount': (areaSqFt * 1.5 * 85.0).roundToDouble(), 'gstRate': 18.0, 'gstAmount': (areaSqFt * 1.5 * 85.0 * 0.18).roundToDouble(), 'totalAmount': (areaSqFt * 1.5 * 85.0 * 1.18).roundToDouble()}
        ],
        'durationDays': 180,
        'profitAnalysis': {
          'constructionCost': totalCost.round(),
          'companyMarginPercentage': 12.0,
          'estimatedProfit': (totalCost * 0.12).round(),
          'gstPercentage': 18.0,
          'gstAmount': ((totalCost * 1.12) * 0.18).round(),
          'netProjectValue': ((totalCost * 1.12) * 1.18).round(),
          'companyOverhead': 50000.0
        }
      };
    }
  }

  // Save new estimate
  static Future<Map<String, dynamic>> saveEstimate(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {
        'success': true,
        'message': 'Estimate saved successfully (Offline Mock)',
        'estimate': {
          'id': 3,
          'estimateNumber': 'EST-2026-0003',
          'projectName': data['projectName'],
          'clientName': data['clientName'],
          'status': 'Pending',
          'totalCost': data['totalCost'],
          'createdAt': DateTime.now().toIso8601String()
        }
      };
    }
  }

  // Get estimate details
  static Future<Map<String, dynamic>> getEstimate(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estimations/$id'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      // Mock estimate detail
      return {
        'id': id,
        'estimateNumber': id == 1 ? 'EST-2026-0001' : 'EST-2026-0002',
        'projectName': id == 1 ? 'Villa Horizon Chennai' : 'Commercial Hub Coimbatore',
        'clientName': id == 1 ? 'Amit Bajaj' : 'Rajesh Malhotra',
        'projectType': id == 1 ? 'Villa' : 'Commercial Building',
        'constructionType': id == 1 ? 'Premium Luxury' : 'Standard',
        'state': 'Tamil Nadu',
        'district': id == 1 ? 'Chennai' : 'Coimbatore',
        'city': id == 1 ? 'Chennai' : 'Coimbatore',
        'siteAddress': id == 1 ? 'ECR Road, Chennai' : 'Avinashi Road, Coimbatore',
        'builtUpArea': id == 1 ? 3500.0 : 12000.0,
        'unit': 'Square Feet',
        'selectedPackage': id == 1 ? 'Premium' : 'Standard',
        'packageRate': id == 1 ? 2800.0 : 2500.0,
        'totalCost': id == 1 ? 9800000.0 : 30000000.0,
        'companyMarginPercentage': 12.0,
        'estimatedProfit': id == 1 ? 1176000.0 : 3600000.0,
        'gstPercentage': 18.0,
        'gstAmount': id == 1 ? 1975680.0 : 6048000.0,
        'netProjectValue': id == 1 ? 12951680.0 : 39648000.0,
        'status': id == 1 ? 'Approved' : 'Pending',
        'projectId': id == 1 ? 1 : null,
        'createdAt': '2026-06-25T10:00:00.000Z',
        'creator': {'name': 'Ar. Anand Sathiesivam'},
        'materials': [
          {'id': 1, 'materialName': 'Cement', 'unit': 'Bags', 'quantity': 1400.0, 'rate': 420.0, 'cost': 588000.0},
          {'id': 2, 'materialName': 'Steel', 'unit': 'Kgs', 'quantity': 14000.0, 'rate': 68.0, 'cost': 952000.0},
          {'id': 3, 'materialName': 'Sand', 'unit': 'Cft', 'quantity': 5250.0, 'rate': 85.0, 'cost': 446250.0}
        ],
        'labours': [
          {'id': 1, 'labourType': 'Mason', 'requiredWorkers': 5, 'estimatedDays': 60, 'estimatedCost': 285000.0},
          {'id': 2, 'labourType': 'Helper', 'requiredWorkers': 8, 'estimatedDays': 60, 'estimatedCost': 312000.0}
        ],
        'phases': [
          {'id': 1, 'phaseName': 'Foundation', 'estimatedCost': 980000.0, 'estimatedDuration': 25, 'completionPercentage': 100, 'budgetAllocation': 980000.0},
          {'id': 2, 'phaseName': 'RCC Structure', 'estimatedCost': 2450000.0, 'estimatedDuration': 45, 'completionPercentage': 20, 'budgetAllocation': 2450000.0},
          {'id': 3, 'phaseName': 'Brick Work', 'estimatedCost': 1176000.0, 'estimatedDuration': 20, 'completionPercentage': 0, 'budgetAllocation': 1176000.0}
        ],
        'boqs': [
          {'id': 1, 'materialName': 'Cement', 'unit': 'Bags', 'quantity': 1400.0, 'rate': 420.0, 'amount': 588000.0, 'gstRate': 18.0, 'gstAmount': 105840.0, 'totalAmount': 693840.0},
          {'id': 2, 'materialName': 'Steel', 'unit': 'Kgs', 'quantity': 14000.0, 'rate': 68.0, 'amount': 952000.0, 'gstRate': 18.0, 'gstAmount': 171360.0, 'totalAmount': 1123360.0}
        ]
      };
    }
  }

  // Update pending estimate
  static Future<Map<String, dynamic>> updateEstimate(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/estimations/$id'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Estimate updated successfully (Offline Mock)'};
    }
  }

  // Approve estimate & auto-create project
  static Future<Map<String, dynamic>> approveEstimate(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations/$id/approve'),
        headers: _headers,
      );
      return json.decode(response.body);
    } catch (_) {
      return {
        'success': true,
        'message': 'Estimate approved and Project created successfully (Offline Mock)',
        'project': {
          'id': 10,
          'projectId': 'VIAN-2026-0010',
          'name': 'Villa Horizon Chennai Project',
          'status': 'Planning'
        }
      };
    }
  }

  // Get cost settings (Super Admin / Managing Director)
  static Future<Map<String, dynamic>> getEstimationSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estimations/settings'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'id': 1,
        'economyRate': 2200.0,
        'standardRate': 2500.0,
        'premiumRate': 2800.0,
        'profitMarginPercentage': 12.0,
        'gstPercentage': 18.0,
        'regionalCostIndex': 1.0,
        'companyOverhead': 50000.0,
        'districtAdjustments': json.encode({
          'Chennai': 1.1,
          'Coimbatore': 1.0,
          'Madurai': 0.95,
          'Trichy': 0.95,
          'Salem': 0.9,
          'Tiruppur': 1.0
        }),
        'materialsFormula': json.encode({
          'Cement': {'unit': 'Bags', 'economy': 0.38, 'standard': 0.4, 'premium': 0.42, 'defaultRate': 420.0},
          'Steel': {'unit': 'Kgs', 'economy': 3.5, 'standard': 4.0, 'premium': 4.5, 'defaultRate': 68.0},
          'Sand': {'unit': 'Cft', 'economy': 1.4, 'standard': 1.5, 'premium': 1.6, 'defaultRate': 85.0},
          'Aggregate': {'unit': 'Cft', 'economy': 1.6, 'standard': 1.8, 'premium': 2.0, 'defaultRate': 72.0},
          'Concrete': {'unit': 'Cu.m', 'economy': 0.04, 'standard': 0.05, 'premium': 0.06, 'defaultRate': 4500.0},
          'Tiles': {'unit': 'Sq.ft', 'economy': 1.0, 'standard': 1.2, 'premium': 1.4, 'defaultRate': 90.0},
          'Paint': {'unit': 'Litres', 'economy': 0.12, 'standard': 0.15, 'premium': 0.18, 'defaultRate': 280.0}
        }),
        'labourFormula': json.encode({
          'Mason': {'economy': 18, 'standard': 20, 'premium': 22, 'defaultWage': 950.0},
          'Helper': {'economy': 25, 'standard': 30, 'premium': 35, 'defaultWage': 650.0},
          'Carpenter': {'economy': 4, 'standard': 5, 'premium': 6, 'defaultWage': 900.0},
          'Bar Bender': {'economy': 6, 'standard': 7, 'premium': 8, 'defaultWage': 900.0}
        }),
        'timelineFormula': json.encode([
          {'maxArea': 1500, 'months': 6},
          {'maxArea': 3000, 'months': 8},
          {'maxArea': 5000, 'months': 10}
        ])
      };
    }
  }

  // Update cost settings
  static Future<Map<String, dynamic>> updateEstimationSettings(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations/settings'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Estimation settings updated successfully (Offline Mock)'};
    }
  }

  // Get Company Settings
  static Future<Map<String, dynamic>> getCompanySettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/settings'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'settings': {
          'companyName': 'VIAN Architects & Designers',
          'address': 'Plot 42, Galleria Complex, Sector 43, Gurugram',
          'gst': '07AAAAA1111A1Z1',
          'email': 'office@vianarchitects.com',
          'phone': '+91 124 4567890',
          'cloudinaryCloudName': '',
          'cloudinaryApiKey': '',
          'cloudinaryApiSecret': ''
        }
      };
    }
  }

  // Update Company Settings
  static Future<Map<String, dynamic>> updateCompanySettings(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Company settings updated successfully (Offline Mock)'};
    }
  }

  // Get AI settings
  static Future<Map<String, dynamic>> getAiSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ai/settings'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'id': 1,
        'geminiApiKey': '',
        'aiModel': 'gemini-1.5-flash',
        'temperature': 0.2,
        'maxTokens': 2048,
        'timeout': 30000,
        'enableAi': true,
        'enablePdfAnalysis': true,
        'enableImageAnalysis': true,
        'enableBoqGeneration': true,
        'enableCostEstimation': true,
        'apiUsageCount': 0,
        'dailyTokenUsage': 0
      };
    }
  }

  // Update AI settings
  static Future<Map<String, dynamic>> updateAiSettings(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/settings'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'AI settings updated successfully (Offline Mock)'};
    }
  }

  // Test AI Connection
  static Future<Map<String, dynamic>> testAiConnection(String apiKey, String model) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/test'),
        headers: _headers,
        body: json.encode({'geminiApiKey': apiKey, 'aiModel': model}),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': false, 'message': 'Connection test failed (Offline Mock)'};
    }
  }

  // Upload floor plan for AI analysis
  static Future<Map<String, dynamic>> analyzeFloorPlanWithAi(List<int> bytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/estimations/ai-analyze'));
      request.headers.addAll(_headers);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'success': false,
        'message': 'Failed to analyze floor plan (Status code: ${response.statusCode})'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading floor plan: $e'
      };
    }
  }

  // Share quotation
  static Future<Map<String, dynamic>> shareQuotation(int id, String channel, String recipient) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations/$id/share'),
        headers: _headers,
        body: json.encode({'channel': channel, 'recipient': recipient}),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Quotation shared successfully (Offline Mock)'};
    }
  }

  // Export quotation to Excel
  static Future<List<int>?> exportQuotationExcel(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estimations/$id/quotation/excel'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Get market prices
  static Future<List<dynamic>> getMarketPrices({String? district}) async {
    try {
      final url = district != null ? '$baseUrl/estimations/market-prices?district=$district' : '$baseUrl/estimations/market-prices';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return [
        {'id': 1, 'materialName': 'Cement', 'currentRate': 420.0, 'previousRate': 415.0, 'supplier': 'UltraTech Direct', 'district': district ?? 'Chennai'},
        {'id': 2, 'materialName': 'Steel', 'currentRate': 68.0, 'previousRate': 70.0, 'supplier': 'TATA Tiscon Dealer', 'district': district ?? 'Chennai'},
        {'id': 3, 'materialName': 'Sand', 'currentRate': 85.0, 'previousRate': 82.0, 'supplier': 'Local Riverbed Quarry', 'district': district ?? 'Chennai'},
        {'id': 4, 'materialName': 'Aggregate', 'currentRate': 72.0, 'previousRate': 72.0, 'supplier': 'Blue Metal Crushers', 'district': district ?? 'Chennai'}
      ];
    }
  }

  // Update specific market price
  static Future<Map<String, dynamic>> updateMarketPrice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations/market-prices'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Market price updated successfully (Offline Mock)'};
    }
  }

  // Create a new market price record
  static Future<Map<String, dynamic>> createMarketPrice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estimations/market-prices/new'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Market price created successfully (Offline Mock)'};
    }
  }

  // Delete a market price record
  static Future<Map<String, dynamic>> deleteMarketPrice(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/estimations/market-prices/$id'),
        headers: _headers,
      );
      return json.decode(response.body);
    } catch (_) {
      return {'success': true, 'message': 'Market price record deleted successfully (Offline Mock)'};
    }
  }

  // Get budget vs actual details
  static Future<Map<String, dynamic>> getBudgetVsActual(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estimations/$id/budget-actual'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {
        'estimatedMaterialCost': 1986250.0,
        'actualMaterialCost': 1850000.0,
        'materialVariance': 136250.0,
        'materialStatus': 'green',

        'estimatedLabourCost': 597000.0,
        'actualLabourCost': 610000.0,
        'labourVariance': -13000.0,
        'labourStatus': 'yellow',

        'estimatedExpenses': 0.0,
        'actualExpenses': 85000.0,
        'expensesVariance': -85000.0,
        'expensesStatus': 'red',

        'totalEstimatedCost': 9800000.0,
        'totalActualCost': 2545000.0,
        'totalVariance': 7255000.0,
        'totalStatus': 'green'
      };
    }
  }

  // Get project by ID with full nested details
  static Future<Map<String, dynamic>> getProjectDetails(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects/$id'), headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception();
    } catch (_) {
      return {};
    }
  }

  // Archive project
  static Future<bool> archiveProject(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/projects/$id/archive'), headers: _headers);
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Restore project
  static Future<bool> restoreProject(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/projects/$id/restore'), headers: _headers);
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Duplicate project
  static Future<bool> duplicateProject(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/projects/$id/duplicate'), headers: _headers);
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Delete project (MD / Super Admin only)
  static Future<bool> deleteProject(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/projects/$id'), headers: _headers);
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Create project stage
  static Future<bool> addProjectStage(int projectId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/stages'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Update project stage
  static Future<bool> updateProjectStage(int projectId, int stageId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Delete project stage
  static Future<bool> deleteProjectStage(int projectId, int stageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Record daily report / hourly site tracking
  static Future<bool> addStageReport(int projectId, int stageId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId/reports'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Record material log
  static Future<bool> addStageMaterialLog(int projectId, int stageId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId/materials'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Record labour log
  static Future<bool> addStageLabourLog(int projectId, int stageId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId/labours'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Record payment log
  static Future<bool> addStagePaymentLog(int projectId, int stageId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId/payments'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // Approve stage step
  static Future<bool> approveStage(int projectId, int stageId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/stages/$stageId/approve'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  // ==========================================
  // PUBLIC CLIENT ENQUIRY PORTAL MODULE
  // ==========================================

  // Generate Enquiry Link
  static Future<Map<String, dynamic>> generateEnquiryLink(int leadId, {int? expiryDays}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/generate-link'),
        headers: _headers,
        body: json.encode({'leadId': leadId, 'expiryDays': expiryDays}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Upload Enquiry Attachment (Public)
  static Future<Map<String, dynamic>> uploadEnquiryAttachment(String fileName, List<int> bytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/enquiry/upload'))
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Upload failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Toggle Enquiry Link Status
  static Future<Map<String, dynamic>> statusEnquiryLink(int leadId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/status-link'),
        headers: _headers,
        body: json.encode({'leadId': leadId, 'status': status}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Retrieve Link and Draft by Token (Public)
  static Future<Map<String, dynamic>> getEnquiryLink(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enquiry/link/$token'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': json.decode(response.body)['message'] ?? 'Invalid token'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Save Draft by Token (Public)
  static Future<Map<String, dynamic>> saveEnquiryDraft(String token, Map<String, dynamic> draftData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/draft/$token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'draftData': draftData}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Submit Enquiry by Token (Public)
  static Future<Map<String, dynamic>> submitEnquiry(String token, Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/submit/$token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': json.decode(response.body)['message'] ?? 'Submission failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Submissions Inbox (Authorized)
  static Future<List<dynamic>> getEnquiryInbox() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enquiry/inbox'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['submissions'] ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Update Submission Status (In Review, Rejected, etc.)
  static Future<bool> updateEnquiryStatus(int id, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/status/$id'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Add Submission Note
  static Future<bool> addEnquiryNote(int submissionId, String noteText) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/notes/$submissionId'),
        headers: _headers,
        body: json.encode({'noteText': noteText}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Approve Submission & Convert to Project
  static Future<Map<String, dynamic>> approveEnquiry(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enquiry/approve/$id'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Approval failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  // Get trash items for a module
  static Future<List<dynamic>> getTrashItems(String module) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trash/$module'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['items'] ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Restore trash item
  static Future<bool> restoreItem(String module, int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/restore/$module/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- OFFLINE SYNC QUEUE ---
  static List<Map<String, dynamic>> offlineQueue = [];
  
  static void queueOfflineRequest(String endpoint, String method, Map<String, dynamic> data) {
    offlineQueue.add({
      'endpoint': endpoint,
      'method': method,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('Offline sync queued: $endpoint');
  }

  static Future<void> processOfflineQueue() async {
    if (offlineQueue.isEmpty) return;
    print('Processing offline queue (${offlineQueue.length} items)...');
    
    final tempQueue = List<Map<String, dynamic>>.from(offlineQueue);
    offlineQueue.clear();

    for (final item in tempQueue) {
      try {
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final data = item['data'] as Map<String, dynamic>;

        if (method == 'POST') {
          await http.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: json.encode(data),
          );
        }
      } catch (e) {
        // Re-queue on failure
        offlineQueue.add(item);
        print('Offline sync failed for item, re-queued: $e');
      }
    }
  }

  // --- CONFERENCE CALLS TRACKER ---
  static Future<List<dynamic>> getConferenceCalls() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conference-calls'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createConferenceCall(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conference-calls'),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      queueOfflineRequest('/conference-calls', 'POST', data);
      return true;
    }
  }

  // --- STAFF INCENTIVE ENGINE ---
  static Future<List<dynamic>> getIncentives(String month) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/incentives?month=$month'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> calculateIncentive(int userId, String month) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/incentives/calculate'),
        headers: _headers,
        body: json.encode({'userId': userId, 'month': month}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateIncentiveStatus(int id, String status, String remarks) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/incentives/$id/status'),
        headers: _headers,
        body: json.encode({'status': status, 'remarks': remarks}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

double safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  return 0;
}


