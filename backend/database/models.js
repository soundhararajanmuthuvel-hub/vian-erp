const { DataTypes } = require('sequelize');
const { getSequelize } = require('./db');

// Function to initialize models and set up relations
function initModels() {
  const sequelize = getSequelize();

  // 1. User Model
  const User = sequelize.define('User', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    employeeId: { type: DataTypes.STRING, unique: true, allowNull: true },
    username: { type: DataTypes.STRING, unique: true, allowNull: false },
    passwordHash: { type: DataTypes.STRING, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, unique: true, allowNull: false },
    mobile: { type: DataTypes.STRING, allowNull: true },
    role: {
      type: DataTypes.STRING,
      allowNull: false
    },
    department: { type: DataTypes.STRING, allowNull: true },
    designation: { type: DataTypes.STRING, allowNull: true },
    joiningDate: { type: DataTypes.DATEONLY, allowNull: true },
    status: { type: DataTypes.ENUM('Active', 'Inactive'), defaultValue: 'Active' }
  }, { tableName: 'users', timestamps: true, underscored: true });

  // 2. Session Model
  const Session = sequelize.define('Session', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    token: { type: DataTypes.STRING(500), allowNull: false },
    deviceId: { type: DataTypes.STRING, allowNull: true },
    deviceName: { type: DataTypes.STRING, allowNull: true },
    expiresAt: { type: DataTypes.DATE, allowNull: false }
  }, { tableName: 'sessions', timestamps: true, underscored: true });

  // 3. Lead Model
  const Lead = sequelize.define('Lead', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    name: { type: DataTypes.STRING, allowNull: false },
    phone: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, allowNull: true },
    source: { type: DataTypes.STRING, allowNull: true },
    budget: { type: DataTypes.DECIMAL(15, 2), allowNull: true },
    requirement: { type: DataTypes.TEXT, allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
    status: {
      type: DataTypes.ENUM('New', 'Contacted', 'Site Visit Scheduled', 'Proposal Sent', 'Negotiation', 'Won', 'Lost'),
      defaultValue: 'New'
    },
    companyName: { type: DataTypes.STRING, allowNull: true },
    contactPerson: { type: DataTypes.STRING, allowNull: true },
    city: { type: DataTypes.STRING, allowNull: true },
    state: { type: DataTypes.STRING, allowNull: true },
    country: { type: DataTypes.STRING, allowNull: true },
    gstNumber: { type: DataTypes.STRING, allowNull: true },
    pan: { type: DataTypes.STRING, allowNull: true },
    industry: { type: DataTypes.STRING, allowNull: true },
    attachments: { type: DataTypes.TEXT, allowNull: true },
    converted: { type: DataTypes.ENUM('Yes', 'No'), defaultValue: 'No' },
    convertedDate: { type: DataTypes.DATE, allowNull: true },
    convertedBy: { type: DataTypes.INTEGER, allowNull: true },
    clientId: { type: DataTypes.STRING, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'leads', timestamps: true, underscored: true });

  // 4. LeadTimeline Model
  const LeadTimeline = sequelize.define('LeadTimeline', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    action: { type: DataTypes.STRING, allowNull: false },
    notes: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'lead_timeline', timestamps: true, underscored: true });

  // 5. Client Model
  const Client = sequelize.define('Client', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    clientId: { type: DataTypes.STRING, unique: true, allowNull: true },
    name: { type: DataTypes.STRING, allowNull: false },
    phone: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, allowNull: false },
    address: { type: DataTypes.TEXT, allowNull: true },
    gst: { type: DataTypes.STRING(15), allowNull: true },
    propertyDetails: { type: DataTypes.TEXT, allowNull: true },
    companyName: { type: DataTypes.STRING, allowNull: true },
    contactPerson: { type: DataTypes.STRING, allowNull: true },
    city: { type: DataTypes.STRING, allowNull: true },
    state: { type: DataTypes.STRING, allowNull: true },
    country: { type: DataTypes.STRING, allowNull: true },
    gstNumber: { type: DataTypes.STRING, allowNull: true },
    pan: { type: DataTypes.STRING, allowNull: true },
    leadSource: { type: DataTypes.STRING, allowNull: true },
    industry: { type: DataTypes.STRING, allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
    attachments: { type: DataTypes.TEXT, allowNull: true },
    assignedTo: { type: DataTypes.INTEGER, allowNull: true },
    leadId: { type: DataTypes.INTEGER, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'clients', timestamps: true, underscored: true });

  // 5b. ClientTimeline Model
  const ClientTimeline = sequelize.define('ClientTimeline', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    clientId: { type: DataTypes.INTEGER, allowNull: false },
    action: { type: DataTypes.STRING, allowNull: false },
    notes: { type: DataTypes.TEXT, allowNull: true },
    performedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'client_timeline', timestamps: true, underscored: true });

  // 6. Project Model
  const Project = sequelize.define('Project', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    projectId: { type: DataTypes.STRING, unique: true, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    type: {
      type: DataTypes.ENUM('Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'),
      allowNull: false
    },
    budget: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    startDate: { type: DataTypes.DATEONLY, allowNull: true },
    completionDate: { type: DataTypes.DATEONLY, allowNull: true },
    status: {
      type: DataTypes.ENUM('Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled'),
      defaultValue: 'Planning'
    },
    progressPercentage: { type: DataTypes.INTEGER, defaultValue: 0 },
    actualMaterialCost: { type: DataTypes.DECIMAL(15, 2), allowNull: true },
    actualLabourCost: { type: DataTypes.DECIMAL(15, 2), allowNull: true },
    actualTimelineMonths: { type: DataTypes.INTEGER, allowNull: true },
    actualPurchaseCost: { type: DataTypes.DECIMAL(15, 2), allowNull: true },
    actualProfit: { type: DataTypes.DECIMAL(15, 2), allowNull: true },
    managingDirectorId: { type: DataTypes.INTEGER, allowNull: true },
    designEngineerId: { type: DataTypes.INTEGER, allowNull: true },
    supervisorId: { type: DataTypes.INTEGER, allowNull: true },
    constructionPackage: { type: DataTypes.STRING, allowNull: true },
    siteAddress: { type: DataTypes.TEXT, allowNull: true },
    googleMapsLocation: { type: DataTypes.STRING, allowNull: true },
    builtUpArea: { type: DataTypes.DECIMAL(12, 2), allowNull: true },
    floors: { type: DataTypes.INTEGER, defaultValue: 1 },
    isArchived: { type: DataTypes.BOOLEAN, defaultValue: false },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true },
    latitude: { type: DataTypes.DECIMAL(9, 6), allowNull: true },
    longitude: { type: DataTypes.DECIMAL(9, 6), allowNull: true },
    allowedRadius: { type: DataTypes.INTEGER, defaultValue: 100 }
  }, { tableName: 'projects', timestamps: true, underscored: true });

  // 7. Attendance Model
  const Attendance = sequelize.define('Attendance', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    checkInTime: { type: DataTypes.TIME, allowNull: true },
    checkInGps: { type: DataTypes.STRING, allowNull: true },
    checkInSelfieUrl: { type: DataTypes.STRING, allowNull: true },
    checkOutTime: { type: DataTypes.TIME, allowNull: true },
    checkOutGps: { type: DataTypes.STRING, allowNull: true },
    workingHours: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.00 },
    status: {
      type: DataTypes.ENUM('Present', 'Late', 'Half Day', 'Absent', 'Leave'),
      defaultValue: 'Present'
    },
    checkInLatitude: { type: DataTypes.DECIMAL(9, 6), allowNull: true },
    checkInLongitude: { type: DataTypes.DECIMAL(9, 6), allowNull: true },
    checkInAddress: { type: DataTypes.TEXT, allowNull: true },
    checkInFaceScore: { type: DataTypes.DECIMAL(5, 2), allowNull: true },
    checkInGpsAccuracy: { type: DataTypes.DECIMAL(5, 2), allowNull: true },
    checkInDevice: { type: DataTypes.STRING, allowNull: true },
    checkInBrowser: { type: DataTypes.STRING, allowNull: true },
    checkInIpAddress: { type: DataTypes.STRING, allowNull: true },
    checkInNetwork: { type: DataTypes.STRING, allowNull: true },
    checkOutLatitude: { type: DataTypes.DECIMAL(9, 6), allowNull: true },
    checkOutLongitude: { type: DataTypes.DECIMAL(9, 6), allowNull: true },
    checkOutAddress: { type: DataTypes.TEXT, allowNull: true },
    checkOutFaceScore: { type: DataTypes.DECIMAL(5, 2), allowNull: true },
    checkOutGpsAccuracy: { type: DataTypes.DECIMAL(5, 2), allowNull: true },
    checkOutDevice: { type: DataTypes.STRING, allowNull: true },
    checkOutBrowser: { type: DataTypes.STRING, allowNull: true },
    checkOutIpAddress: { type: DataTypes.STRING, allowNull: true },
    checkOutNetwork: { type: DataTypes.STRING, allowNull: true },
    manualEntry: { type: DataTypes.BOOLEAN, defaultValue: false },
    manualReason: { type: DataTypes.TEXT, allowNull: true },
    approvedBy: { type: DataTypes.STRING, allowNull: true },
    auditId: { type: DataTypes.INTEGER, allowNull: true },
    projectId: { type: DataTypes.INTEGER, allowNull: true },
    checkInGpsDistance: { type: DataTypes.DECIMAL(10, 2), allowNull: true },
    checkOutGpsDistance: { type: DataTypes.DECIMAL(10, 2), allowNull: true },
    attendanceStatus: { type: DataTypes.STRING, allowNull: true },
    adminApprovalStatus: { type: DataTypes.ENUM('Pending', 'Approved', 'Rejected'), allowNull: true },
    overrideReason: { type: DataTypes.TEXT, allowNull: true },
    overrideRemarks: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'attendance', timestamps: true, underscored: true });

  // 8. Task Model
  const Task = sequelize.define('Task', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    title: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    priority: {
      type: DataTypes.ENUM('Low', 'Medium', 'High', 'Critical'),
      defaultValue: 'Medium'
    },
    dueDate: { type: DataTypes.DATEONLY, allowNull: true },
    status: {
      type: DataTypes.ENUM('Pending', 'In Progress', 'Review', 'Completed'),
      defaultValue: 'Pending'
    },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'tasks', timestamps: true, underscored: true });

  // 9. SiteVisit Model
  const SiteVisit = sequelize.define('SiteVisit', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    gpsLocation: { type: DataTypes.STRING, allowNull: false },
    notes: { type: DataTypes.TEXT, allowNull: true },
    photoUrls: { type: DataTypes.TEXT, allowNull: true }, // Store as JSON string
    voiceNoteUrl: { type: DataTypes.STRING, allowNull: true },
    signatureUrl: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'site_visits', timestamps: true, underscored: true });

  // 10. Drawing Model
  const Drawing = sequelize.define('Drawing', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    drawingNumber: { type: DataTypes.STRING, allowNull: true },
    title: { type: DataTypes.STRING, allowNull: false },
    version: { type: DataTypes.STRING, defaultValue: '1.0' },
    type: {
      type: DataTypes.ENUM('Floor Plans', 'Elevations', 'Structural Drawings', 'Electrical Drawings', 'Plumbing Drawings', 'Interior Drawings'),
      allowNull: false
    },
    fileUrl: { type: DataTypes.STRING, allowNull: false },
    status: {
      type: DataTypes.ENUM('Pending', 'Approved', 'Rejected'),
      defaultValue: 'Pending'
    },
    assignedArchitectId: { type: DataTypes.INTEGER, allowNull: true },
    completionPercentage: { type: DataTypes.INTEGER, defaultValue: 0 },
    approvalStatus: { type: DataTypes.STRING, defaultValue: 'Pending' },
    uploadDate: { type: DataTypes.DATEONLY, allowNull: true },
    lastUpdated: { type: DataTypes.DATEONLY, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'drawings', timestamps: true, underscored: true });

  // 11. Document Model
  const Document = sequelize.define('Document', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    title: { type: DataTypes.STRING, allowNull: false },
    folder: { type: DataTypes.STRING, defaultValue: 'General' },
    fileUrl: { type: DataTypes.STRING, allowNull: false },
    fileSize: { type: DataTypes.INTEGER, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'documents', timestamps: true, underscored: true });

  // 12. Quotation Model
  const Quotation = sequelize.define('Quotation', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    quotationNumber: { type: DataTypes.STRING, unique: true, allowNull: false },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    taxRate: { type: DataTypes.DECIMAL(5, 2), defaultValue: 18.00 },
    discount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    subtotal: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    total: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    status: {
      type: DataTypes.ENUM('Draft', 'Sent', 'Approved', 'Declined'),
      defaultValue: 'Draft'
    },
    items: { type: DataTypes.TEXT, allowNull: false }, // JSON string
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'quotations', timestamps: true, underscored: true });

  // 13. Invoice Model
  const Invoice = sequelize.define('Invoice', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    invoiceNumber: { type: DataTypes.STRING, unique: true, allowNull: false },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    dueDate: { type: DataTypes.DATEONLY, allowNull: true },
    taxRate: { type: DataTypes.DECIMAL(5, 2), defaultValue: 18.00 },
    discount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    subtotal: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    total: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    paidAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    status: {
      type: DataTypes.ENUM('Draft', 'Sent', 'Paid', 'Overdue'),
      defaultValue: 'Draft'
    },
    items: { type: DataTypes.TEXT, allowNull: false }, // JSON string
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'invoices', timestamps: true, underscored: true });

  // 14. Expense Model
  const Expense = sequelize.define('Expense', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    category: {
      type: DataTypes.ENUM('Site Expenses', 'Material Expenses', 'Labour Expenses', 'Travel Expenses'),
      allowNull: false
    },
    description: { type: DataTypes.TEXT, allowNull: true },
    receiptUrl: { type: DataTypes.STRING, allowNull: true },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    status: {
      type: DataTypes.ENUM('Pending', 'Approved', 'Rejected'),
      defaultValue: 'Pending'
    },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'expenses', timestamps: true, underscored: true });

  // 15. Notification Model
  const Notification = sequelize.define('Notification', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    title: { type: DataTypes.STRING, allowNull: false },
    message: { type: DataTypes.TEXT, allowNull: false },
    readStatus: { type: DataTypes.BOOLEAN, defaultValue: false },
    type: { type: DataTypes.STRING, defaultValue: 'General' }
  }, { tableName: 'notifications', timestamps: true, underscored: true });

  // 16. Company Settings Model
  const CompanySettings = sequelize.define('CompanySettings', {
    id: { type: DataTypes.INTEGER, primaryKey: true, defaultValue: 1 },
    companyName: { type: DataTypes.STRING, allowNull: false },
    logoUrl: { type: DataTypes.STRING, allowNull: true },
    address: { type: DataTypes.TEXT, allowNull: true },
    gst: { type: DataTypes.STRING(15), allowNull: true },
    email: { type: DataTypes.STRING, allowNull: true },
    phone: { type: DataTypes.STRING, allowNull: true },
    cloudinaryCloudName: { type: DataTypes.STRING, allowNull: true },
    cloudinaryApiKey: { type: DataTypes.STRING, allowNull: true },
    cloudinaryApiSecret: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'company_settings', timestamps: true, underscored: true });

  // 17. Worker Model
  const Worker = sequelize.define('Worker', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    workerId: { type: DataTypes.STRING, unique: true, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    mobile: { type: DataTypes.STRING, allowNull: true },
    skillType: {
      type: DataTypes.ENUM('Mason', 'Carpenter', 'Painter', 'Electrician', 'Plumber', 'Tile Worker', 'Welder', 'Helper', 'Interior Worker'),
      allowNull: false
    },
    dailyWage: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    contractor: { type: DataTypes.STRING, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'workers', timestamps: true, underscored: true });

  // 18. ManagerAttendance Model
  const ManagerAttendance = sequelize.define('ManagerAttendance', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    status: { type: DataTypes.ENUM('Present', 'Absent', 'Half Day'), defaultValue: 'Present' },
    overtimeHours: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.00 },
    remarks: { type: DataTypes.TEXT, allowNull: true },
    entryTime: { type: DataTypes.TIME, allowNull: false },
    gpsLocation: { type: DataTypes.STRING, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'manager_attendance', timestamps: true, underscored: true });

  // 19. DailyReport Model
  const DailyReport = sequelize.define('DailyReport', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    workCategory: { type: DataTypes.STRING, allowNull: false },
    workDescription: { type: DataTypes.TEXT, allowNull: true },
    quantityCompleted: { type: DataTypes.STRING, allowNull: true },
    photoUrls: { type: DataTypes.TEXT, allowNull: true }, // JSON array string
    notes: { type: DataTypes.TEXT, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'daily_reports', timestamps: true, underscored: true });

  // 20. ProgressReport Model
  const ProgressReport = sequelize.define('ProgressReport', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    workersPresent: { type: DataTypes.INTEGER, defaultValue: 0 },
    workCompleted: { type: DataTypes.TEXT, allowNull: false },
    materialsUsed: { type: DataTypes.TEXT, allowNull: true },
    issuesFaced: { type: DataTypes.TEXT, allowNull: true },
    delays: { type: DataTypes.TEXT, allowNull: true },
    photoUrls: { type: DataTypes.TEXT, allowNull: true }, // JSON array string
    tomorrowPlan: { type: DataTypes.TEXT, allowNull: true },
    voiceNoteUrl: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'manager_progress_reports', timestamps: true, underscored: true });

  // 21. Announcement Model
  const Announcement = sequelize.define('Announcement', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    title: { type: DataTypes.STRING, allowNull: false },
    message: { type: DataTypes.TEXT, allowNull: false },
    targetRole: { type: DataTypes.STRING, defaultValue: 'All' },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'announcements', timestamps: true, underscored: true });

  // 22. Import Activity Log Model
  const ImportActivityLog = sequelize.define('ImportActivityLog', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    type: { type: DataTypes.ENUM('Import', 'Export', 'Backup', 'Restore'), allowNull: false },
    module: { type: DataTypes.STRING, allowNull: false },
    fileName: { type: DataTypes.STRING, allowNull: true },
    filePath: { type: DataTypes.STRING(500), allowNull: true },
    recordsImported: { type: DataTypes.INTEGER, defaultValue: 0 },
    recordsUpdated: { type: DataTypes.INTEGER, defaultValue: 0 },
    recordsFailed: { type: DataTypes.INTEGER, defaultValue: 0 },
    ipAddress: { type: DataTypes.STRING, allowNull: true },
    device: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'import_activity_logs', underscored: true });

  // 23. Geofence Warning Model
  const GeofenceWarning = sequelize.define('GeofenceWarning', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    currentLocation: { type: DataTypes.STRING, allowNull: true },
    timeLeftSite: { type: DataTypes.DATE, allowNull: true },
    durationOutside: { type: DataTypes.INTEGER, defaultValue: 0 },
    status: {
      type: DataTypes.ENUM('Warning Pending', 'Approved', 'Ignored', 'Fine Applied'),
      defaultValue: 'Warning Pending'
    }
  }, { tableName: 'geofence_warnings', underscored: true });

  // 24. Fine Model
  const Fine = sequelize.define('Fine', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    reason: { type: DataTypes.TEXT, allowNull: false },
    acknowledged: { type: DataTypes.BOOLEAN, defaultValue: false }
  }, { tableName: 'fines', underscored: true });

  // 25. Hourly Site Progress Model
  const HourlySiteProgress = sequelize.define('HourlySiteProgress', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    workProgress: { type: DataTypes.TEXT, allowNull: false },
    remarks: { type: DataTypes.TEXT, allowNull: true },
    completionPercentage: { type: DataTypes.INTEGER, defaultValue: 0 },
    workersPresent: { type: DataTypes.INTEGER, defaultValue: 0 },
    materialsUsed: { type: DataTypes.TEXT, allowNull: true },
    delayReason: { type: DataTypes.TEXT, allowNull: true },
    weather: { type: DataTypes.STRING, allowNull: true },
    photoUrls: { type: DataTypes.TEXT, allowNull: true } // JSON string
  }, { tableName: 'hourly_site_progress', underscored: true });

  // 26. Announcement Action Model
  const AnnouncementAction = sequelize.define('AnnouncementAction', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    acknowledged: { type: DataTypes.BOOLEAN, defaultValue: false },
    comment: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'announcement_actions', underscored: true });

  // 27. BoqItem Model
  const BoqItem = sequelize.define('BoqItem', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    itemDescription: { type: DataTypes.TEXT, allowNull: false },
    unit: { type: DataTypes.STRING, allowNull: true },
    quantity: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    rate: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    totalAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 }
  }, { tableName: 'boq_items', underscored: true });

  // 28. Material Model
  const Material = sequelize.define('Material', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    materialName: { type: DataTypes.STRING, allowNull: false },
    purchasedQuantity: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    usedQuantity: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    balanceStock: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    materialCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 }
  }, { tableName: 'materials', underscored: true });

  // 29. ProjectPayment Model
  const ProjectPayment = sequelize.define('ProjectPayment', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    paymentDate: { type: DataTypes.DATEONLY, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    paidAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    pendingAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    paymentType: { type: DataTypes.STRING, allowNull: false }, // Client Payment or Vendor Payment
    expenseCategory: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'project_payments', underscored: true });

  // 30. Vendor Model
  const Vendor = sequelize.define('Vendor', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    name: { type: DataTypes.STRING, allowNull: false },
    phone: { type: DataTypes.STRING, allowNull: true },
    email: { type: DataTypes.STRING, allowNull: true },
    address: { type: DataTypes.TEXT, allowNull: true },
    gstNumber: { type: DataTypes.STRING(15), allowNull: true }
  }, { tableName: 'vendors', underscored: true });

  const Contractor = sequelize.define('Contractor', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    contractorId: { type: DataTypes.STRING, unique: true, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    phone: { type: DataTypes.STRING, allowNull: true },
    email: { type: DataTypes.STRING, allowNull: true },
    address: { type: DataTypes.TEXT, allowNull: true },
    serviceType: { type: DataTypes.STRING, allowNull: true },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'contractors', underscored: true });

  // 31a. ContractorPaymentStage Model (Admin/Superadmin managed master list of stages)
  const ContractorPaymentStage = sequelize.define('ContractorPaymentStage', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    name: { type: DataTypes.STRING, unique: true, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'contractor_payment_stages', underscored: true });

  // 31b. ContractorPaymentRelease Model (Payments released to contractors per project and stage)
  const ContractorPaymentRelease = sequelize.define('ContractorPaymentRelease', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    releaseDate: { type: DataTypes.DATEONLY, allowNull: false },
    paymentMode: { type: DataTypes.STRING, defaultValue: 'Bank Transfer' },
    referenceNumber: { type: DataTypes.STRING, allowNull: true },
    status: { type: DataTypes.ENUM('Pending', 'Released'), defaultValue: 'Released' },
    notes: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'contractor_payment_releases', underscored: true });

  // 31c. LeadStage1 Model (Stage 1 Client Enquiry Form)
  const LeadStage1 = sequelize.define('LeadStage1', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    leadId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
    clientName: { type: DataTypes.STRING, allowNull: false },
    contactNumber: { type: DataTypes.STRING, allowNull: false },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    siteAddress: { type: DataTypes.TEXT, allowNull: false },
    nearLandmark: { type: DataTypes.STRING, allowNull: true },
    siteFacing: { type: DataTypes.STRING, allowNull: true },
    buildingType: { type: DataTypes.TEXT, allowNull: false },
    localBody: { type: DataTypes.STRING, allowNull: true },
    roadWidth: { type: DataTypes.INTEGER, allowNull: true },
    frontRoad: { type: DataTypes.INTEGER, allowNull: true },
    mainRoad: { type: DataTypes.INTEGER, allowNull: true },
    connectingRoad: { type: DataTypes.INTEGER, allowNull: true },
    siteCondition: { type: DataTypes.TEXT, allowNull: true },
    waterCondition: { type: DataTypes.TEXT, allowNull: true },
    boreDepth: { type: DataTypes.INTEGER, allowNull: true },
    ebConnection: { type: DataTypes.STRING, allowNull: true },
    ebDistance: { type: DataTypes.INTEGER, allowNull: true },
    drainage: { type: DataTypes.STRING, allowNull: true },
    undergroundSump: { type: DataTypes.BOOLEAN, defaultValue: false },
    roadToPlinth: { type: DataTypes.STRING, allowNull: true },
    siteLevel: { type: DataTypes.STRING, allowNull: true },
    carParking: { type: DataTypes.INTEGER, defaultValue: 0 },
    bikeParking: { type: DataTypes.INTEGER, defaultValue: 0 },
    waterTankCapacity: { type: DataTypes.STRING, allowNull: true },
    buildingPurpose: { type: DataTypes.STRING, allowNull: true },
    staircase: { type: DataTypes.TEXT, allowNull: true },
    terraceAccess: { type: DataTypes.STRING, allowNull: true },
    northContext: { type: DataTypes.STRING, allowNull: true },
    southContext: { type: DataTypes.STRING, allowNull: true },
    eastContext: { type: DataTypes.STRING, allowNull: true },
    westContext: { type: DataTypes.STRING, allowNull: true },
    clientRequirements: { type: DataTypes.TEXT, allowNull: true },
    siteLayoutJson: { type: DataTypes.TEXT, allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
    conceptSketchJson: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'lead_stage1', timestamps: true, underscored: true });

  // 31d. PublicEnquiryLink Model
  const PublicEnquiryLink = sequelize.define('PublicEnquiryLink', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    leadId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
    token: { type: DataTypes.STRING, allowNull: false, unique: true },
    expiryDate: { type: DataTypes.DATE, allowNull: true },
    status: { type: DataTypes.ENUM('Active', 'Inactive'), defaultValue: 'Active' },
    qrCodeData: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'public_enquiry_links', underscored: true });

  // 31e. PublicEnquirySubmission Model
  const PublicEnquirySubmission = sequelize.define('PublicEnquirySubmission', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    leadId: { type: DataTypes.INTEGER, allowNull: false },
    clientIp: { type: DataTypes.STRING, allowNull: true },
    browser: { type: DataTypes.STRING, allowNull: true },
    submissionTime: { type: DataTypes.DATE, allowNull: true },
    clientName: { type: DataTypes.STRING, allowNull: false },
    contactNumber: { type: DataTypes.STRING, allowNull: false },
    whatsappNumber: { type: DataTypes.STRING, allowNull: true },
    email: { type: DataTypes.STRING, allowNull: true },
    occupation: { type: DataTypes.STRING, allowNull: true },
    preferredContactTime: { type: DataTypes.STRING, allowNull: true },
    date: { type: DataTypes.DATEONLY, allowNull: true },
    siteAddress: { type: DataTypes.TEXT, allowNull: false },
    nearLandmark: { type: DataTypes.STRING, allowNull: true },
    village: { type: DataTypes.STRING, allowNull: true },
    taluk: { type: DataTypes.STRING, allowNull: true },
    district: { type: DataTypes.STRING, allowNull: true },
    state: { type: DataTypes.STRING, allowNull: true },
    pincode: { type: DataTypes.STRING, allowNull: true },
    roadWidth: { type: DataTypes.STRING, allowNull: true },
    buildingType: { type: DataTypes.STRING, allowNull: true },
    localAuthority: { type: DataTypes.STRING, allowNull: true },
    siteCondition: { type: DataTypes.STRING, allowNull: true },
    siteConditionOther: { type: DataTypes.STRING, allowNull: true },
    waterCondition: { type: DataTypes.STRING, allowNull: true },
    boreAvailable: { type: DataTypes.BOOLEAN, defaultValue: false },
    boreDepth: { type: DataTypes.STRING, allowNull: true },
    waterRemarks: { type: DataTypes.TEXT, allowNull: true },
    electricity: { type: DataTypes.STRING, allowNull: true },
    ebDistance: { type: DataTypes.STRING, allowNull: true },
    electricityRemarks: { type: DataTypes.TEXT, allowNull: true },
    drainage: { type: DataTypes.STRING, allowNull: true },
    drainageRemarks: { type: DataTypes.TEXT, allowNull: true },
    undergroundSump: { type: DataTypes.BOOLEAN, defaultValue: false },
    undergroundSumpRemarks: { type: DataTypes.TEXT, allowNull: true },
    roadToPlinth: { type: DataTypes.STRING, allowNull: true },
    roadToPlinthRemarks: { type: DataTypes.TEXT, allowNull: true },
    siteLevel: { type: DataTypes.STRING, allowNull: true },
    siteLevelRemarks: { type: DataTypes.TEXT, allowNull: true },
    parkingCars: { type: DataTypes.INTEGER, defaultValue: 0 },
    parkingBikes: { type: DataTypes.INTEGER, defaultValue: 0 },
    parkingRemarks: { type: DataTypes.TEXT, allowNull: true },
    waterTankCapacity: { type: DataTypes.STRING, allowNull: true },
    buildingPurpose: { type: DataTypes.STRING, allowNull: true },
    staircase: { type: DataTypes.STRING, allowNull: true },
    terraceAccess: { type: DataTypes.STRING, allowNull: true },
    siteFacing: { type: DataTypes.STRING, allowNull: true },
    frontRoadWidth: { type: DataTypes.STRING, allowNull: true },
    mainRoadWidth: { type: DataTypes.STRING, allowNull: true },
    connectingRoadWidth: { type: DataTypes.STRING, allowNull: true },
    waterLevel: { type: DataTypes.STRING, allowNull: true },
    northContextType: { type: DataTypes.STRING, allowNull: true },
    southContextType: { type: DataTypes.STRING, allowNull: true },
    eastContextType: { type: DataTypes.STRING, allowNull: true },
    westContextType: { type: DataTypes.STRING, allowNull: true },
    latitude: { type: DataTypes.STRING, allowNull: true },
    longitude: { type: DataTypes.STRING, allowNull: true },
    northContext: { type: DataTypes.TEXT, allowNull: true },
    southContext: { type: DataTypes.TEXT, allowNull: true },
    eastContext: { type: DataTypes.TEXT, allowNull: true },
    westContext: { type: DataTypes.TEXT, allowNull: true },
    clientRequirements: { type: DataTypes.TEXT, allowNull: true },
    conceptSketchJson: { type: DataTypes.TEXT, allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
    confirmFullName: { type: DataTypes.STRING, allowNull: true },
    relationship: { type: DataTypes.STRING, allowNull: true },
    status: { type: DataTypes.ENUM('New', 'In Review', 'Approved', 'Rejected', 'Converted'), defaultValue: 'New' }
  }, { tableName: 'public_enquiry_submissions', underscored: true });

  // 31f. PublicEnquiryDocument Model
  const PublicEnquiryDocument = sequelize.define('PublicEnquiryDocument', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    submissionId: { type: DataTypes.INTEGER, allowNull: true },
    leadId: { type: DataTypes.INTEGER, allowNull: false },
    fileType: { type: DataTypes.STRING, allowNull: false },
    fileName: { type: DataTypes.STRING, allowNull: false },
    fileUrl: { type: DataTypes.TEXT, allowNull: false },
    fileSize: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'public_enquiry_documents', underscored: true });

  // 31g. PublicEnquiryHistory Model
  const PublicEnquiryHistory = sequelize.define('PublicEnquiryHistory', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    leadId: { type: DataTypes.INTEGER, allowNull: false },
    action: { type: DataTypes.STRING, allowNull: false },
    notes: { type: DataTypes.TEXT, allowNull: true },
    clientIp: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'public_enquiry_history', underscored: true });

  // 31h. PublicEnquiryDraft Model
  const PublicEnquiryDraft = sequelize.define('PublicEnquiryDraft', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    token: { type: DataTypes.STRING, allowNull: false, unique: true },
    draftData: { type: DataTypes.TEXT, allowNull: false },
    lastSaved: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
  }, { tableName: 'public_enquiry_drafts', underscored: true });

  // 31i. PublicEnquiryNote Model
  const PublicEnquiryNote = sequelize.define('PublicEnquiryNote', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    submissionId: { type: DataTypes.INTEGER, allowNull: false },
    author: { type: DataTypes.STRING, allowNull: false },
    noteText: { type: DataTypes.TEXT, allowNull: false }
  }, { tableName: 'public_enquiry_notes', underscored: true });



  // 32. DrawingProgress Model
  const DrawingProgress = sequelize.define('DrawingProgress', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    currentStatus: { type: DataTypes.STRING, defaultValue: 'Pending' },
    pendingWork: { type: DataTypes.TEXT, allowNull: true },
    revisionHistory: { type: DataTypes.TEXT, allowNull: true },
    completionPercentage: { type: DataTypes.INTEGER, defaultValue: 0 }
  }, { tableName: 'drawing_progress', underscored: true });

  // 33. AnnualTarget Model
  const AnnualTarget = sequelize.define('AnnualTarget', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    financialYear: { type: DataTypes.STRING, unique: true, allowNull: false },
    annualProjectTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    annualRevenueTarget: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    annualProfitTarget: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    residentialProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    commercialProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    interiorProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    renovationProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    newClientTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    repeatClientTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    isApproved: { type: DataTypes.BOOLEAN, defaultValue: false }
  }, { tableName: 'annual_targets', underscored: true });

  // 34. MonthlyTarget Model
  const MonthlyTarget = sequelize.define('MonthlyTarget', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    monthName: { type: DataTypes.STRING, allowNull: false },
    monthNumber: { type: DataTypes.INTEGER, allowNull: false },
    projectTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    revenueTarget: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    profitTarget: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    residentialProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    commercialProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    interiorProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    renovationProjectsTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    newClientTarget: { type: DataTypes.INTEGER, defaultValue: 0 },
    repeatClientTarget: { type: DataTypes.INTEGER, defaultValue: 0 }
  }, { tableName: 'monthly_targets', underscored: true });

  // 35. TeamTarget Model
  const TeamTarget = sequelize.define('TeamTarget', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    financialYear: { type: DataTypes.STRING, allowNull: false },
    teamName: { type: DataTypes.STRING, allowNull: false },
    targetMetric: { type: DataTypes.STRING, allowNull: false },
    targetValue: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    unit: { type: DataTypes.STRING, defaultValue: 'number' },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'team_targets', underscored: true });

  // 36. EmployeeTarget Model
  const EmployeeTarget = sequelize.define('EmployeeTarget', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    targetDescription: { type: DataTypes.TEXT, allowNull: false },
    targetMetric: { type: DataTypes.STRING, allowNull: false },
    targetValue: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    currentValue: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    period: { type: DataTypes.STRING, defaultValue: 'Monthly' },
    startDate: { type: DataTypes.DATEONLY, allowNull: false },
    endDate: { type: DataTypes.DATEONLY, allowNull: false },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'employee_targets', underscored: true });

  // 37. BuildHistory Model
  const BuildHistory = sequelize.define('BuildHistory', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    versionName: { type: DataTypes.STRING, allowNull: false },
    buildNumber: { type: DataTypes.INTEGER, allowNull: false },
    platform: { type: DataTypes.STRING, allowNull: false },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' },
    duration: { type: DataTypes.INTEGER, defaultValue: 0 },
    fileName: { type: DataTypes.STRING, allowNull: true },
    fileSize: { type: DataTypes.INTEGER, defaultValue: 0 },
    sha256Checksum: { type: DataTypes.STRING, allowNull: true },
    releaseNotes: { type: DataTypes.TEXT, allowNull: true },
    logsPath: { type: DataTypes.STRING, allowNull: true },
    artifactPath: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'build_history', underscored: true });

  // 38. SigningConfig Model
  const SigningConfig = sequelize.define('SigningConfig', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    platform: { type: DataTypes.STRING, unique: true, allowNull: false },
    keystoreFile: { type: DataTypes.STRING, allowNull: true },
    keystoreAlias: { type: DataTypes.STRING, allowNull: true },
    keystorePassword: { type: DataTypes.STRING, allowNull: true },
    keyPassword: { type: DataTypes.STRING, allowNull: true },
    certificateFile: { type: DataTypes.STRING, allowNull: true },
    provisioningProfile: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'signing_configs', underscored: true });



  // 40. Estimate Model
  const Estimate = sequelize.define('Estimate', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    estimateNumber: { type: DataTypes.STRING, unique: true, allowNull: false },
    projectName: { type: DataTypes.STRING, allowNull: false },
    clientName: { type: DataTypes.STRING, allowNull: false },
    projectType: { type: DataTypes.STRING, allowNull: false },
    constructionType: { type: DataTypes.STRING, allowNull: false },
    state: { type: DataTypes.STRING, allowNull: false },
    district: { type: DataTypes.STRING, allowNull: false },
    city: { type: DataTypes.STRING, allowNull: false },
    siteAddress: { type: DataTypes.TEXT, allowNull: true },
    builtUpArea: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    unit: { type: DataTypes.STRING, allowNull: false },
    selectedPackage: { type: DataTypes.STRING, allowNull: false },
    packageRate: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    totalCost: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    companyMarginPercentage: { type: DataTypes.DECIMAL(5, 2), allowNull: false },
    estimatedProfit: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    gstPercentage: { type: DataTypes.DECIMAL(5, 2), defaultValue: 18.00 },
    gstAmount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    netProjectValue: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' },
    complexityScore: { type: DataTypes.STRING, allowNull: true },
    structuralComplexity: { type: DataTypes.STRING, allowNull: true },
    finishingQuality: { type: DataTypes.STRING, allowNull: true },
    drawingDetails: { type: DataTypes.TEXT, allowNull: true },
    confidenceMetrics: { type: DataTypes.TEXT, allowNull: true },
    similarProjectsData: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'estimates', underscored: true });

  // 41. EstimateMaterial Model
  const EstimateMaterial = sequelize.define('EstimateMaterial', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    materialName: { type: DataTypes.STRING, allowNull: false },
    quantity: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    unit: { type: DataTypes.STRING, allowNull: true },
    rate: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    cost: { type: DataTypes.DECIMAL(15, 2), allowNull: false }
  }, { tableName: 'estimate_materials', underscored: true });

  // 42. EstimatePhase Model
  const EstimatePhase = sequelize.define('EstimatePhase', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    phaseName: { type: DataTypes.STRING, allowNull: false },
    estimatedCost: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    estimatedDuration: { type: DataTypes.INTEGER, allowNull: false },
    completionPercentage: { type: DataTypes.INTEGER, defaultValue: 0 },
    budgetAllocation: { type: DataTypes.DECIMAL(15, 2), allowNull: false }
  }, { tableName: 'estimate_phases', underscored: true });

  // 43. EstimateBoq Model
  const EstimateBoq = sequelize.define('EstimateBoq', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    materialName: { type: DataTypes.STRING, allowNull: false },
    unit: { type: DataTypes.STRING, allowNull: true },
    quantity: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    rate: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    gstRate: { type: DataTypes.DECIMAL(5, 2), defaultValue: 18.00 },
    gstAmount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    totalAmount: { type: DataTypes.DECIMAL(15, 2), allowNull: false }
  }, { tableName: 'estimate_boqs', underscored: true });

  // 44. EstimateLabour Model
  const EstimateLabour = sequelize.define('EstimateLabour', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    labourType: { type: DataTypes.STRING, allowNull: false },
    requiredWorkers: { type: DataTypes.INTEGER, allowNull: false },
    estimatedDays: { type: DataTypes.INTEGER, allowNull: false },
    estimatedCost: { type: DataTypes.DECIMAL(15, 2), allowNull: false }
  }, { tableName: 'estimate_labours', underscored: true });

  // 45. EstimationSetting Model
  const EstimationSetting = sequelize.define('EstimationSetting', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    economyRate: { type: DataTypes.DECIMAL(15, 2), defaultValue: 2200.00 },
    standardRate: { type: DataTypes.DECIMAL(15, 2), defaultValue: 2500.00 },
    premiumRate: { type: DataTypes.DECIMAL(15, 2), defaultValue: 2800.00 },
    profitMarginPercentage: { type: DataTypes.DECIMAL(5, 2), defaultValue: 15.00 },
    gstPercentage: { type: DataTypes.DECIMAL(5, 2), defaultValue: 18.00 },
    materialsFormula: { type: DataTypes.TEXT, allowNull: true },
    labourFormula: { type: DataTypes.TEXT, allowNull: true },
    timelineFormula: { type: DataTypes.TEXT, allowNull: true },
    districtAdjustments: { type: DataTypes.TEXT, allowNull: true },
    regionalCostIndex: { type: DataTypes.DECIMAL(5, 2), defaultValue: 1.00 },
    companyOverhead: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    civilLabourRate: { type: DataTypes.DECIMAL(15, 2), defaultValue: 450.00 }
  }, { tableName: 'estimation_settings', underscored: true });

  // 46. MarketPrice Model
  const MarketPrice = sequelize.define('MarketPrice', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    materialName: { type: DataTypes.STRING, allowNull: false },
    currentRate: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
    previousRate: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    supplier: { type: DataTypes.STRING, allowNull: true },
    district: { type: DataTypes.STRING, allowNull: false }
  }, { tableName: 'market_prices', underscored: true });

  // 47. BuildVersion Model
  const BuildVersion = sequelize.define('BuildVersion', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    versionName: { type: DataTypes.STRING, allowNull: false },
    buildNumber: { type: DataTypes.INTEGER, allowNull: false },
    releaseNotes: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'build_versions', underscored: true });

  // 48. Build Model
  const Build = sequelize.define('Build', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    versionId: { type: DataTypes.INTEGER, allowNull: true },
    platform: { type: DataTypes.STRING, allowNull: false },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' },
    startedAt: { type: DataTypes.DATE, allowNull: true },
    finishedAt: { type: DataTypes.DATE, allowNull: true },
    duration: { type: DataTypes.INTEGER, defaultValue: 0 },
    builtBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'builds', underscored: true });

  // 49. BuildLog Model
  const BuildLog = sequelize.define('BuildLog', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    buildId: { type: DataTypes.INTEGER, allowNull: false },
    logFilePath: { type: DataTypes.STRING, allowNull: false }
  }, { tableName: 'build_logs', underscored: true });

  // 50. BuildArtifact Model
  const BuildArtifact = sequelize.define('BuildArtifact', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    buildId: { type: DataTypes.INTEGER, allowNull: false },
    fileName: { type: DataTypes.STRING, allowNull: false },
    filePath: { type: DataTypes.STRING, allowNull: false },
    fileSize: { type: DataTypes.BIGINT, defaultValue: 0 },
    sha256Checksum: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'build_artifacts', underscored: true });

  // 51. AiSetting Model
  const AiSetting = sequelize.define('AiSetting', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    geminiApiKey: { type: DataTypes.STRING, allowNull: true },
    aiModel: { type: DataTypes.STRING, defaultValue: 'gemini-1.5-flash' },
    temperature: { type: DataTypes.DECIMAL(3, 2), defaultValue: 0.2 },
    maxTokens: { type: DataTypes.INTEGER, defaultValue: 2048 },
    timeout: { type: DataTypes.INTEGER, defaultValue: 30000 },
    enableAi: { type: DataTypes.BOOLEAN, defaultValue: true },
    enablePdfAnalysis: { type: DataTypes.BOOLEAN, defaultValue: true },
    enableImageAnalysis: { type: DataTypes.BOOLEAN, defaultValue: true },
    enableBoqGeneration: { type: DataTypes.BOOLEAN, defaultValue: true },
    enableCostEstimation: { type: DataTypes.BOOLEAN, defaultValue: true },
    apiUsageCount: { type: DataTypes.INTEGER, defaultValue: 0 },
    dailyTokenUsage: { type: DataTypes.INTEGER, defaultValue: 0 }
  }, { tableName: 'ai_settings', underscored: true });

  // 52. ProjectStage Model
  const ProjectStage = sequelize.define('ProjectStage', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    name: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    estimatedStart: { type: DataTypes.DATEONLY, allowNull: true },
    estimatedEnd: { type: DataTypes.DATEONLY, allowNull: true },
    actualStart: { type: DataTypes.DATEONLY, allowNull: true },
    actualEnd: { type: DataTypes.DATEONLY, allowNull: true },
    estimatedCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    actualCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    labourCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    materialCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    completionPercentage: { type: DataTypes.INTEGER, defaultValue: 0 },
    priority: { type: DataTypes.STRING, defaultValue: 'Medium' },
    remarks: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' }, // Pending, In Progress, Completed, Approved
    order: { type: DataTypes.INTEGER, defaultValue: 0 },
    paymentPercentage: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.00 },
    paymentStatus: { type: DataTypes.STRING, defaultValue: 'Pending' }, // Pending, Partially Paid, Paid, Overdue
    paymentDueDate: { type: DataTypes.DATEONLY, allowNull: true },
    paymentAmountPaid: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    paymentInvoiceUrl: { type: DataTypes.STRING, allowNull: true },
    paymentReceiptUrl: { type: DataTypes.STRING, allowNull: true },
    approvalStatus: { type: DataTypes.STRING, defaultValue: 'Pending' }, // Pending, Engineer, Site Manager, Architect, MD, Approved
    isArchived: { type: DataTypes.BOOLEAN, defaultValue: false }
  }, { tableName: 'project_stages', underscored: true });

  // 53. StageTask Model
  const StageTask = sequelize.define('StageTask', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    title: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' }, // Pending, In Progress, Completed
    dueDate: { type: DataTypes.DATEONLY, allowNull: true }
  }, { tableName: 'stage_tasks', underscored: true });

  // 54. StageMaterial Model
  const StageMaterial = sequelize.define('StageMaterial', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    materialName: { type: DataTypes.STRING, allowNull: false },
    requiredQty: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    issuedQty: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    usedQty: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    balanceStock: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    supplier: { type: DataTypes.STRING, allowNull: true },
    purchaseCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 }
  }, { tableName: 'stage_materials', underscored: true });

  // 55. StageLabour Model
  const StageLabour = sequelize.define('StageLabour', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    workerName: { type: DataTypes.STRING, allowNull: false },
    skillType: { type: DataTypes.STRING, allowNull: true },
    contractorName: { type: DataTypes.STRING, allowNull: true },
    attendanceStatus: { type: DataTypes.STRING, defaultValue: 'Present' },
    overtimeHours: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.00 },
    dailyCost: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 }
  }, { tableName: 'stage_labours', underscored: true });

  // 56. StagePayment Model
  const StagePayment = sequelize.define('StagePayment', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    amount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    paidAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    pendingAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
    dueDate: { type: DataTypes.DATEONLY, allowNull: true },
    status: { type: DataTypes.STRING, defaultValue: 'Pending' },
    invoiceUrl: { type: DataTypes.STRING, allowNull: true },
    receiptUrl: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'stage_payments', underscored: true });

  // 57. StageDocument Model
  const StageDocument = sequelize.define('StageDocument', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    name: { type: DataTypes.STRING, allowNull: false },
    fileUrl: { type: DataTypes.STRING(500), allowNull: false },
    fileType: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'stage_documents', underscored: true });

  // 58. StagePhoto Model
  const StagePhoto = sequelize.define('StagePhoto', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    url: { type: DataTypes.STRING(500), allowNull: false },
    type: { type: DataTypes.STRING, defaultValue: 'Photo' }, // Photo or Video
    uploadedAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
  }, { tableName: 'stage_photos', underscored: true });

  // 59. StageReport Model
  const StageReport = sequelize.define('StageReport', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    reportType: { type: DataTypes.STRING, defaultValue: 'Daily' }, // Daily or Hourly
    description: { type: DataTypes.TEXT, allowNull: false },
    workersPresentCount: { type: DataTypes.INTEGER, defaultValue: 0 },
    materialsUsedInfo: { type: DataTypes.TEXT, allowNull: true },
    problemsEncountered: { type: DataTypes.TEXT, allowNull: true },
    weather: { type: DataTypes.STRING, allowNull: true },
    nextDayPlan: { type: DataTypes.TEXT, allowNull: true },
    gpsCoordinates: { type: DataTypes.STRING, allowNull: true },
    photoUrls: { type: DataTypes.TEXT, allowNull: true } // JSON string
  }, { tableName: 'stage_reports', underscored: true });

  // 60. StageApproval Model
  const StageApproval = sequelize.define('StageApproval', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    role: { type: DataTypes.STRING, allowNull: false }, // Engineer, Site Manager, Senior Architect, MD
    status: { type: DataTypes.STRING, defaultValue: 'Pending' }, // Pending, Approved, Rejected
    comments: { type: DataTypes.TEXT, allowNull: true },
    signatureUrl: { type: DataTypes.STRING, allowNull: true },
    approvedAt: { type: DataTypes.DATE, allowNull: true }
  }, { tableName: 'stage_approvals', underscored: true });

  // 61. StageHistory Model
  const StageHistory = sequelize.define('StageHistory', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    action: { type: DataTypes.STRING, allowNull: false },
    notes: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'stage_histories', underscored: true });

  // 62. AuditLog Model
  const AuditLog = sequelize.define('AuditLog', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    userId: { type: DataTypes.INTEGER, allowNull: true },
    userName: { type: DataTypes.STRING, allowNull: true },
    role: { type: DataTypes.STRING, allowNull: true },
    action: { type: DataTypes.STRING, allowNull: false },
    module: { type: DataTypes.STRING, allowNull: false },
    oldValue: { type: DataTypes.TEXT, allowNull: true },
    newValue: { type: DataTypes.TEXT, allowNull: true },
    ipAddress: { type: DataTypes.STRING, allowNull: true },
    device: { type: DataTypes.STRING, allowNull: true }
  }, { tableName: 'audit_logs', underscored: true });

  // --- SET UP ASSOCIATIONS ---
  
  // User <-> Session
  User.hasMany(Session, { foreignKey: 'userId', as: 'sessions', onDelete: 'CASCADE' });
  Session.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // User <-> AuditLog
  User.hasMany(AuditLog, { foreignKey: 'userId', as: 'auditLogs', onDelete: 'SET NULL' });
  AuditLog.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // User (Assigned) <-> Lead
  User.hasMany(Lead, { foreignKey: 'assignedTo', as: 'leads', onDelete: 'SET NULL' });
  Lead.belongsTo(User, { foreignKey: 'assignedTo', as: 'assignee' });

  // Lead <-> LeadTimeline
  Lead.hasMany(LeadTimeline, { foreignKey: 'leadId', as: 'timeline', onDelete: 'CASCADE' });
  LeadTimeline.belongsTo(Lead, { foreignKey: 'leadId', as: 'lead' });

  // User (Creator) <-> LeadTimeline
  User.hasMany(LeadTimeline, { foreignKey: 'createdBy', as: 'timelineEntries', onDelete: 'SET NULL' });
  LeadTimeline.belongsTo(User, { foreignKey: 'createdBy', as: 'creator' });

  // Lead <-> LeadStage1
  Lead.hasOne(LeadStage1, { foreignKey: 'leadId', as: 'stage1', onDelete: 'CASCADE' });
  LeadStage1.belongsTo(Lead, { foreignKey: 'leadId', as: 'lead' });

  // Lead <-> PublicEnquiryLink
  Lead.hasOne(PublicEnquiryLink, { foreignKey: 'leadId', as: 'enquiryLink', onDelete: 'CASCADE' });
  PublicEnquiryLink.belongsTo(Lead, { foreignKey: 'leadId', as: 'lead' });

  // Lead <-> PublicEnquirySubmission
  Lead.hasMany(PublicEnquirySubmission, { foreignKey: 'leadId', as: 'enquirySubmissions', onDelete: 'CASCADE' });
  PublicEnquirySubmission.belongsTo(Lead, { foreignKey: 'leadId', as: 'lead' });

  // Lead <-> PublicEnquiryDocument
  Lead.hasMany(PublicEnquiryDocument, { foreignKey: 'leadId', as: 'enquiryDocuments', onDelete: 'CASCADE' });
  PublicEnquiryDocument.belongsTo(Lead, { foreignKey: 'leadId', as: 'lead' });

  // PublicEnquirySubmission <-> PublicEnquiryDocument
  PublicEnquirySubmission.hasMany(PublicEnquiryDocument, { foreignKey: 'submissionId', as: 'documents', onDelete: 'SET NULL' });
  PublicEnquiryDocument.belongsTo(PublicEnquirySubmission, { foreignKey: 'submissionId', as: 'submission' });

  // PublicEnquirySubmission <-> PublicEnquiryNote
  PublicEnquirySubmission.hasMany(PublicEnquiryNote, { foreignKey: 'submissionId', as: 'submissionNotes', onDelete: 'CASCADE' });
  PublicEnquiryNote.belongsTo(PublicEnquirySubmission, { foreignKey: 'submissionId', as: 'submission' });

  // User (Creator/Updater) <-> LeadStage1
  User.hasMany(LeadStage1, { foreignKey: 'createdBy', as: 'createdStage1Forms', onDelete: 'SET NULL' });
  LeadStage1.belongsTo(User, { foreignKey: 'createdBy', as: 'creator' });
  User.hasMany(LeadStage1, { foreignKey: 'updatedBy', as: 'updatedStage1Forms', onDelete: 'SET NULL' });
  LeadStage1.belongsTo(User, { foreignKey: 'updatedBy', as: 'updater' });

  // User (Client Role) <-> Client
  User.hasOne(Client, { foreignKey: 'userId', as: 'clientProfile', onDelete: 'SET NULL' });
  Client.belongsTo(User, { foreignKey: 'userId', as: 'userAccount' });

  // Client <-> Project
  Client.hasMany(Project, { foreignKey: 'clientId', as: 'projects', onDelete: 'CASCADE' });
  Project.belongsTo(Client, { foreignKey: 'clientId', as: 'client' });

  // Client <-> ClientTimeline
  Client.hasMany(ClientTimeline, { foreignKey: 'clientId', as: 'timeline', onDelete: 'CASCADE' });
  ClientTimeline.belongsTo(Client, { foreignKey: 'clientId', as: 'client' });
  User.hasMany(ClientTimeline, { foreignKey: 'performedBy', as: 'clientTimelineEntries', onDelete: 'SET NULL' });
  ClientTimeline.belongsTo(User, { foreignKey: 'performedBy', as: 'performer' });

  // User (Assigned Employee) <-> Client
  User.hasMany(Client, { foreignKey: 'assignedTo', as: 'clients', onDelete: 'SET NULL' });
  Client.belongsTo(User, { foreignKey: 'assignedTo', as: 'assignee' });

  // User (Architect) <-> Project
  User.hasMany(Project, { foreignKey: 'architectId', as: 'architectedProjects', onDelete: 'SET NULL' });
  Project.belongsTo(User, { foreignKey: 'architectId', as: 'architect' });

  // User (Site Engineer) <-> Project
  User.hasMany(Project, { foreignKey: 'siteEngineerId', as: 'engineeredProjects', onDelete: 'SET NULL' });
  Project.belongsTo(User, { foreignKey: 'siteEngineerId', as: 'siteEngineer' });

  // User (Managing Director) <-> Project
  User.hasMany(Project, { foreignKey: 'managingDirectorId', as: 'managedProjects', onDelete: 'SET NULL' });
  Project.belongsTo(User, { foreignKey: 'managingDirectorId', as: 'managingDirector' });

  // User (Design Engineer) <-> Project
  User.hasMany(Project, { foreignKey: 'designEngineerId', as: 'designedProjects', onDelete: 'SET NULL' });
  Project.belongsTo(User, { foreignKey: 'designEngineerId', as: 'designEngineer' });

  // User (Site Supervisor) <-> Project
  User.hasMany(Project, { foreignKey: 'supervisorId', as: 'supervisedProjects', onDelete: 'SET NULL' });
  Project.belongsTo(User, { foreignKey: 'supervisorId', as: 'supervisor' });

  // User <-> Attendance
  User.hasMany(Attendance, { foreignKey: 'userId', as: 'attendanceRecords', onDelete: 'CASCADE' });
  Attendance.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Project <-> Attendance
  Project.hasMany(Attendance, { foreignKey: 'projectId', as: 'attendanceRecords', onDelete: 'SET NULL' });
  Attendance.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Project <-> Task
  Project.hasMany(Task, { foreignKey: 'projectId', as: 'tasks', onDelete: 'CASCADE' });
  Task.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User <-> Task
  User.hasMany(Task, { foreignKey: 'assignedTo', as: 'tasks', onDelete: 'SET NULL' });
  Task.belongsTo(User, { foreignKey: 'assignedTo', as: 'assignee' });

  // Project <-> SiteVisit
  Project.hasMany(SiteVisit, { foreignKey: 'projectId', as: 'siteVisits', onDelete: 'CASCADE' });
  SiteVisit.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User <-> SiteVisit
  User.hasMany(SiteVisit, { foreignKey: 'userId', as: 'siteVisits', onDelete: 'CASCADE' });
  SiteVisit.belongsTo(User, { foreignKey: 'userId', as: 'visitor' });

  // Project <-> Drawing
  Project.hasMany(Drawing, { foreignKey: 'projectId', as: 'drawings', onDelete: 'CASCADE' });
  Drawing.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User (Approver) <-> Drawing
  User.hasMany(Drawing, { foreignKey: 'approvedBy', as: 'approvedDrawings', onDelete: 'SET NULL' });
  Drawing.belongsTo(User, { foreignKey: 'approvedBy', as: 'approver' });

  // Project <-> Document
  Project.hasMany(Document, { foreignKey: 'projectId', as: 'documents', onDelete: 'CASCADE' });
  Document.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Project <-> Quotation
  Project.hasMany(Quotation, { foreignKey: 'projectId', as: 'quotations', onDelete: 'CASCADE' });
  Quotation.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Project <-> Invoice
  Project.hasMany(Invoice, { foreignKey: 'projectId', as: 'invoices', onDelete: 'CASCADE' });
  Invoice.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Project <-> Expense
  Project.hasMany(Expense, { foreignKey: 'projectId', as: 'expenses', onDelete: 'SET NULL' });
  Expense.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User <-> Expense
  User.hasMany(Expense, { foreignKey: 'userId', as: 'expenses', onDelete: 'CASCADE' });
  Expense.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // User <-> Notification
  User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications', onDelete: 'CASCADE' });
  Notification.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Project <-> Worker
  Project.hasMany(Worker, { foreignKey: 'projectId', as: 'workers', onDelete: 'SET NULL' });
  Worker.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Worker <-> ManagerAttendance
  Worker.hasMany(ManagerAttendance, { foreignKey: 'workerId', as: 'attendanceRecords', onDelete: 'CASCADE' });
  ManagerAttendance.belongsTo(Worker, { foreignKey: 'workerId', as: 'worker' });

  // User (Manager) <-> ManagerAttendance
  User.hasMany(ManagerAttendance, { foreignKey: 'managerId', as: 'markedAttendance', onDelete: 'CASCADE' });
  ManagerAttendance.belongsTo(User, { foreignKey: 'managerId', as: 'manager' });

  // Project <-> DailyReport
  Project.hasMany(DailyReport, { foreignKey: 'projectId', as: 'dailyReports', onDelete: 'CASCADE' });
  DailyReport.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User <-> DailyReport
  User.hasMany(DailyReport, { foreignKey: 'userId', as: 'dailyReports', onDelete: 'CASCADE' });
  DailyReport.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Project <-> ProgressReport
  Project.hasMany(ProgressReport, { foreignKey: 'projectId', as: 'progressReports', onDelete: 'CASCADE' });
  ProgressReport.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User (Manager) <-> ProgressReport
  User.hasMany(ProgressReport, { foreignKey: 'managerId', as: 'progressReports', onDelete: 'CASCADE' });
  ProgressReport.belongsTo(User, { foreignKey: 'managerId', as: 'manager' });

  // User (Creator) <-> Announcement
  User.hasMany(Announcement, { foreignKey: 'createdBy', as: 'announcements', onDelete: 'SET NULL' });
  Announcement.belongsTo(User, { foreignKey: 'creator' });

  // User <-> ImportActivityLog
  User.hasMany(ImportActivityLog, { foreignKey: 'userId', as: 'importLogs', onDelete: 'SET NULL' });
  ImportActivityLog.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // User <-> GeofenceWarning
  User.hasMany(GeofenceWarning, { foreignKey: 'userId', as: 'geofenceWarnings', onDelete: 'CASCADE' });
  GeofenceWarning.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Project <-> GeofenceWarning
  Project.hasMany(GeofenceWarning, { foreignKey: 'projectId', as: 'geofenceWarnings', onDelete: 'CASCADE' });
  GeofenceWarning.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // GeofenceWarning <-> Fine
  GeofenceWarning.hasMany(Fine, { foreignKey: 'warningId', as: 'fines', onDelete: 'SET NULL' });
  Fine.belongsTo(GeofenceWarning, { foreignKey: 'warningId', as: 'warning' });

  // User <-> Fine
  User.hasMany(Fine, { foreignKey: 'employeeId', as: 'fines', onDelete: 'CASCADE' });
  Fine.belongsTo(User, { foreignKey: 'employeeId', as: 'employee' });

  // Project <-> HourlySiteProgress
  Project.hasMany(HourlySiteProgress, { foreignKey: 'projectId', as: 'hourlySiteProgressRecords', onDelete: 'CASCADE' });
  HourlySiteProgress.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // User <-> HourlySiteProgress
  User.hasMany(HourlySiteProgress, { foreignKey: 'userId', as: 'hourlySiteProgressRecords', onDelete: 'CASCADE' });
  HourlySiteProgress.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Announcement <-> AnnouncementAction
  Announcement.hasMany(AnnouncementAction, { foreignKey: 'announcementId', as: 'actions', onDelete: 'CASCADE' });
  AnnouncementAction.belongsTo(Announcement, { foreignKey: 'announcementId', as: 'announcement' });

  // User <-> AnnouncementAction
  User.hasMany(AnnouncementAction, { foreignKey: 'userId', as: 'announcementActions', onDelete: 'CASCADE' });
  AnnouncementAction.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Project <-> BoqItem
  Project.hasMany(BoqItem, { foreignKey: 'projectId', as: 'boqs', onDelete: 'CASCADE' });
  BoqItem.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Project <-> Material
  Project.hasMany(Material, { foreignKey: 'projectId', as: 'materials', onDelete: 'CASCADE' });
  Material.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Project <-> ProjectPayment
  Project.hasMany(ProjectPayment, { foreignKey: 'projectId', as: 'payments', onDelete: 'CASCADE' });
  ProjectPayment.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Drawing <-> DrawingProgress
  Drawing.hasMany(DrawingProgress, { foreignKey: 'drawingId', as: 'progressList', onDelete: 'CASCADE' });
  DrawingProgress.belongsTo(Drawing, { foreignKey: 'drawingId', as: 'drawing' });

  // User <-> DrawingProgress (Assigned Employee)
  User.hasMany(DrawingProgress, { foreignKey: 'assignedEmployeeId', as: 'assignedDrawingProgress', onDelete: 'SET NULL' });
  DrawingProgress.belongsTo(User, { foreignKey: 'assignedEmployeeId', as: 'assignedEmployee' });

  // User <-> Drawing (Assigned Architect)
  User.hasMany(Drawing, { foreignKey: 'assignedArchitectId', as: 'assignedDrawings', onDelete: 'SET NULL' });
  Drawing.belongsTo(User, { foreignKey: 'assignedArchitectId', as: 'assignedArchitect' });

  // AnnualTarget <-> MonthlyTarget
  AnnualTarget.hasMany(MonthlyTarget, { foreignKey: 'annualTargetId', as: 'monthlyTargets', onDelete: 'CASCADE' });
  MonthlyTarget.belongsTo(AnnualTarget, { foreignKey: 'annualTargetId', as: 'annualTarget' });

  // User (Approver) <-> AnnualTarget
  User.hasMany(AnnualTarget, { foreignKey: 'approvedBy', as: 'approvedAnnualTargets', onDelete: 'SET NULL' });
  AnnualTarget.belongsTo(User, { foreignKey: 'approvedBy', as: 'approver' });

  // User (Employee) <-> EmployeeTarget
  User.hasMany(EmployeeTarget, { foreignKey: 'employeeId', as: 'assignedTargets', onDelete: 'CASCADE' });
  EmployeeTarget.belongsTo(User, { foreignKey: 'employeeId', as: 'employee' });

  // User (Assigner) <-> EmployeeTarget
  User.hasMany(EmployeeTarget, { foreignKey: 'assignedBy', as: 'createdEmployeeTargets', onDelete: 'CASCADE' });
  EmployeeTarget.belongsTo(User, { foreignKey: 'assignedBy', as: 'assigner' });

  // User (Builder) <-> BuildHistory
  User.hasMany(BuildHistory, { foreignKey: 'builtBy', as: 'builds', onDelete: 'SET NULL' });
  BuildHistory.belongsTo(User, { foreignKey: 'builtBy', as: 'builder' });

  // Estimate <-> EstimateMaterial
  Estimate.hasMany(EstimateMaterial, { foreignKey: 'estimateId', as: 'materials', onDelete: 'CASCADE' });
  EstimateMaterial.belongsTo(Estimate, { foreignKey: 'estimateId', as: 'estimate' });

  // Estimate <-> EstimatePhase
  Estimate.hasMany(EstimatePhase, { foreignKey: 'estimateId', as: 'phases', onDelete: 'CASCADE' });
  EstimatePhase.belongsTo(Estimate, { foreignKey: 'estimateId', as: 'estimate' });

  // Estimate <-> EstimateBoq
  Estimate.hasMany(EstimateBoq, { foreignKey: 'estimateId', as: 'boqs', onDelete: 'CASCADE' });
  EstimateBoq.belongsTo(Estimate, { foreignKey: 'estimateId', as: 'estimate' });

  // Estimate <-> EstimateLabour
  Estimate.hasMany(EstimateLabour, { foreignKey: 'estimateId', as: 'labours', onDelete: 'CASCADE' });
  EstimateLabour.belongsTo(Estimate, { foreignKey: 'estimateId', as: 'estimate' });

  // User (Approver) <-> Estimate
  User.hasMany(Estimate, { foreignKey: 'approvedBy', as: 'approvedEstimates', onDelete: 'SET NULL' });
  Estimate.belongsTo(User, { foreignKey: 'approvedBy', as: 'approver' });

  // User (Creator) <-> Estimate
  User.hasMany(Estimate, { foreignKey: 'createdBy', as: 'createdEstimates', onDelete: 'SET NULL' });
  Estimate.belongsTo(User, { foreignKey: 'createdBy', as: 'creator' });

  // Project <-> Estimate
  Project.hasMany(Estimate, { foreignKey: 'projectId', as: 'estimates', onDelete: 'SET NULL' });
  Estimate.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // Contractor <-> ContractorPaymentRelease
  Contractor.hasMany(ContractorPaymentRelease, { foreignKey: 'contractorId', as: 'releases', onDelete: 'CASCADE' });
  ContractorPaymentRelease.belongsTo(Contractor, { foreignKey: 'contractorId', as: 'contractor', onDelete: 'CASCADE' });

  // Project <-> ContractorPaymentRelease
  Project.hasMany(ContractorPaymentRelease, { foreignKey: 'projectId', as: 'contractorReleases', onDelete: 'CASCADE' });
  ContractorPaymentRelease.belongsTo(Project, { foreignKey: 'projectId', as: 'project', onDelete: 'CASCADE' });

  // ContractorPaymentStage <-> ContractorPaymentRelease
  ContractorPaymentStage.hasMany(ContractorPaymentRelease, { foreignKey: 'stageId', as: 'releases', onDelete: 'CASCADE' });
  ContractorPaymentRelease.belongsTo(ContractorPaymentStage, { foreignKey: 'stageId', as: 'stage', onDelete: 'CASCADE' });


  // BuildVersion <-> Build
  BuildVersion.hasMany(Build, { foreignKey: 'versionId', as: 'builds', onDelete: 'SET NULL' });
  Build.belongsTo(BuildVersion, { foreignKey: 'versionId', as: 'version' });

  // User (Builder) <-> Build
  User.hasMany(Build, { foreignKey: 'builtBy', as: 'buildsList', onDelete: 'SET NULL' });
  Build.belongsTo(User, { foreignKey: 'builtBy', as: 'builder' });

  // Build <-> BuildLog
  Build.hasMany(BuildLog, { foreignKey: 'buildId', as: 'logs', onDelete: 'CASCADE' });
  BuildLog.belongsTo(Build, { foreignKey: 'buildId', as: 'build' });

  // Build <-> BuildArtifact
  Build.hasMany(BuildArtifact, { foreignKey: 'buildId', as: 'artifacts', onDelete: 'CASCADE' });
  BuildArtifact.belongsTo(Build, { foreignKey: 'buildId', as: 'build' });

  // Project <-> ProjectStage
  Project.hasMany(ProjectStage, { foreignKey: 'projectId', as: 'stages', onDelete: 'CASCADE' });
  ProjectStage.belongsTo(Project, { foreignKey: 'projectId', as: 'project' });

  // ProjectStage <-> StageTask
  ProjectStage.hasMany(StageTask, { foreignKey: 'stageId', as: 'tasks', onDelete: 'CASCADE' });
  StageTask.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StageMaterial
  ProjectStage.hasMany(StageMaterial, { foreignKey: 'stageId', as: 'materials', onDelete: 'CASCADE' });
  StageMaterial.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StageLabour
  ProjectStage.hasMany(StageLabour, { foreignKey: 'stageId', as: 'labours', onDelete: 'CASCADE' });
  StageLabour.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StagePayment
  ProjectStage.hasMany(StagePayment, { foreignKey: 'stageId', as: 'payments', onDelete: 'CASCADE' });
  StagePayment.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StageDocument
  ProjectStage.hasMany(StageDocument, { foreignKey: 'stageId', as: 'documents', onDelete: 'CASCADE' });
  StageDocument.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StagePhoto
  ProjectStage.hasMany(StagePhoto, { foreignKey: 'stageId', as: 'photos', onDelete: 'CASCADE' });
  StagePhoto.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StageReport
  ProjectStage.hasMany(StageReport, { foreignKey: 'stageId', as: 'reports', onDelete: 'CASCADE' });
  StageReport.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StageApproval
  ProjectStage.hasMany(StageApproval, { foreignKey: 'stageId', as: 'approvals', onDelete: 'CASCADE' });
  StageApproval.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> StageHistory
  ProjectStage.hasMany(StageHistory, { foreignKey: 'stageId', as: 'history', onDelete: 'CASCADE' });
  StageHistory.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage' });

  // ProjectStage <-> User (Assigned Roles)
  ProjectStage.belongsTo(User, { foreignKey: 'assignedEngineerId', as: 'assignedEngineer' });
  ProjectStage.belongsTo(User, { foreignKey: 'assignedArchitectId', as: 'assignedArchitect' });
  ProjectStage.belongsTo(User, { foreignKey: 'assignedSiteManagerId', as: 'assignedSiteManager' });
  ProjectStage.belongsTo(ProjectStage, { foreignKey: 'dependencyStageId', as: 'dependency' });

  // StageApproval <-> User (Approver)
  StageApproval.belongsTo(User, { foreignKey: 'approvedById', as: 'approver' });

  // StageHistory <-> User (Creator)
  StageHistory.belongsTo(User, { foreignKey: 'createdById', as: 'creator' });

  // 54. ConferenceCall Model
  const ConferenceCall = sequelize.define('ConferenceCall', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    type: {
      type: DataTypes.ENUM('Morning Call', 'Evening Call'),
      defaultValue: 'Morning Call',
      allowNull: false
    },
    date: { type: DataTypes.DATEONLY, allowNull: false },
    durationMinutes: { type: DataTypes.INTEGER, defaultValue: 15 },
    notes: { type: DataTypes.TEXT, allowNull: true },
    loggedById: { type: DataTypes.INTEGER, allowNull: true },
    participants: { type: DataTypes.TEXT, allowNull: true } // JSON string of attendees
  }, { tableName: 'conference_calls', underscored: true });

  ConferenceCall.belongsTo(User, { foreignKey: 'loggedById', as: 'logger' });

  // 55. Incentive Model
  const Incentive = sequelize.define('Incentive', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    month: { type: DataTypes.STRING(10), allowNull: false }, // YYYY-MM
    attendanceScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    callsScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    tasksScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    photosScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    reportsScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    totalScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    originalSuggestedAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.0 },
    suggestedAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.0 },
    finalAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.0 },
    penaltyAmount: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.0 },
    status: {
      type: DataTypes.STRING(30),
      defaultValue: 'Draft'
    },
    remarks: { type: DataTypes.TEXT, allowNull: true },
    adminRemarks: { type: DataTypes.TEXT, allowNull: true },
    superAdminRemarks: { type: DataTypes.TEXT, allowNull: true },
    reviewTimeline: { type: DataTypes.TEXT, allowNull: true }, // JSON array of logs
    locked: { type: DataTypes.BOOLEAN, defaultValue: false },
    approvedById: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'incentives', underscored: true });

  Incentive.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  Incentive.belongsTo(User, { foreignKey: 'approvedById', as: 'approver' });

  // 56. StageChecklist Model
  const StageChecklist = sequelize.define('StageChecklist', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    stageId: { type: DataTypes.INTEGER, allowNull: false },
    parentId: { type: DataTypes.INTEGER, allowNull: true },
    title: { type: DataTypes.STRING(150), allowNull: false },
    status: { type: DataTypes.ENUM('Pending', 'Completed'), defaultValue: 'Pending' },
    completionPercentage: { type: DataTypes.INTEGER, defaultValue: 0 },
    sequenceOrder: { type: DataTypes.INTEGER, defaultValue: 0 },
    deletedAt: { type: DataTypes.DATE, allowNull: true },
    deletedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'stage_checklists', underscored: true });

  StageChecklist.belongsTo(ProjectStage, { foreignKey: 'stageId', as: 'stage', onDelete: 'CASCADE' });
  ProjectStage.hasMany(StageChecklist, { foreignKey: 'stageId', as: 'checklists', onDelete: 'CASCADE' });
  StageChecklist.belongsTo(StageChecklist, { foreignKey: 'parentId', as: 'parent', onDelete: 'CASCADE' });
  StageChecklist.hasMany(StageChecklist, { foreignKey: 'parentId', as: 'children', onDelete: 'CASCADE' });

  // 57. ConferenceCallAction Model
  const ConferenceCallAction = sequelize.define('ConferenceCallAction', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    callId: { type: DataTypes.INTEGER, allowNull: false },
    taskDescription: { type: DataTypes.TEXT, allowNull: false },
    assignedTo: { type: DataTypes.INTEGER, allowNull: false },
    dueDate: { type: DataTypes.DATEONLY, allowNull: false },
    status: { type: DataTypes.ENUM('Pending', 'Completed'), defaultValue: 'Pending' }
  }, { tableName: 'conference_call_actions', underscored: true });

  ConferenceCallAction.belongsTo(ConferenceCall, { foreignKey: 'callId', as: 'call', onDelete: 'CASCADE' });
  ConferenceCall.hasMany(ConferenceCallAction, { foreignKey: 'callId', as: 'actions', onDelete: 'CASCADE' });
  ConferenceCallAction.belongsTo(User, { foreignKey: 'assignedTo', as: 'assignee', onDelete: 'CASCADE' });

  // 58. DrawingRevision Model
  const DrawingRevision = sequelize.define('DrawingRevision', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    drawingId: { type: DataTypes.INTEGER, allowNull: false },
    revisionNumber: { type: DataTypes.STRING(20), allowNull: false },
    fileUrl: { type: DataTypes.STRING(255), allowNull: false },
    pdfPreviewUrl: { type: DataTypes.STRING(255), allowNull: false },
    comments: { type: DataTypes.TEXT, allowNull: true },
    uploadedBy: { type: DataTypes.INTEGER, allowNull: false }
  }, { tableName: 'drawing_revisions', underscored: true });

  DrawingRevision.belongsTo(Drawing, { foreignKey: 'drawingId', as: 'drawing', onDelete: 'CASCADE' });
  Drawing.hasMany(DrawingRevision, { foreignKey: 'drawingId', as: 'revisions', onDelete: 'CASCADE' });
  DrawingRevision.belongsTo(User, { foreignKey: 'uploadedBy', as: 'uploader', onDelete: 'CASCADE' });

  // 59. DrawingComment Model
  const DrawingComment = sequelize.define('DrawingComment', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    drawingId: { type: DataTypes.INTEGER, allowNull: false },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    comment: { type: DataTypes.TEXT, allowNull: false }
  }, { tableName: 'drawing_comments', underscored: true });

  DrawingComment.belongsTo(Drawing, { foreignKey: 'drawingId', as: 'drawing', onDelete: 'CASCADE' });
  Drawing.hasMany(DrawingComment, { foreignKey: 'drawingId', as: 'comments', onDelete: 'CASCADE' });
  DrawingComment.belongsTo(User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });

  // 60. MonthlyAttendanceLock Model
  const MonthlyAttendanceLock = sequelize.define('MonthlyAttendanceLock', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    month: { type: DataTypes.STRING(7), allowNull: false, unique: true },
    locked: { type: DataTypes.BOOLEAN, defaultValue: false },
    lockedBy: { type: DataTypes.INTEGER, allowNull: true }
  }, { tableName: 'monthly_attendance_locks', underscored: true });

  MonthlyAttendanceLock.belongsTo(User, { foreignKey: 'lockedBy', as: 'locker', onDelete: 'SET NULL' });

  // 61. EmployeeFace Model
  const EmployeeFace = sequelize.define('EmployeeFace', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    frontFaceUrl: { type: DataTypes.TEXT, allowNull: true },
    leftFaceUrl: { type: DataTypes.TEXT, allowNull: true },
    rightFaceUrl: { type: DataTypes.TEXT, allowNull: true },
    smileFaceUrl: { type: DataTypes.TEXT, allowNull: true },
    faceEmbeddings: { type: DataTypes.TEXT, allowNull: true },
    qualityScore: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0.0 },
    capturedBy: { type: DataTypes.STRING, allowNull: true },
    status: { type: DataTypes.ENUM('Active', 'Archived'), defaultValue: 'Active' }
  }, { tableName: 'employee_faces', underscored: true });

  EmployeeFace.belongsTo(User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });

  // 62. EmployeeFaceAudit Model
  const EmployeeFaceAudit = sequelize.define('EmployeeFaceAudit', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    action: { type: DataTypes.STRING(50), allowNull: false },
    performedBy: { type: DataTypes.STRING(100), allowNull: false },
    timestamp: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
    remarks: { type: DataTypes.TEXT, allowNull: true },
    changes: { type: DataTypes.TEXT, allowNull: true }
  }, { tableName: 'employee_face_audits', underscored: true });

  EmployeeFaceAudit.belongsTo(User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });

  return {
    User, Session, Lead, LeadTimeline, LeadStage1, Client, ClientTimeline, Project,
    Attendance, Task, SiteVisit, Drawing, Document,
    Quotation, Invoice, Expense, Notification, CompanySettings,
    Worker, ManagerAttendance, DailyReport, ProgressReport, Announcement, ImportActivityLog,
    GeofenceWarning, Fine, HourlySiteProgress, AnnouncementAction,
    BoqItem, Material, ProjectPayment, Vendor, Contractor, ContractorPaymentStage, ContractorPaymentRelease, DrawingProgress,
    AnnualTarget, MonthlyTarget, TeamTarget, EmployeeTarget,
    BuildHistory, SigningConfig,
    Estimate, EstimateMaterial, EstimatePhase, EstimateBoq, EstimateLabour, EstimationSetting, MarketPrice,
    BuildVersion, Build, BuildLog, BuildArtifact, AiSetting,
    ProjectStage, StageTask, StageMaterial, StageLabour, StagePayment, StageDocument, StagePhoto, StageReport, StageApproval, StageHistory,
    PublicEnquiryLink, PublicEnquirySubmission, PublicEnquiryDocument, PublicEnquiryHistory, PublicEnquiryDraft, PublicEnquiryNote,
    AuditLog,
    ConferenceCall, Incentive,
    StageChecklist, ConferenceCallAction, DrawingRevision, DrawingComment,
    MonthlyAttendanceLock, EmployeeFace, EmployeeFaceAudit
  };
}

module.exports = {
  initModels
};
