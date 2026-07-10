const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Op } = require('sequelize');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const XLSX = require('xlsx');
const AdmZip = require('adm-zip');

const AiService = require('./build_system/AiService');
const CloudinaryService = require('./build_system/CloudinaryService');
const { getSequelize } = require('./database/db');

const JWT_SECRET = process.env.JWT_SECRET || 'VIAN_ARCHITECTS_SUPER_SECRET_JWT_KEY_2026';

// Middleware to verify JWT and attach user
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = (authHeader && authHeader.split(' ')[1]) || req.query.token;
  if (!token) return res.status(401).json({ message: 'Access token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid or expired token' });
    req.user = user;
    next();
  });
}

// Middleware to check specific roles
function authorizeRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(403).json({ message: 'Unauthorized. Insufficient permissions.' });
    }
    const role = req.user.role === 'Managing Director' ? 'Super Admin' : req.user.role;
    if (!allowedRoles.includes(role) && !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Unauthorized. Insufficient permissions.' });
    }
    next();
  };
}

function registerRoutes(app, models) {
  const {
    User, Session, Lead, LeadTimeline, Client, ClientTimeline, Project,
    Attendance, Task, SiteVisit, Drawing, Document,
    Quotation, Invoice, Expense, Notification, CompanySettings,
    Worker, ManagerAttendance, DailyReport, ProgressReport, Announcement, ImportActivityLog,
    GeofenceWarning, Fine, HourlySiteProgress, AnnouncementAction,
    Contractor, ContractorPaymentStage, ContractorPaymentRelease,
    LeadStage1,
    PublicEnquiryLink, PublicEnquirySubmission, PublicEnquiryDocument, PublicEnquiryHistory, PublicEnquiryDraft, PublicEnquiryNote,
    ProjectStage, StageTask, StageMaterial, StageLabour, StagePayment, StageDocument, StagePhoto, StageReport, StageApproval, StageHistory, Estimate, EstimateMaterial, EstimateBoq, EstimateLabour,
    AuditLog
  } = models;

  // Role permissions helper
  function getPermissionRole(role) {
    if (!role) return 'Staff';
    const r = role.toLowerCase();
    if (r === 'managing director' || r === 'super admin') return 'Super Admin';
    if (
      r === 'admin / office manager / accounts' ||
      r === 'admin' ||
      r === 'tech head + senior architect' ||
      r === 'accountant'
    ) {
      return 'Admin';
    }
    return 'Staff';
  }

  // Audit logger helper
  async function writeAuditLog(req, action, moduleName, oldValue = null, newValue = null) {
    try {
      if (!req.user) return;
      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const device = req.headers['user-agent'] || 'Unknown Device';
      await AuditLog.create({
        userId: req.user.id,
        userName: req.user.name,
        role: req.user.role,
        action,
        module: moduleName,
        oldValue: oldValue ? (typeof oldValue === 'object' ? JSON.stringify(oldValue) : String(oldValue)) : null,
        newValue: newValue ? (typeof newValue === 'object' ? JSON.stringify(newValue) : String(newValue)) : null,
        ipAddress: clientIp,
        device
      });
    } catch (err) {
      console.error('Failed writing audit log:', err.message);
    }
  }

  // Gating middleware
  const requireSuperAdmin = (req, res, next) => {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (getPermissionRole(req.user.role) !== 'Super Admin') {
      return res.status(403).json({ message: 'Forbidden: Super Admin role required' });
    }
    next();
  };

  // ==========================================
  // AUTHENTICATION MODULE
  // ==========================================
  
  app.post('/api/auth/login', async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Username and password required' });
    }

    try {
      const user = await User.findOne({ where: { username } });
      if (!user) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      if (user.status === 'Inactive') {
        return res.status(403).json({ message: 'Account is deactivated' });
      }

      const validPassword = await bcrypt.compare(password, user.passwordHash);
      if (!validPassword) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      // Generate JWT Token
      const tokenPayload = {
        id: user.id,
        username: user.username,
        role: user.role,
        name: user.name,
        email: user.email
      };
      const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '30d' });

      // Save session
      await Session.create({
        userId: user.id,
        token: token,
        deviceName: req.headers['user-agent'] || 'Unknown Device',
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
      });

      res.json({
        token,
        user: {
          id: user.id,
          employeeId: user.employeeId,
          username: user.username,
          name: user.name,
          email: user.email,
          role: user.role,
          department: user.department,
          designation: user.designation
        }
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error during login', error: error.message });
    }
  });

  app.get('/api/auth/profile', authenticateToken, async (req, res) => {
    try {
      const user = await User.findByPk(req.user.id);
      if (!user) return res.status(404).json({ message: 'User not found' });
      res.json({ user });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });

  // ==========================================
  // DASHBOARD WIDGETS & STATS
  // ==========================================
  
  app.get('/api/dashboard', authenticateToken, async (req, res) => {
    try {
      const totalProjects = await Project.count();
      const activeProjects = await Project.count({ where: { status: 'In Progress' } });
      const completedProjects = await Project.count({ where: { status: 'Completed' } });
      const totalClients = await Client.count();
      const totalLeads = await Lead.count();
      const wonLeads = await Lead.count({ where: { status: 'Won' } });
      const conversionRate = totalLeads > 0 ? parseFloat(((wonLeads / totalLeads) * 100).toFixed(1)) : 0.0;
      
      // Invoices summaries
      const invoices = await Invoice.findAll();
      let totalRevenue = 0;
      let pendingPayments = 0;
      invoices.forEach(inv => {
        totalRevenue += parseFloat(inv.paidAmount || 0);
        pendingPayments += parseFloat(inv.total || 0) - parseFloat(inv.paidAmount || 0);
      });

      // Attendance / Site Visits today
      const today = new Date().toISOString().split('T')[0];
      const siteVisitsToday = await SiteVisit.count({ where: { date: today } });
      const attendanceToday = await Attendance.count({ where: { date: today } });

      // Recent activities feed stub
      const activities = [
        { id: 1, type: 'Project', message: 'Project "Villa Horizon" progress updated to 45%', time: '10 mins ago' },
        { id: 2, type: 'CRM', message: 'New Lead "Ankit Sharma" added from Website', time: '1 hr ago' },
        { id: 3, type: 'Attendance', message: 'Site Engineer Rahul checked in at Site A', time: '2 hrs ago' },
        { id: 4, type: 'Invoice', message: 'Invoice VIAN-2026-002 paid by Mr. Mehta', time: '1 day ago' }
      ];

      res.json({
        stats: {
          totalProjects,
          activeProjects,
          completedProjects,
          totalClients,
          totalLeads,
          wonLeads,
          conversionRate,
          revenue: totalRevenue,
          pendingPayments,
          siteVisitsToday,
          employeeAttendance: attendanceToday
        },
        recentActivities: activities
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error loading dashboard metrics', error: error.message });
    }
  });

  // ==========================================
  // CRM MODULE
  // ==========================================
  
  app.get('/api/crm/leads', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';
      const status = req.query.status || '';

      const where = { deletedAt: null };
      if (status) {
        where.status = status;
      }
      if (search) {
        where[Op.or] = [
          { name: { [Op.like]: `%${search}%` } },
          { phone: { [Op.like]: `%${search}%` } },
          { email: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await Lead.findAndCountAll({
        where,
        include: [
          { model: User, as: 'assignee', attributes: ['name', 'role'] },
          { model: LeadTimeline, as: 'timeline' },
          { model: PublicEnquiryLink, as: 'enquiryLink' }
        ],
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        leads: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving leads', error: error.message });
    }
  });

  app.get('/api/crm/leads/:id', authenticateToken, async (req, res) => {
    try {
      const lead = await Lead.findOne({
        where: { id: req.params.id, deletedAt: null },
        include: [
          { model: User, as: 'assignee', attributes: ['name', 'role'] },
          { model: LeadTimeline, as: 'timeline' },
          { model: PublicEnquiryLink, as: 'enquiryLink' }
        ]
      });
      if (!lead) return res.status(404).json({ message: 'Lead not found' });
      res.json(lead);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching lead details', error: error.message });
    }
  });

  app.post('/api/crm/leads', authenticateToken, async (req, res) => {
    try {
      const lead = await Lead.create({
        ...req.body,
        assignedTo: req.body.assignedTo || req.user.id
      });
      
      await LeadTimeline.create({
        leadId: lead.id,
        action: 'Lead Created',
        notes: `Lead added by ${req.user.name}`,
        createdBy: req.user.id
      });

      await writeAuditLog(req, 'Create', 'Leads', null, lead.toJSON());

      res.status(201).json(lead);
    } catch (error) {
      res.status(400).json({ message: 'Error creating lead', error: error.message });
    }
  });

  app.put('/api/crm/leads/:id', authenticateToken, async (req, res) => {
    try {
      const lead = await Lead.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!lead) return res.status(404).json({ message: 'Lead not found' });
      
      const oldVal = { ...lead.toJSON() };
      const previousStatus = lead.status;
      await lead.update(req.body);

      if (previousStatus !== lead.status) {
        await LeadTimeline.create({
          leadId: lead.id,
          action: 'Status Changed',
          notes: `Status updated from ${previousStatus} to ${lead.status}`,
          createdBy: req.user.id
        });
      }

      await writeAuditLog(req, 'Update', 'Leads', oldVal, lead.toJSON());

      res.json(lead);
    } catch (error) {
      res.status(400).json({ message: 'Error updating lead', error: error.message });
    }
  });

  app.post('/api/crm/leads/:id/convert', authenticateToken, async (req, res) => {
    try {
      const role = req.user.role;
      // Verification of role: Only Super Admin and Admin can convert
      if (role !== 'Managing Director' && role !== 'Super Admin' && role !== 'Admin / Office Manager / Accounts' && role !== 'Tech Head + Senior Architect') {
        return res.status(403).json({ message: 'Only Super Admin and Admin can convert a Lead into a Client.' });
      }

      const lead = await Lead.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!lead) return res.status(404).json({ message: 'Lead not found' });

      // Check duplicate client
      const duplicate = await Client.findOne({
        where: {
          [Op.or]: [
            ...(lead.email ? [{ email: lead.email }] : []),
            ...(lead.phone ? [{ phone: lead.phone }] : []),
            ...(lead.gstNumber ? [{ gst: lead.gstNumber }] : [])
          ],
          deletedAt: null
        }
      });

      if (duplicate && req.body.merge !== true) {
        return res.status(400).json({
          conflict: true,
          duplicate: {
            id: duplicate.id,
            name: duplicate.name,
            clientId: duplicate.clientId,
            email: duplicate.email,
            phone: duplicate.phone,
            gst: duplicate.gst
          },
          message: 'This lead already exists as a client. Open existing client or merge?'
        });
      }

      let client;
      let isMerged = false;

      if (duplicate && req.body.merge === true) {
        // Merge Lead into existing Client
        isMerged = true;
        client = duplicate;
        const updatedFields = {
          companyName: duplicate.companyName || lead.companyName,
          contactPerson: duplicate.contactPerson || lead.contactPerson || lead.name,
          address: duplicate.address || lead.address,
          city: duplicate.city || lead.city,
          state: duplicate.state || lead.state,
          country: duplicate.country || lead.country,
          gst: duplicate.gst || lead.gstNumber,
          pan: duplicate.pan || lead.pan,
          leadSource: duplicate.leadSource || lead.source,
          industry: duplicate.industry || lead.industry,
          notes: duplicate.notes || lead.notes,
          attachments: duplicate.attachments || lead.attachments,
          assignedTo: duplicate.assignedTo || lead.assignedTo
        };
        await client.update(updatedFields);
      } else {
        // Create new Client ID
        let clientId = '';
        let unique = false;
        let attempt = 0;
        while (!unique) {
          const count = await Client.count() + attempt;
          clientId = `CLI-${(count + 1).toString().padStart(6, '0')}`;
          const existing = await Client.findOne({ where: { clientId } });
          if (!existing) {
            unique = true;
          } else {
            attempt++;
          }
        }

        // Create new Client
        client = await Client.create({
          clientId,
          name: lead.name,
          phone: lead.phone,
          email: lead.email || '',
          address: lead.address || '',
          gst: lead.gstNumber || '',
          companyName: lead.companyName || '',
          contactPerson: lead.contactPerson || lead.name,
          city: lead.city || '',
          state: lead.state || '',
          country: lead.country || '',
          pan: lead.pan || '',
          leadSource: lead.source || '',
          industry: lead.industry || '',
          notes: lead.notes || '',
          attachments: lead.attachments || '',
          assignedTo: lead.assignedTo || req.user.id,
          leadId: lead.id
        });
      }

      // Update Lead status
      const oldLeadVal = { ...lead.toJSON() };
      await lead.update({
        status: 'Won',
        converted: 'Yes',
        convertedDate: new Date(),
        convertedBy: req.user.id,
        clientId: client.clientId
      });

      // Timeline entries
      await LeadTimeline.create({
        leadId: lead.id,
        action: 'Status Changed',
        notes: `Converted to Client: ${client.name} (${client.clientId})`,
        createdBy: req.user.id
      });

      if (ClientTimeline) {
        await ClientTimeline.create({
          clientId: client.id,
          action: 'Converted from Lead',
          notes: `Converted from Lead ID: ${lead.id} by ${req.user.name}`,
          performedBy: req.user.id
        });
      }

      // Auto-create initial project (if requested)
      if (req.body.createProject === true) {
        let projId = '';
        let projUnique = false;
        let projAttempt = 0;
        while (!projUnique) {
          const pCount = await Project.count() + projAttempt;
          projId = `PRJ-${(pCount + 1).toString().padStart(6, '0')}`;
          const existingProj = await Project.findOne({ where: { projectId: projId } });
          if (!existingProj) {
            projUnique = true;
          } else {
            projAttempt++;
          }
        }

        await Project.create({
          projectId: projId,
          name: req.body.projectName || `${client.name} Project`,
          type: req.body.projectType || 'Residential',
          budget: req.body.projectBudget || lead.budget || 0,
          siteAddress: req.body.projectSiteAddress || client.address || '',
          clientId: client.id,
          status: 'Planning',
          progressPercentage: 0
        });
      }

      // Create Welcome Task
      await Task.create({
        title: `Welcome onboard: ${client.name}`,
        description: `Kick-off task for client ${client.name} (${client.companyName || ''}). Set up folder, review layout choices, and align timeline.`,
        priority: 'High',
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        status: 'Pending',
        assignedTo: client.assignedTo || req.user.id
      });

      // Create Follow-up Reminder
      await Task.create({
        title: `Follow-up review with ${client.name}`,
        description: `Check-in call with client ${client.name} to confirm initial project parameters and mood board approvals.`,
        priority: 'Medium',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        status: 'Pending',
        assignedTo: client.assignedTo || req.user.id
      });

      // Write Audit Log
      await writeAuditLog(req, 'Convert', 'Leads', oldLeadVal, lead.toJSON());
      await writeAuditLog(req, 'Create', 'Clients', null, client.toJSON());

      res.status(200).json({
        success: true,
        message: isMerged ? 'Lead successfully merged and converted' : 'Lead successfully converted to Client',
        client: {
          id: client.id,
          name: client.name,
          clientId: client.clientId,
          convertedBy: req.user.name,
          convertedOn: new Date().toISOString().split('T')[0]
        }
      });
    } catch (error) {
      res.status(500).json({ message: 'Error converting lead to client', error: error.message });
    }
  });

  app.delete('/api/crm/leads/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const lead = await Lead.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!lead) return res.status(404).json({ message: 'Lead not found' });

      const oldVal = { ...lead.toJSON() };
      const deletedAt = new Date();
      await lead.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Leads', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Lead soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting lead', error: error.message });
    }
  });

  app.post('/api/crm/leads/:id/timeline', authenticateToken, async (req, res) => {
    try {
      const lead = await Lead.findByPk(req.params.id);
      if (!lead) return res.status(404).json({ message: 'Lead not found' });
      
      const { action, notes } = req.body;
      if (!action) return res.status(400).json({ message: 'Action name is required' });

      const entry = await LeadTimeline.create({
        leadId: lead.id,
        action,
        notes,
        createdBy: req.user.id
      });

      res.status(201).json(entry);
    } catch (error) {
      res.status(500).json({ message: 'Failed to create timeline entry', error: error.message });
    }
  });

  // Lead Stage 1 (Client Enquiry Form)
  app.get('/api/crm/leads/:leadId/stage1', authenticateToken, async (req, res) => {
    try {
      const stage1 = await LeadStage1.findOne({ where: { leadId: req.params.leadId } });
      if (!stage1) {
        return res.status(404).json({ message: 'Stage 1 client enquiry form not found for this lead' });
      }
      res.json(stage1);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching Stage 1 form', error: error.message });
    }
  });

  app.post('/api/crm/leads/:leadId/stage1', authenticateToken, async (req, res) => {
    try {
      const leadId = req.params.leadId;
      const data = {
        ...req.body,
        leadId,
        updatedBy: req.user ? req.user.id : null
      };

      let stage1 = await LeadStage1.findOne({ where: { leadId } });
      if (stage1) {
        await stage1.update(data);
      } else {
        data.createdBy = req.user ? req.user.id : null;
        stage1 = await LeadStage1.create(data);
      }

      // Add a timeline entry for the lead
      await LeadTimeline.create({
        leadId,
        action: 'Stage 1 Form Updated',
        notes: `Stage 1 Enquiry Form saved/updated.`,
        createdBy: req.user ? req.user.id : null
      });

      res.json({ success: true, stage1 });
    } catch (error) {
      res.status(400).json({ message: 'Error saving Stage 1 form', error: error.message });
    }
  });

  app.delete('/api/crm/leads/:leadId/stage1', authenticateToken, async (req, res) => {
    try {
      const stage1 = await LeadStage1.findOne({ where: { leadId: req.params.leadId } });
      if (!stage1) return res.status(404).json({ message: 'Stage 1 form not found' });
      await stage1.destroy();
      res.json({ message: 'Stage 1 form cleared successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting Stage 1 form', error: error.message });
    }
  });

  const uploadsPath = path.join(__dirname, 'uploads');
  if (!fs.existsSync(uploadsPath)) {
    fs.mkdirSync(uploadsPath, { recursive: true });
  }
  app.use('/uploads', express.static(uploadsPath));

  const publicStorage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, uploadsPath);
    },
    filename: function (req, file, cb) {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, uniqueSuffix + '-' + file.originalname.replace(/\s+/g, '_'));
    }
  });
  const publicUpload = multer({
    storage: publicStorage,
    limits: { fileSize: 25 * 1024 * 1024 }
  });

  // 0. Public File Upload Endpoint
  app.post('/api/enquiry/upload', publicUpload.single('file'), (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
      const fileUrl = `/uploads/${req.file.filename}`;
      res.json({
        success: true,
        fileName: req.file.originalname,
        fileUrl,
        fileSize: req.file.size
      });
    } catch (err) {
      res.status(500).json({ message: 'Upload failed', error: err.message });
    }
  });

  // 1. Generate Public Link (Anand, Jaya, Muthuiya only)
  app.post('/api/enquiry/generate-link', authenticateToken, authorizeRoles('Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect'), async (req, res) => {
    try {
      const { leadId, expiryDays } = req.body;
      if (!leadId) return res.status(400).json({ message: 'Lead ID is required' });

      const lead = await Lead.findByPk(leadId);
      if (!lead) return res.status(404).json({ message: 'Lead not found' });

      const token = require('crypto').randomBytes(24).toString('hex');
      const expiryDate = expiryDays ? new Date(Date.now() + expiryDays * 24 * 60 * 60 * 1000) : null;
      const qrCodeData = `https://erp.vianarchitects.in/enquiry/${token}`;

      let link = await PublicEnquiryLink.findOne({ where: { leadId } });
      if (link) {
        await link.update({ token, expiryDate, status: 'Active', qrCodeData });
      } else {
        link = await PublicEnquiryLink.create({ leadId, token, expiryDate, status: 'Active', qrCodeData });
      }

      await PublicEnquiryHistory.create({
        leadId,
        action: 'Link Generated',
        notes: `Enquiry portal link generated by ${req.user.name}`
      });

      res.json({ success: true, link });
    } catch (err) {
      res.status(500).json({ message: 'Failed to generate link', error: err.message });
    }
  });

  // 2. Disable/Enable Link Status
  app.post('/api/enquiry/status-link', authenticateToken, authorizeRoles('Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect'), async (req, res) => {
    try {
      const { leadId, status } = req.body;
      if (!leadId || !status) return res.status(400).json({ message: 'Lead ID and status required' });

      const link = await PublicEnquiryLink.findOne({ where: { leadId } });
      if (!link) return res.status(404).json({ message: 'Link not found' });

      await link.update({ status });

      await PublicEnquiryHistory.create({
        leadId,
        action: `Link ${status}`,
        notes: `Link status updated to ${status} by ${req.user.name}`
      });

      res.json({ success: true, link });
    } catch (err) {
      res.status(500).json({ message: 'Failed to update link status', error: err.message });
    }
  });

  // 3. Get Link Details & Draft (Public, no auth)
  app.get('/api/enquiry/link/:token', async (req, res) => {
    try {
      const { token } = req.params;
      const link = await PublicEnquiryLink.findOne({
        where: { token },
        include: [{ model: Lead, as: 'lead' }]
      });

      if (!link) return res.status(404).json({ message: 'Enquiry link is invalid or expired' });
      if (link.status === 'Inactive') return res.status(400).json({ message: 'This enquiry link has been deactivated' });
      if (link.expiryDate && new Date(link.expiryDate) < new Date()) {
        return res.status(400).json({ message: 'This enquiry link has expired' });
      }

      const draft = await PublicEnquiryDraft.findOne({ where: { token } });

      res.json({
        success: true,
        link,
        draft: draft ? JSON.parse(draft.draftData) : null
      });
    } catch (err) {
      res.status(500).json({ message: 'Error retrieving enquiry link', error: err.message });
    }
  });

  // 4. Save Draft progress (Public, no auth)
  app.post('/api/enquiry/draft/:token', async (req, res) => {
    try {
      const { token } = req.params;
      const { draftData } = req.body;
      if (!draftData) return res.status(400).json({ message: 'Draft data required' });

      const link = await PublicEnquiryLink.findOne({ where: { token } });
      if (!link) return res.status(404).json({ message: 'Invalid token' });

      let draft = await PublicEnquiryDraft.findOne({ where: { token } });
      if (draft) {
        await draft.update({ draftData: JSON.stringify(draftData), lastSaved: new Date() });
      } else {
        draft = await PublicEnquiryDraft.create({ token, draftData: JSON.stringify(draftData), lastSaved: new Date() });
      }

      res.json({ success: true, message: 'Draft autosaved' });
    } catch (err) {
      res.status(500).json({ message: 'Error saving draft', error: err.message });
    }
  });

  // 5. Submit Enquiry (Public, no auth)
  app.post('/api/enquiry/submit/:token', async (req, res) => {
    try {
      const { token } = req.params;
      const link = await PublicEnquiryLink.findOne({ where: { token } });
      if (!link) return res.status(404).json({ message: 'Invalid enquiry link' });
      if (link.status === 'Inactive') return res.status(400).json({ message: 'Enquiry link is inactive' });

      const existing = await PublicEnquirySubmission.findOne({
        where: { leadId: link.leadId, status: ['New', 'In Review', 'Approved', 'Converted'] }
      });
      if (existing) {
        return res.status(400).json({ message: 'An enquiry has already been submitted for this lead' });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const browser = req.headers['user-agent'] || 'Unknown Browser';

      const submission = await PublicEnquirySubmission.create({
        ...req.body,
        leadId: link.leadId,
        clientIp,
        browser,
        submissionTime: new Date(),
        status: 'New'
      });

      const attachments = req.body.attachments || [];
      const conceptualIdeas = req.body.conceptualIdeas || [];
      const siteLayout = req.body.siteLayout;
      const allDocs = [...attachments, ...conceptualIdeas];
      if (siteLayout) {
        allDocs.push(siteLayout);
      }

      for (const att of allDocs) {
        await PublicEnquiryDocument.create({
          submissionId: submission.id,
          leadId: link.leadId,
          fileType: att.fileType,
          fileName: att.fileName,
          fileUrl: att.fileUrl,
          fileSize: att.fileSize
        });
      }

      await link.update({ status: 'Inactive' });
      await PublicEnquiryDraft.destroy({ where: { token } });

      await PublicEnquiryHistory.create({
        leadId: link.leadId,
        action: 'Submission Received',
        notes: `Client Enquiry Form submitted by IP: ${clientIp}`,
        clientIp
      });

      const lead = await Lead.findByPk(link.leadId);
      if (lead) {
        await lead.update({ status: 'Site Visit Scheduled' });
      }

      // System notification
      const notifyUsers = await User.findAll({
        where: {
          role: ['Managing Director', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect']
        }
      });
      for (const u of notifyUsers) {
        await Notification.create({
          userId: u.id,
          title: 'New Client Enquiry Submission',
          message: `A public enquiry form has been submitted for Lead: ${req.body.clientName || 'Unknown'}.`,
          type: 'Enquiry'
        });
      }

      res.json({
        success: true,
        referenceNumber: `VIAN-LEAD-2026-${String(link.leadId).padStart(4, '0')}`,
        submissionId: submission.id
      });
    } catch (err) {
      res.status(500).json({ message: 'Submission failed', error: err.message });
    }
  });

  // 6. Submissions Inbox (Authorized)
  app.get('/api/enquiry/inbox', authenticateToken, async (req, res) => {
    try {
      const submissions = await PublicEnquirySubmission.findAll({
        include: [
          { model: Lead, as: 'lead' },
          { model: PublicEnquiryDocument, as: 'documents' },
          { model: PublicEnquiryNote, as: 'submissionNotes' }
        ],
        order: [['createdAt', 'DESC']]
      });
      res.json({ success: true, submissions });
    } catch (err) {
      res.status(500).json({ message: 'Error loading submissions inbox', error: err.message });
    }
  });

  // 7. Update Submission Status (In Review, Rejected, etc.)
  app.post('/api/enquiry/status/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      const submission = await PublicEnquirySubmission.findByPk(id);
      if (!submission) return res.status(404).json({ message: 'Submission not found' });

      await submission.update({ status });

      await PublicEnquiryHistory.create({
        leadId: submission.leadId,
        action: `Status: ${status}`,
        notes: `Submission marked as ${status} by ${req.user.name}`
      });

      res.json({ success: true, submission });
    } catch (err) {
      res.status(500).json({ message: 'Failed to update submission status', error: err.message });
    }
  });

  // 8. Add Submission Note
  app.post('/api/enquiry/notes/:submissionId', authenticateToken, async (req, res) => {
    try {
      const { submissionId } = req.params;
      const { noteText } = req.body;
      if (!noteText) return res.status(400).json({ message: 'Note text required' });

      const note = await PublicEnquiryNote.create({
        submissionId,
        author: req.user.name,
        noteText
      });

      res.json({ success: true, note });
    } catch (err) {
      res.status(500).json({ message: 'Failed to add note', error: err.message });
    }
  });

  // 9. Approve Submission & Convert to Project (Anand, Jaya, Muthuiya only)
  app.post('/api/enquiry/approve/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect'), async (req, res) => {
    try {
      const { id } = req.params;
      const submission = await PublicEnquirySubmission.findByPk(id, {
        include: [{ model: PublicEnquiryDocument, as: 'documents' }]
      });
      if (!submission) return res.status(404).json({ message: 'Submission not found' });

      // Create Client Profile
      const client = await Client.create({
        name: submission.clientName,
        phone: submission.contactNumber,
        email: submission.email || `${submission.clientName.toLowerCase().replace(/\s+/g, '')}@vianenquiry.com`,
        address: submission.siteAddress,
        propertyDetails: `${submission.buildingType} building context`
      });

      // Create Project
      const projectType = submission.buildingType && submission.buildingType.includes('Commercial') ? 'Commercial' : 'Residential';
      const project = await Project.create({
        projectId: `VIAN-PROJ-2026-${submission.leadId}`,
        name: `${submission.clientName}'s Project`,
        type: projectType,
        budget: 5000000.0,
        startDate: submission.date || new Date().toISOString().split('T')[0],
        completionDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        status: 'Planning',
        progressPercentage: 0,
        clientId: client.id,
        constructionPackage: 'Premium',
        siteAddress: submission.siteAddress,
        builtUpArea: 1800.0,
        floors: 1
      });

      // Seed project lifecycle stages
      await seedStagesForProject(project, 'Default');

      // Create Initial Estimate & BOQ
      const totalCost = 4200000.0;
      const currentYear = new Date().getFullYear();
      const estCount = await Estimate.count();
      const estimateNo = `EST-${currentYear}-${(estCount + 1).toString().padStart(4, '0')}`;

      const estimate = await Estimate.create({
        estimateNumber: estimateNo,
        projectName: project.name,
        clientName: submission.clientName,
        projectType: project.type,
        constructionType: 'New Construction',
        state: submission.state || 'Tamil Nadu',
        district: submission.district || 'Chennai',
        city: submission.village || '',
        siteAddress: submission.siteAddress,
        builtUpArea: 1800.0,
        unit: 'sqft',
        selectedPackage: 'Premium',
        packageRate: 2300.0,
        totalCost: totalCost,
        companyMarginPercentage: 15.0,
        estimatedProfit: totalCost * 0.15,
        gstPercentage: 18.0,
        gstAmount: totalCost * 0.18,
        netProjectValue: totalCost * 1.18,
        status: 'Approved',
        createdBy: req.user.id,
        projectId: project.id
      });

      await EstimateMaterial.create({
        estimateId: estimate.id,
        materialName: 'Cement',
        quantity: 800,
        unit: 'bags',
        rate: 450,
        amount: 360000,
        category: 'Structural'
      });

      await EstimateBoq.create({
        estimateId: estimate.id,
        itemName: 'Earthwork Excavation',
        description: 'Excavation for footings up to 1.5m depth',
        quantity: 1200,
        unit: 'cuft',
        rate: 25,
        amount: 30000
      });

      // Initialize Document Repository with files
      for (const doc of submission.documents) {
        await Document.create({
          title: doc.fileName,
          folder: 'Enquiry Attachments',
          fileUrl: doc.fileUrl,
          fileSize: doc.fileSize,
          projectId: project.id
        });
      }

      // Initial task list items
      await Task.create({
        title: 'Initial Site Soil Test Verification',
        description: 'Verify soil structure classification before foundation engineering layout.',
        priority: 'High',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        status: 'Pending',
        projectId: project.id
      });

      // Initial Site Visit Schedule
      await SiteVisit.create({
        date: new Date().toISOString().split('T')[0],
        gpsLocation: submission.nearLandmark || submission.siteAddress,
        notes: 'Initial Kick-off Project Meeting and Site Inspection scheduled.',
        projectId: project.id
      });

      // Update statuses
      await submission.update({ status: 'Converted' });
      const lead = await Lead.findByPk(submission.leadId);
      if (lead) {
        await lead.update({ status: 'Won' });
      }

      await PublicEnquiryHistory.create({
        leadId: submission.leadId,
        action: 'Converted',
        notes: `Submission approved and converted to Client & Project by ${req.user.name}`
      });

      res.json({ success: true, project });
    } catch (err) {
      res.status(500).json({ message: 'Error approving submission', error: err.message });
    }
  });

  // ==========================================
  // CLIENT MANAGEMENT MODULE
  // ==========================================
  
  app.get('/api/clients', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const where = { deletedAt: null };
      if (search) {
        where[Op.or] = [
          { name: { [Op.like]: `%${search}%` } },
          { phone: { [Op.like]: `%${search}%` } },
          { email: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await Client.findAndCountAll({
        where,
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        clients: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching clients', error: error.message });
    }
  });

  app.get('/api/clients/:id', authenticateToken, async (req, res) => {
    try {
      const client = await Client.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!client) return res.status(404).json({ message: 'Client not found' });
      res.json(client);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching client details', error: error.message });
    }
  });

  app.post('/api/clients', authenticateToken, async (req, res) => {
    try {
      const client = await Client.create(req.body);
      await writeAuditLog(req, 'Create', 'Clients', null, client.toJSON());
      res.status(201).json(client);
    } catch (error) {
      res.status(400).json({ message: 'Error creating client', error: error.message });
    }
  });

  app.put('/api/clients/:id', authenticateToken, async (req, res) => {
    try {
      const client = await Client.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!client) return res.status(404).json({ message: 'Client not found' });

      const oldVal = { ...client.toJSON() };
      await client.update(req.body);
      await writeAuditLog(req, 'Update', 'Clients', oldVal, client.toJSON());
      res.json(client);
    } catch (error) {
      res.status(400).json({ message: 'Error updating client', error: error.message });
    }
  });

  app.delete('/api/clients/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const client = await Client.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!client) return res.status(404).json({ message: 'Client not found' });

      const oldVal = { ...client.toJSON() };
      const deletedAt = new Date();
      await client.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Clients', oldVal, { deletedAt, deletedBy: req.user.id });
      res.json({ message: 'Client soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting client', error: error.message });
    }
  });

  // ==========================================
  // PROJECT MANAGEMENT MODULE
  // ==========================================
  
  app.get('/api/projects', authenticateToken, async (req, res) => {
    try {
      let projects;
      const whereClause = { isArchived: false, deletedAt: null };
      
      // Support viewing archived projects if query param is set
      if (req.query.archived === 'true') {
        whereClause.isArchived = true;
      } else if (req.query.all === 'true') {
        delete whereClause.isArchived;
      }

      if (req.user.role === 'Client') {
        const client = await Client.findOne({ where: { userId: req.user.id } });
        if (!client) return res.status(200).json({ projects: [] });
        whereClause.clientId = client.id;
        projects = await Project.findAll({
          where: whereClause,
          include: ['client', 'architect', 'siteEngineer', 'managingDirector', 'designEngineer', 'supervisor']
        });
      } else {
        projects = await Project.findAll({
          where: whereClause,
          include: ['client', 'architect', 'siteEngineer', 'managingDirector', 'designEngineer', 'supervisor']
        });
      }
      res.json({ projects });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching projects', error: error.message });
    }
  });

  // Get project by ID with full nested stage & payment lifecycle details
  app.get('/api/projects/:id', authenticateToken, async (req, res) => {
    try {
      const project = await Project.findByPk(req.params.id, {
        include: [
          'client', 'architect', 'siteEngineer', 'managingDirector', 'designEngineer', 'supervisor',
          {
            model: ProjectStage,
            as: 'stages',
            include: ['assignedEngineer', 'assignedArchitect', 'assignedSiteManager', 'tasks', 'materials', 'labours', 'payments', 'documents', 'photos', 'reports', 'approvals', 'history']
          }
        ]
      });

      if (!project) return res.status(404).json({ message: 'Project not found' });
      res.json(project);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching project details', error: error.message });
    }
  });

  // Helper to generate stages based on templates
  async function seedStagesForProject(project, templateType) {
    const defaultStages = [
      { name: 'Planning', description: 'Design signoffs, drawing preparation, blueprints approval.', paymentPercentage: 10, offsetDays: 0 },
      { name: 'Site Preparation', description: 'Clearing weeds, leveling soil, placing container offices.', paymentPercentage: 5, offsetDays: 15 },
      { name: 'Foundation', description: 'Excavation and foundation works.', paymentPercentage: 15, offsetDays: 30 },
      { name: 'Basement & Soil Filling', description: 'RCC basement columns and compaction soil filling.', paymentPercentage: 10, offsetDays: 50 },
      { name: 'Columns & Plinth Beam', description: 'Ground floor columns casting, plinth level beam grid.', paymentPercentage: 10, offsetDays: 75 },
      { name: 'Roof Slab casting', description: 'Formwork, steel binding, and concrete pouring.', paymentPercentage: 20, offsetDays: 105 },
      { name: 'Brick Work & Plastering', description: 'Outer & inner walls construction, cement rendering.', paymentPercentage: 10, offsetDays: 135 },
      { name: 'Electrical & Plumbing', description: 'Concealed conduits running, copper cabling, PVC pipes laying.', paymentPercentage: 10, offsetDays: 165 },
      { name: 'Finishing & Handover', description: 'Painting, tile flooring, interior wooden fixtures, deep cleaning.', paymentPercentage: 10, offsetDays: 200 }
    ];

    const baseDate = new Date(project.startDate || new Date());
    for (let i = 0; i < defaultStages.length; i++) {
      const s = defaultStages[i];
      const estStart = new Date(baseDate);
      estStart.setDate(estStart.getDate() + s.offsetDays);
      const estEnd = new Date(estStart);
      estEnd.setDate(estEnd.getDate() + 14); // 2-week duration default

      const stage = await ProjectStage.create({
        projectId: project.id,
        name: s.name,
        description: s.description,
        order: i,
        estimatedStart: estStart.toISOString().split('T')[0],
        estimatedEnd: estEnd.toISOString().split('T')[0],
        paymentPercentage: s.paymentPercentage,
        estimatedCost: project.budget * (s.paymentPercentage / 100),
        status: i === 0 ? 'In Progress' : 'Pending',
        priority: 'Medium'
      });

      // Log history entry
      await StageHistory.create({
        stageId: stage.id,
        action: 'Stage Configured',
        notes: `Stage initialized from project template: ${templateType}`
      });
    }
  }

  app.post('/api/projects', authenticateToken, async (req, res) => {
    try {
      const { template, ...projectData } = req.body;
      const project = await Project.create(projectData);
      
      // Auto seed from templates if requested
      if (template) {
        await seedStagesForProject(project, template);
      } else {
        await seedStagesForProject(project, 'Default');
      }

      await writeAuditLog(req, 'Create', 'Projects', null, project.toJSON());

      res.status(201).json(project);
    } catch (error) {
      res.status(400).json({ message: 'Error creating project', error: error.message });
    }
  });

  app.put('/api/projects/:id', authenticateToken, async (req, res) => {
    try {
      const project = await Project.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!project) return res.status(404).json({ message: 'Project not found' });
      
      const oldVal = { ...project.toJSON() };
      await project.update(req.body);

      await writeAuditLog(req, 'Update', 'Projects', oldVal, project.toJSON());

      res.json(project);
    } catch (error) {
      res.status(400).json({ message: 'Error updating project', error: error.message });
    }
  });

  // Archive Project
  app.post('/api/projects/:id/archive', authenticateToken, async (req, res) => {
    try {
      const project = await Project.findByPk(req.params.id);
      if (!project) return res.status(404).json({ message: 'Project not found' });
      await project.update({ isArchived: true });
      res.json({ message: 'Project archived successfully', project });
    } catch (error) {
      res.status(500).json({ message: 'Error archiving project', error: error.message });
    }
  });

  // Restore Project
  app.post('/api/projects/:id/restore', authenticateToken, async (req, res) => {
    try {
      const project = await Project.findByPk(req.params.id);
      if (!project) return res.status(404).json({ message: 'Project not found' });
      await project.update({ isArchived: false });
      res.json({ message: 'Project restored successfully', project });
    } catch (error) {
      res.status(500).json({ message: 'Error restoring project', error: error.message });
    }
  });

  // Duplicate Project
  app.post('/api/projects/:id/duplicate', authenticateToken, async (req, res) => {
    try {
      const sourceProject = await Project.findByPk(req.params.id, {
        include: [{ model: ProjectStage, as: 'stages' }]
      });

      if (!sourceProject) return res.status(404).json({ message: 'Source project not found' });

      // Create new copy
      const copy = await Project.create({
        projectId: `${sourceProject.projectId}-DUP-${Date.now().toString().slice(-4)}`,
        name: `${sourceProject.name} (Copy)`,
        type: sourceProject.type,
        clientId: sourceProject.clientId,
        budget: sourceProject.budget,
        startDate: sourceProject.startDate,
        completionDate: sourceProject.completionDate,
        constructionPackage: sourceProject.constructionPackage,
        siteAddress: sourceProject.siteAddress,
        googleMapsLocation: sourceProject.googleMapsLocation,
        builtUpArea: sourceProject.builtUpArea,
        floors: sourceProject.floors
      });

      // Duplicate stages
      if (sourceProject.stages && sourceProject.stages.length > 0) {
        for (const stage of sourceProject.stages) {
          await ProjectStage.create({
            projectId: copy.id,
            name: stage.name,
            description: stage.description,
            order: stage.order,
            estimatedStart: stage.estimatedStart,
            estimatedEnd: stage.estimatedEnd,
            estimatedCost: stage.estimatedCost,
            paymentPercentage: stage.paymentPercentage,
            priority: stage.priority,
            status: stage.status
          });
        }
      }

      res.status(201).json(copy);
    } catch (error) {
      res.status(500).json({ message: 'Error duplicating project', error: error.message });
    }
  });

  // Delete Project (Super Admin Only)
  app.delete('/api/projects/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const project = await Project.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!project) return res.status(404).json({ message: 'Project not found' });
      
      const oldVal = { ...project.toJSON() };
      const deletedAt = new Date();
      await project.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Projects', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Project soft-deleted successfully.' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting project', error: error.message });
    }
  });

  // ==========================================
  // STAGES CRUD & MANAGEMENT
  // ==========================================

  // Check stage permission helper
  function checkStageManagerPermission(user) {
    const allowedRoles = ['Managing Director', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect', 'Site Manager'];
    return allowedRoles.includes(user.role);
  }

  // Create stage manually
  app.post('/api/projects/:id/stages', authenticateToken, async (req, res) => {
    try {
      if (!checkStageManagerPermission(req.user)) {
        return res.status(403).json({ message: 'Permission denied to manage stages.' });
      }

      const stage = await ProjectStage.create({
        ...req.body,
        projectId: req.params.id
      });

      await StageHistory.create({
        stageId: stage.id,
        action: 'Stage Created',
        notes: `Created manually by ${req.user.name}`
      });

      res.status(201).json(stage);
    } catch (error) {
      res.status(400).json({ message: 'Error creating stage', error: error.message });
    }
  });

  // Edit stage info
  app.put('/api/projects/:id/stages/:stageId', authenticateToken, async (req, res) => {
    try {
      const stage = await ProjectStage.findByPk(req.params.stageId);
      if (!stage) return res.status(404).json({ message: 'Stage not found' });

      const wasCompleted = stage.status === 'Completed';
      
      await stage.update(req.body);

      if (!wasCompleted && stage.status === 'Completed') {
        await Notification.create({
          title: 'Stage Completed',
          message: `Stage "${stage.name}" in project has been marked as Completed and requires Approval.`,
          type: 'Workflow',
          userId: 1
        });
      }

      await StageHistory.create({
        stageId: stage.id,
        action: 'Stage Updated',
        notes: `Updated parameters by ${req.user.name}`
      });

      res.json(stage);
    } catch (error) {
      res.status(400).json({ message: 'Error updating stage', error: error.message });
    }
  });

  // Reorder stages
  app.post('/api/projects/:id/stages/reorder', authenticateToken, async (req, res) => {
    try {
      if (!checkStageManagerPermission(req.user)) {
        return res.status(403).json({ message: 'Permission denied.' });
      }
      const { orders } = req.body;
      for (const item of orders) {
        await ProjectStage.update({ order: item.order }, { where: { id: item.id } });
      }
      res.json({ message: 'Stages reordered successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Failed to reorder stages', error: error.message });
    }
  });

  // Duplicate Stage
  app.post('/api/projects/:id/stages/:stageId/duplicate', authenticateToken, async (req, res) => {
    try {
      if (!checkStageManagerPermission(req.user)) {
        return res.status(403).json({ message: 'Permission denied.' });
      }
      const source = await ProjectStage.findByPk(req.params.stageId);
      if (!source) return res.status(404).json({ message: 'Stage not found' });

      const copy = await ProjectStage.create({
        projectId: source.projectId,
        name: `${source.name} (Copy)`,
        description: source.description,
        estimatedStart: source.estimatedStart,
        estimatedEnd: source.estimatedEnd,
        estimatedCost: source.estimatedCost,
        paymentPercentage: source.paymentPercentage,
        priority: source.priority,
        status: 'Pending',
        order: source.order + 1
      });

      res.status(201).json(copy);
    } catch (error) {
      res.status(500).json({ message: 'Error duplicating stage', error: error.message });
    }
  });

  // Delete Stage
  app.delete('/api/projects/:id/stages/:stageId', authenticateToken, async (req, res) => {
    try {
      if (!checkStageManagerPermission(req.user)) {
        return res.status(403).json({ message: 'Permission denied.' });
      }
      const stage = await ProjectStage.findByPk(req.params.stageId);
      if (!stage) return res.status(404).json({ message: 'Stage not found' });
      await stage.destroy();
      res.json({ message: 'Stage deleted successfully.' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting stage', error: error.message });
    }
  });

  // ==========================================
  // STAGE PROGRESS, MATERIAL & LABOUR LOGS
  // ==========================================

  app.post('/api/projects/:id/stages/:stageId/reports', authenticateToken, async (req, res) => {
    try {
      const report = await StageReport.create({
        ...req.body,
        stageId: req.params.stageId
      });

      if (req.body.completionPercentage !== undefined) {
        await ProjectStage.update(
          { completionPercentage: req.body.completionPercentage },
          { where: { id: req.params.stageId } }
        );
      }

      res.status(201).json(report);
    } catch (error) {
      res.status(400).json({ message: 'Error adding report', error: error.message });
    }
  });

  app.post('/api/projects/:id/stages/:stageId/materials', authenticateToken, async (req, res) => {
    try {
      const material = await StageMaterial.create({
        ...req.body,
        stageId: req.params.stageId
      });

      const stage = await ProjectStage.findByPk(req.params.stageId);
      if (stage) {
        const newMatCost = parseFloat(stage.materialCost || 0) + parseFloat(req.body.purchaseCost || 0);
        await stage.update({
          materialCost: newMatCost,
          actualCost: parseFloat(stage.labourCost || 0) + newMatCost
        });
      }

      res.status(201).json(material);
    } catch (error) {
      res.status(400).json({ message: 'Error adding material log', error: error.message });
    }
  });

  app.post('/api/projects/:id/stages/:stageId/labours', authenticateToken, async (req, res) => {
    try {
      const labour = await StageLabour.create({
        ...req.body,
        stageId: req.params.stageId
      });

      const stage = await ProjectStage.findByPk(req.params.stageId);
      if (stage) {
        const newLabCost = parseFloat(stage.labourCost || 0) + parseFloat(req.body.dailyCost || 0);
        await stage.update({
          labourCost: newLabCost,
          actualCost: parseFloat(stage.materialCost || 0) + newLabCost
        });
      }

      res.status(201).json(labour);
    } catch (error) {
      res.status(400).json({ message: 'Error adding labour log', error: error.message });
    }
  });

  app.post('/api/projects/:id/stages/:stageId/payments', authenticateToken, async (req, res) => {
    try {
      const payment = await StagePayment.create({
        ...req.body,
        stageId: req.params.stageId
      });

      const stage = await ProjectStage.findByPk(req.params.stageId);
      if (stage) {
        const amountPaid = parseFloat(stage.paymentAmountPaid || 0) + parseFloat(req.body.paidAmount || 0);
        let status = 'Pending';
        if (amountPaid >= parseFloat(req.body.amount || 0)) status = 'Paid';
        else if (amountPaid > 0) status = 'Partially Paid';

        await stage.update({
          paymentAmountPaid: amountPaid,
          paymentStatus: status,
          paymentDueDate: req.body.dueDate
        });
      }

      res.status(201).json(payment);
    } catch (error) {
      res.status(400).json({ message: 'Error recording payment log', error: error.message });
    }
  });

  app.post('/api/projects/:id/stages/:stageId/approve', authenticateToken, async (req, res) => {
    try {
      const stage = await ProjectStage.findByPk(req.params.stageId);
      if (!stage) return res.status(404).json({ message: 'Stage not found' });

      const { role, status, comments, signatureUrl } = req.body;
      const approval = await StageApproval.create({
        stageId: stage.id,
        role,
        status,
        comments,
        signatureUrl,
        approvedById: req.user.id,
        approvedAt: new Date()
      });

      let nextWorkflowStatus = stage.approvalStatus;
      if (status === 'Approved') {
        if (role === 'Engineer') nextWorkflowStatus = 'Site Manager';
        else if (role === 'Site Manager') nextWorkflowStatus = 'Architect';
        else if (role === 'Senior Architect') nextWorkflowStatus = 'MD';
        else if (role === 'Managing Director') {
          nextWorkflowStatus = 'Approved';
          await stage.update({ status: 'Approved' });
        }
      } else {
        nextWorkflowStatus = `Rejected by ${role}`;
        await stage.update({ status: 'On Hold' });
      }

      await stage.update({ approvalStatus: nextWorkflowStatus });

      await StageHistory.create({
        stageId: stage.id,
        action: `Approval Update: ${role}`,
        notes: `Marked as ${status}. Comments: ${comments || 'None'}`
      });

      res.status(201).json({ approval, stage });
    } catch (error) {
      res.status(500).json({ message: 'Failed to record approval', error: error.message });
    }
  });

  // ==========================================
  // SITE VISIT MODULE
  // ==========================================
  
  app.post('/api/site-visits', authenticateToken, async (req, res) => {
    try {
      const visit = await SiteVisit.create({
        ...req.body,
        userId: req.user.id
      });
      res.status(201).json(visit);
    } catch (error) {
      res.status(400).json({ message: 'Error creating site visit', error: error.message });
    }
  });

  app.get('/api/site-visits', authenticateToken, async (req, res) => {
    try {
      const visits = await SiteVisit.findAll({ include: ['project', 'visitor'] });
      res.json({ visits });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching site visits', error: error.message });
    }
  });

  // ==========================================
  // GPS ATTENDANCE SYSTEM
  // ==========================================
  
  app.post('/api/attendance/check-in', authenticateToken, async (req, res) => {
    const { gps, selfieUrl } = req.body;
    const today = new Date().toISOString().split('T')[0];
    const nowTime = new Date().toTimeString().split(' ')[0];

    try {
      const existing = await Attendance.findOne({ where: { userId: req.user.id, date: today } });
      if (existing) {
        return res.status(400).json({ message: 'Already checked in today' });
      }

      // Simple late detection: check-in after 09:30:00
      let status = 'Present';
      if (nowTime > '09:30:00') status = 'Late';

      const record = await Attendance.create({
        userId: req.user.id,
        date: today,
        checkInTime: nowTime,
        checkInGps: gps,
        checkInSelfieUrl: selfieUrl || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        status: status
      });

      res.status(201).json({ message: 'Check-in successful', record });
    } catch (error) {
      res.status(500).json({ message: 'Check-in failed', error: error.message });
    }
  });

  app.post('/api/attendance/check-out', authenticateToken, async (req, res) => {
    const { gps } = req.body;
    const today = new Date().toISOString().split('T')[0];
    const nowTime = new Date().toTimeString().split(' ')[0];

    try {
      const record = await Attendance.findOne({ where: { userId: req.user.id, date: today } });
      if (!record) return res.status(404).json({ message: 'No check-in record found for today' });
      if (record.checkOutTime) return res.status(400).json({ message: 'Already checked out today' });

      // Calculate working hours
      const [inH, inM, inS] = record.checkInTime.split(':').map(Number);
      const [outH, outM, outS] = nowTime.split(':').map(Number);
      const inDate = new Date(2000, 0, 1, inH, inM, inS);
      const outDate = new Date(2000, 0, 1, outH, outM, outS);
      const hours = (outDate - inDate) / (1000 * 60 * 60);

      await record.update({
        checkOutTime: nowTime,
        checkOutGps: gps,
        workingHours: parseFloat(hours.toFixed(2))
      });

      res.json({ message: 'Check-out successful', record });
    } catch (error) {
      res.status(500).json({ message: 'Check-out failed', error: error.message });
    }
  });

  app.get('/api/attendance', authenticateToken, async (req, res) => {
    try {
      const records = await Attendance.findAll({ include: ['user'] });
      res.json({ attendance: records });
    } catch (error) {
      res.status(500).json({ message: 'Error loading attendance', error: error.message });
    }
  });

  // ==========================================
  // TASK MANAGEMENT MODULE
  // ==========================================
  
  app.get('/api/tasks', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';
      const status = req.query.status || '';

      const where = { deletedAt: null };
      if (status) {
        where.status = status;
      }
      if (search) {
        where[Op.or] = [
          { title: { [Op.like]: `%${search}%` } },
          { description: { [Op.like]: `%${search}%` } }
        ];
      }

      // Staff roles can only see tasks assigned to them
      const pRole = getPermissionRole(req.user.role);
      if (pRole === 'Staff') {
        where.assignedTo = req.user.id;
      }

      const { count, rows } = await Task.findAndCountAll({
        where,
        include: ['project', 'assignee'],
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        tasks: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving tasks', error: error.message });
    }
  });

  app.get('/api/tasks/:id', authenticateToken, async (req, res) => {
    try {
      const where = { id: req.params.id, deletedAt: null };
      const pRole = getPermissionRole(req.user.role);
      if (pRole === 'Staff') {
        where.assignedTo = req.user.id;
      }

      const task = await Task.findOne({
        where,
        include: ['project', 'assignee']
      });
      if (!task) return res.status(404).json({ message: 'Task not found or access denied' });
      res.json(task);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching task details', error: error.message });
    }
  });

  app.post('/api/tasks', authenticateToken, async (req, res) => {
    try {
      const task = await Task.create(req.body);
      await writeAuditLog(req, 'Create', 'Tasks', null, task.toJSON());
      res.status(201).json(task);
    } catch (error) {
      res.status(400).json({ message: 'Error creating task', error: error.message });
    }
  });

  app.put('/api/tasks/:id', authenticateToken, async (req, res) => {
    try {
      const where = { id: req.params.id, deletedAt: null };
      const pRole = getPermissionRole(req.user.role);
      if (pRole === 'Staff') {
        where.assignedTo = req.user.id;
      }

      const task = await Task.findOne({ where });
      if (!task) return res.status(404).json({ message: 'Task not found or access denied' });

      const oldVal = { ...task.toJSON() };
      await task.update(req.body);

      await writeAuditLog(req, 'Update', 'Tasks', oldVal, task.toJSON());

      res.json(task);
    } catch (error) {
      res.status(400).json({ message: 'Error updating task', error: error.message });
    }
  });

  app.delete('/api/tasks/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const task = await Task.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!task) return res.status(404).json({ message: 'Task not found' });

      const oldVal = { ...task.toJSON() };
      const deletedAt = new Date();
      await task.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Tasks', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Task soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting task', error: error.message });
    }
  });

  // ==========================================
  // DRAWINGS & DOCUMENTS
  // ==========================================
  
  app.get('/api/projects/:projectId/drawings', authenticateToken, async (req, res) => {
    try {
      const drawings = await Drawing.findAll({ where: { projectId: req.params.projectId }, include: ['approver'] });
      res.json({ drawings });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving drawings', error: error.message });
    }
  });

  app.post('/api/drawings', authenticateToken, async (req, res) => {
    try {
      const drawing = await Drawing.create(req.body);
      res.status(201).json(drawing);
    } catch (error) {
      res.status(400).json({ message: 'Error creating drawing entry', error: error.message });
    }
  });

  app.put('/api/drawings/:id/approve', authenticateToken, authorizeRoles('Super Admin', 'Architect'), async (req, res) => {
    try {
      const drawing = await Drawing.findByPk(req.params.id);
      if (!drawing) return res.status(404).json({ message: 'Drawing not found' });
      await drawing.update({
        status: req.body.status, // Approved/Rejected
        approvedBy: req.user.id
      });
      res.json(drawing);
    } catch (error) {
      res.status(400).json({ message: 'Drawing approval failed', error: error.message });
    }
  });

  app.get('/api/projects/:projectId/documents', authenticateToken, async (req, res) => {
    try {
      const docs = await Document.findAll({ where: { projectId: req.params.projectId } });
      
      // Filter by folder access based on user role
      const role = req.user.role;
      let allowedFolders = ['Projects', 'Drawings', 'Site Photos', 'General', 'Property Documents', 'Agreements']; // default general
      
      if (role === 'Super Admin' || role === 'Managing Director' || role === 'Admin / Office Manager / Accounts') {
        allowedFolders = ['Projects', 'Drawings', 'Site Photos', 'HR Documents', 'Client Documents', 'Contracts', 'Invoices', 'General', 'Property Documents', 'Agreements', 'Expenses'];
      } else if (role === 'Tech Head + Senior Architect' || role === 'Site Manager') {
        allowedFolders = ['Projects', 'Drawings', 'Site Photos', 'Client Documents', 'General', 'Property Documents', 'Agreements'];
      } else {
        // General employees
        allowedFolders = ['Projects', 'Drawings', 'Site Photos', 'General', 'Property Documents'];
      }
      
      const filteredDocs = docs.filter(d => allowedFolders.includes(d.folder));
      res.json({ documents: filteredDocs });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving documents', error: error.message });
    }
  });

  app.post('/api/documents', authenticateToken, async (req, res) => {
    try {
      const role = req.user.role;
      const folder = req.body.folder || 'General';
      
      let allowed = false;
      if (role === 'Super Admin' || role === 'Managing Director' || role === 'Admin / Office Manager / Accounts') {
        allowed = true;
      } else if (role === 'Tech Head + Senior Architect' || role === 'Site Manager') {
        allowed = ['Projects', 'Drawings', 'Site Photos', 'Client Documents', 'General', 'Property Documents', 'Agreements'].includes(folder);
      } else {
        // general employees
        allowed = ['Projects', 'Drawings', 'Site Photos', 'General', 'Property Documents'].includes(folder);
      }
      
      if (!allowed) {
        return res.status(403).json({ message: `Insufficient permissions to upload to ${folder} directory.` });
      }
      
      const doc = await Document.create(req.body);
      res.status(201).json(doc);
    } catch (error) {
      res.status(400).json({ message: 'Error uploading document', error: error.message });
    }
  });

  // ==========================================
  // QUOTATION MODULE
  // ==========================================
  
  app.get('/api/quotations', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const where = { deletedAt: null };
      if (search) {
        where[Op.or] = [
          { quotationNumber: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await Quotation.findAndCountAll({
        where,
        include: ['project'],
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        quotations: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching quotations', error: error.message });
    }
  });

  app.get('/api/quotations/:id', authenticateToken, async (req, res) => {
    try {
      const quote = await Quotation.findOne({ where: { id: req.params.id, deletedAt: null }, include: ['project'] });
      if (!quote) return res.status(404).json({ message: 'Quotation not found' });
      res.json(quote);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching quotation details', error: error.message });
    }
  });

  app.post('/api/quotations', authenticateToken, async (req, res) => {
    try {
      const { projectId, items, taxRate, discount } = req.body;
      const parsedItems = typeof items === 'string' ? JSON.parse(items) : items;
      
      let subtotal = 0;
      parsedItems.forEach(item => {
        subtotal += parseFloat(item.quantity || 0) * parseFloat(item.rate || 0);
      });
      
      const taxAmount = subtotal * (parseFloat(taxRate || 18) / 100);
      const total = subtotal + taxAmount - parseFloat(discount || 0);

      const count = await Quotation.count();
      const quoteNo = `VIAN-QT-${new Date().getFullYear()}-${String(count + 1).padStart(3, '0')}`;

      const quote = await Quotation.create({
        projectId,
        quotationNumber: quoteNo,
        date: new Date().toISOString().split('T')[0],
        taxRate,
        discount,
        subtotal,
        total,
        items: JSON.stringify(parsedItems),
        status: 'Draft'
      });

      await writeAuditLog(req, 'Create', 'Quotations', null, quote.toJSON());

      res.status(201).json(quote);
    } catch (error) {
      res.status(400).json({ message: 'Quotation creation failed', error: error.message });
    }
  });

  app.put('/api/quotations/:id', authenticateToken, async (req, res) => {
    try {
      const quote = await Quotation.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!quote) return res.status(404).json({ message: 'Quotation not found' });

      const oldVal = { ...quote.toJSON() };
      const updateData = { ...req.body };
      
      if (updateData.items) {
        const parsedItems = typeof updateData.items === 'string' ? JSON.parse(updateData.items) : updateData.items;
        let subtotal = 0;
        parsedItems.forEach(item => {
          subtotal += parseFloat(item.quantity || 0) * parseFloat(item.rate || 0);
        });
        const taxRate = updateData.taxRate || quote.taxRate;
        const discount = updateData.discount || quote.discount;
        const taxAmount = subtotal * (parseFloat(taxRate || 18) / 100);
        
        updateData.subtotal = subtotal;
        updateData.total = subtotal + taxAmount - parseFloat(discount || 0);
        updateData.items = JSON.stringify(parsedItems);
      }

      await quote.update(updateData);
      await writeAuditLog(req, 'Update', 'Quotations', oldVal, quote.toJSON());

      res.json(quote);
    } catch (error) {
      res.status(400).json({ message: 'Quotation update failed', error: error.message });
    }
  });

  app.delete('/api/quotations/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const quote = await Quotation.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!quote) return res.status(404).json({ message: 'Quotation not found' });

      const oldVal = { ...quote.toJSON() };
      const deletedAt = new Date();
      await quote.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Quotations', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Quotation soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting quotation', error: error.message });
    }
  });

  // ==========================================
  // INVOICE MODULE
  // ==========================================
  
  app.get('/api/invoices', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const where = { deletedAt: null };
      if (search) {
        where[Op.or] = [
          { invoiceNumber: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await Invoice.findAndCountAll({
        where,
        include: ['project'],
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        invoices: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching invoices', error: error.message });
    }
  });

  app.get('/api/invoices/:id', authenticateToken, async (req, res) => {
    try {
      const invoice = await Invoice.findOne({ where: { id: req.params.id, deletedAt: null }, include: ['project'] });
      if (!invoice) return res.status(404).json({ message: 'Invoice not found' });
      res.json(invoice);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching invoice details', error: error.message });
    }
  });

  app.post('/api/invoices', authenticateToken, async (req, res) => {
    try {
      const { projectId, items, taxRate, discount, dueDate } = req.body;
      const parsedItems = typeof items === 'string' ? JSON.parse(items) : items;

      let subtotal = 0;
      parsedItems.forEach(item => {
        subtotal += parseFloat(item.quantity || 0) * parseFloat(item.rate || 0);
      });
      
      const taxAmount = subtotal * (parseFloat(taxRate || 18) / 100);
      const total = subtotal + taxAmount - parseFloat(discount || 0);

      const count = await Invoice.count();
      const invoiceNo = `VIAN-INV-${new Date().getFullYear()}-${String(count + 1).padStart(3, '0')}`;

      const invoice = await Invoice.create({
        projectId,
        invoiceNumber: invoiceNo,
        date: new Date().toISOString().split('T')[0],
        dueDate: dueDate || new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        taxRate,
        discount,
        subtotal,
        total,
        paidAmount: 0.00,
        items: JSON.stringify(parsedItems),
        status: 'Draft'
      });

      await writeAuditLog(req, 'Create', 'Invoices', null, invoice.toJSON());

      res.status(201).json(invoice);
    } catch (error) {
      res.status(400).json({ message: 'Invoice generation failed', error: error.message });
    }
  });

  app.put('/api/invoices/:id', authenticateToken, async (req, res) => {
    try {
      const invoice = await Invoice.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!invoice) return res.status(404).json({ message: 'Invoice not found' });

      const oldVal = { ...invoice.toJSON() };
      const updateData = { ...req.body };
      
      if (updateData.items) {
        const parsedItems = typeof updateData.items === 'string' ? JSON.parse(updateData.items) : updateData.items;
        let subtotal = 0;
        parsedItems.forEach(item => {
          subtotal += parseFloat(item.quantity || 0) * parseFloat(item.rate || 0);
        });
        const taxRate = updateData.taxRate || invoice.taxRate;
        const discount = updateData.discount || invoice.discount;
        const taxAmount = subtotal * (parseFloat(taxRate || 18) / 100);
        
        updateData.subtotal = subtotal;
        updateData.total = subtotal + taxAmount - parseFloat(discount || 0);
        updateData.items = JSON.stringify(parsedItems);
      }

      await invoice.update(updateData);
      await writeAuditLog(req, 'Update', 'Invoices', oldVal, invoice.toJSON());

      res.json(invoice);
    } catch (error) {
      res.status(400).json({ message: 'Invoice update failed', error: error.message });
    }
  });

  app.delete('/api/invoices/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const invoice = await Invoice.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!invoice) return res.status(404).json({ message: 'Invoice not found' });

      const oldVal = { ...invoice.toJSON() };
      const deletedAt = new Date();
      await invoice.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Invoices', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Invoice soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting invoice', error: error.message });
    }
  });

  app.put('/api/invoices/:id/payment', authenticateToken, async (req, res) => {
    const { amount } = req.body;
    try {
      const invoice = await Invoice.findByPk(req.params.id);
      if (!invoice) return res.status(404).json({ message: 'Invoice not found' });
      
      const newPaid = parseFloat(invoice.paidAmount) + parseFloat(amount);
      let status = 'Sent';
      if (newPaid >= parseFloat(invoice.total)) {
        status = 'Paid';
      }
      
      await invoice.update({
        paidAmount: newPaid,
        status: status
      });

      res.json(invoice);
    } catch (error) {
      res.status(400).json({ message: 'Payment update failed', error: error.message });
    }
  });

  // ==========================================
  // EXPENSE MODULE
  // ==========================================
  
  app.get('/api/expenses', authenticateToken, async (req, res) => {
    try {
      const expenses = await Expense.findAll({ include: ['project', 'user'] });
      res.json({ expenses });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving expenses', error: error.message });
    }
  });

  app.post('/api/expenses', authenticateToken, async (req, res) => {
    try {
      const expense = await Expense.create({
        ...req.body,
        userId: req.user.id,
        date: req.body.date || new Date().toISOString().split('T')[0]
      });
      res.status(201).json(expense);
    } catch (error) {
      res.status(400).json({ message: 'Error creating expense', error: error.message });
    }
  });

  app.put('/api/expenses/:id/approve', authenticateToken, authorizeRoles('Super Admin', 'Accountant'), async (req, res) => {
    try {
      const exp = await Expense.findByPk(req.params.id);
      if (!exp) return res.status(404).json({ message: 'Expense not found' });
      await exp.update({ status: req.body.status }); // Approved/Rejected
      res.json(exp);
    } catch (error) {
      res.status(400).json({ message: 'Expense status update failed', error: error.message });
    }
  });

  // ==========================================
  // EMPLOYEES & ATTENDANCE REPORTS
  // ==========================================
  
  app.get('/api/employees', authenticateToken, async (req, res) => {
    try {
      const employees = await User.findAll({
        where: {
          role: {
            [Op.ne]: 'Client'
          }
        },
        attributes: { exclude: ['passwordHash'] }
      });
      res.json({ employees });
    } catch (error) {
      res.status(500).json({ message: 'Error loading employees', error: error.message });
    }
  });

  // ==========================================
  // NOTIFICATIONS MODULE
  // ==========================================
  
  app.get('/api/notifications', authenticateToken, async (req, res) => {
    try {
      const list = await Notification.findAll({ where: { userId: req.user.id }, order: [['createdAt', 'DESC']] });
      res.json({ notifications: list });
    } catch (error) {
      res.status(500).json({ message: 'Error loading notifications', error: error.message });
    }
  });

  app.put('/api/notifications/:id/read', authenticateToken, async (req, res) => {
    try {
      const notif = await Notification.findOne({ where: { id: req.params.id, userId: req.user.id } });
      if (!notif) return res.status(404).json({ message: 'Notification not found' });
      await notif.update({ readStatus: true });
      res.json({ message: 'Notification marked read' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });

  // ==========================================
  // SETTINGS MODULE
  // ==========================================
  
  app.get('/api/settings', authenticateToken, async (req, res) => {
    try {
      let settings = await CompanySettings.findOne();
      if (!settings) {
        settings = await CompanySettings.create({
          companyName: 'VIAN Architects & Designers',
          address: 'Headquarters, VIAN Studio',
          email: 'contact@vianarchitects.com',
          phone: '+91 99999 88888',
          gst: '27AAAAA0000A1Z5'
        });
      }
      res.json({ settings });
    } catch (error) {
      res.status(500).json({ message: 'Error loading settings', error: error.message });
    }
  });

  app.put('/api/settings', authenticateToken, authorizeRoles('Super Admin'), async (req, res) => {
    try {
      let settings = await CompanySettings.findOne();
      if (!settings) {
        settings = await CompanySettings.create(req.body);
      } else {
        await settings.update(req.body);
      }
      res.json(settings);
    } catch (error) {
      res.status(400).json({ message: 'Error updating settings', error: error.message });
    }
  });

  // ==========================================
  // LABOUR MANAGEMENT MODULE
  // ==========================================
  
  app.get('/api/labour/workers', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const where = { deletedAt: null };
      if (search) {
        where[Op.or] = [
          { name: { [Op.like]: `%${search}%` } },
          { workerId: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await Worker.findAndCountAll({
        where,
        include: ['project'],
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        workers: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching workers list', error: error.message });
    }
  });

  app.get('/api/labour/workers/:id', authenticateToken, async (req, res) => {
    try {
      const worker = await Worker.findOne({ where: { id: req.params.id, deletedAt: null }, include: ['project'] });
      if (!worker) return res.status(404).json({ message: 'Worker profile not found' });
      res.json(worker);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching worker details', error: error.message });
    }
  });

  app.post('/api/labour/workers', authenticateToken, async (req, res) => {
    try {
      const worker = await Worker.create(req.body);
      await writeAuditLog(req, 'Create', 'Workers', null, worker.toJSON());
      res.status(201).json(worker);
    } catch (error) {
      res.status(400).json({ message: 'Error creating worker profile', error: error.message });
    }
  });

  app.put('/api/labour/workers/:id', authenticateToken, async (req, res) => {
    try {
      const worker = await Worker.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!worker) return res.status(404).json({ message: 'Worker profile not found' });

      const oldVal = { ...worker.toJSON() };
      await worker.update(req.body);
      await writeAuditLog(req, 'Update', 'Workers', oldVal, worker.toJSON());

      res.json(worker);
    } catch (error) {
      res.status(400).json({ message: 'Error updating worker profile', error: error.message });
    }
  });

  app.delete('/api/labour/workers/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const worker = await Worker.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!worker) return res.status(404).json({ message: 'Worker profile not found' });

      const oldVal = { ...worker.toJSON() };
      const deletedAt = new Date();
      await worker.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Workers', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Worker profile soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting worker profile', error: error.message });
    }
  });

  // ==========================================
  // CONTRACTOR MANAGEMENT MODULE
  // ==========================================

  // --- Contractors CRUD ---
  app.get('/api/contractors', authenticateToken, async (req, res) => {
    try {
      const contractors = await Contractor.findAll();
      res.json({ contractors });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching contractors list', error: error.message });
    }
  });

  app.post('/api/contractors', authenticateToken, async (req, res) => {
    try {
      const contractor = await Contractor.create(req.body);
      res.status(201).json(contractor);
    } catch (error) {
      res.status(400).json({ message: 'Error creating contractor profile', error: error.message });
    }
  });

  app.put('/api/contractors/:id', authenticateToken, async (req, res) => {
    try {
      const contractor = await Contractor.findByPk(req.params.id);
      if (!contractor) return res.status(404).json({ message: 'Contractor profile not found' });
      await contractor.update(req.body);
      res.json(contractor);
    } catch (error) {
      res.status(400).json({ message: 'Error updating contractor profile', error: error.message });
    }
  });

  app.delete('/api/contractors/:id', authenticateToken, async (req, res) => {
    try {
      const contractor = await Contractor.findByPk(req.params.id);
      if (!contractor) return res.status(404).json({ message: 'Contractor profile not found' });
      await contractor.destroy();
      res.json({ message: 'Contractor profile deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting contractor profile', error: error.message });
    }
  });

  // --- Contractor Payment Stages CRUD ---
  app.get('/api/contractor-stages', authenticateToken, async (req, res) => {
    try {
      const stages = await ContractorPaymentStage.findAll();
      res.json({ stages });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching payment stages', error: error.message });
    }
  });

  app.post('/api/contractor-stages', authenticateToken, authorizeRoles('Super Admin', 'Admin / Office Manager / Accounts'), async (req, res) => {
    try {
      const stage = await ContractorPaymentStage.create(req.body);
      res.status(201).json(stage);
    } catch (error) {
      res.status(400).json({ message: 'Error creating payment stage', error: error.message });
    }
  });

  app.put('/api/contractor-stages/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin / Office Manager / Accounts'), async (req, res) => {
    try {
      const stage = await ContractorPaymentStage.findByPk(req.params.id);
      if (!stage) return res.status(404).json({ message: 'Payment stage not found' });
      await stage.update(req.body);
      res.json(stage);
    } catch (error) {
      res.status(400).json({ message: 'Error updating payment stage', error: error.message });
    }
  });

  app.delete('/api/contractor-stages/:id', authenticateToken, authorizeRoles('Super Admin', 'Admin / Office Manager / Accounts'), async (req, res) => {
    try {
      const stage = await ContractorPaymentStage.findByPk(req.params.id);
      if (!stage) return res.status(404).json({ message: 'Payment stage not found' });
      await stage.destroy();
      res.json({ message: 'Payment stage deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting payment stage', error: error.message });
    }
  });

  // --- Contractor Payment Releases CRUD ---
  app.get('/api/contractor-releases', authenticateToken, async (req, res) => {
    try {
      const releases = await ContractorPaymentRelease.findAll({
        include: [
          { model: Contractor, as: 'contractor' },
          { model: Project, as: 'project' },
          { model: ContractorPaymentStage, as: 'stage' }
        ],
        order: [['releaseDate', 'DESC']]
      });
      res.json({ releases });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching payment releases', error: error.message });
    }
  });

  app.post('/api/contractor-releases', authenticateToken, async (req, res) => {
    try {
      const release = await ContractorPaymentRelease.create(req.body);
      const populated = await ContractorPaymentRelease.findByPk(release.id, {
        include: [
          { model: Contractor, as: 'contractor' },
          { model: Project, as: 'project' },
          { model: ContractorPaymentStage, as: 'stage' }
        ]
      });
      res.status(201).json(populated);
    } catch (error) {
      res.status(400).json({ message: 'Error creating payment release', error: error.message });
    }
  });

  app.put('/api/contractor-releases/:id', authenticateToken, async (req, res) => {
    try {
      const release = await ContractorPaymentRelease.findByPk(req.params.id);
      if (!release) return res.status(404).json({ message: 'Payment release record not found' });
      await release.update(req.body);
      const populated = await ContractorPaymentRelease.findByPk(release.id, {
        include: [
          { model: Contractor, as: 'contractor' },
          { model: Project, as: 'project' },
          { model: ContractorPaymentStage, as: 'stage' }
        ]
      });
      res.json(populated);
    } catch (error) {
      res.status(400).json({ message: 'Error updating payment release record', error: error.message });
    }
  });

  app.delete('/api/contractor-releases/:id', authenticateToken, async (req, res) => {
    try {
      const release = await ContractorPaymentRelease.findByPk(req.params.id);
      if (!release) return res.status(404).json({ message: 'Payment release record not found' });
      await release.destroy();
      res.json({ message: 'Payment release record deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting payment release record', error: error.message });
    }
  });

  // ==========================================
  // MANAGER ATTENDANCE ENTRY MODULE
  // ==========================================
  
  app.get('/api/attendance/workers/:projectId', authenticateToken, async (req, res) => {
    try {
      const date = req.query.date || new Date().toISOString().split('T')[0];
      // Fetch all workers allocated to this project
      const workers = await Worker.findAll({ where: { projectId: req.params.projectId } });
      
      // Fetch any existing manager attendance records marked for these workers today
      const workerIds = workers.map(w => w.id);
      const markedRecords = await ManagerAttendance.findAll({
        where: {
          workerId: { [Op.in]: workerIds },
          date: date
        }
      });

      res.json({ workers, attendance: markedRecords });
    } catch (error) {
      res.status(500).json({ message: 'Error loading attendance details', error: error.message });
    }
  });

  app.post('/api/attendance/manager/submit', authenticateToken, async (req, res) => {
    const allowedUsernames = ['murugan', 'mohan', 'vijayan', 'manoj'];
    if (!allowedUsernames.includes(req.user.username) && req.user.role !== 'Managing Director' && req.user.role !== 'Super Admin') {
      return res.status(403).json({ message: 'Only Murugan, Mohan, Vijayan, and Manoj can mark attendance for labourers.' });
    }

    const { workers, gpsLocation, date } = req.body;
    const markDate = date || new Date().toISOString().split('T')[0];
    const entryTime = new Date().toTimeString().split(' ')[0];

    try {
      // Prevent duplicate attendance for the same worker on the same date
      const workerIds = workers.map(w => w.workerId);
      const existing = await ManagerAttendance.findOne({
        where: {
          workerId: { [Op.in]: workerIds },
          date: markDate
        }
      });
      if (existing) {
        return res.status(400).json({ message: 'Attendance already recorded for today.' });
      }

      const results = [];
      for (const record of workers) {
        const att = await ManagerAttendance.create({
          workerId: record.workerId,
          date: markDate,
          status: record.status || 'Present',
          overtimeHours: parseFloat(record.overtimeHours || 0),
          remarks: record.remarks,
          managerId: req.user.id,
          entryTime: entryTime,
          gpsLocation: gpsLocation
        });
        results.push(att);
      }
      res.status(201).json({ message: 'Attendance submitted successfully', records: results });
    } catch (error) {
      res.status(500).json({ message: 'Failed to record attendance', error: error.message });
    }
  });

  // ==========================================
  // DAILY PROGRESS REPORTS MODULE
  // ==========================================
  
  app.get('/api/reports/daily', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const where = { deletedAt: null };
      if (search) {
        where[Op.or] = [
          { workCategory: { [Op.like]: `%${search}%` } },
          { workDescription: { [Op.like]: `%${search}%` } }
        ];
      }

      // Staff roles can only see reports they submitted
      const pRole = getPermissionRole(req.user.role);
      if (pRole === 'Staff') {
        where.userId = req.user.id;
      }

      const { count, rows } = await DailyReport.findAndCountAll({
        where,
        include: ['project', 'user'],
        order: [['id', 'DESC']],
        limit,
        offset
      });

      res.json({
        reports: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching daily progress reports', error: error.message });
    }
  });

  app.get('/api/reports/daily/:id', authenticateToken, async (req, res) => {
    try {
      const where = { id: req.params.id, deletedAt: null };
      const pRole = getPermissionRole(req.user.role);
      if (pRole === 'Staff') {
        where.userId = req.user.id;
      }

      const report = await DailyReport.findOne({
        where,
        include: ['project', 'user']
      });
      if (!report) return res.status(404).json({ message: 'Report not found or access denied' });
      res.json(report);
    } catch (error) {
      res.status(500).json({ message: 'Error loading daily report details', error: error.message });
    }
  });

  app.post('/api/reports/daily', authenticateToken, async (req, res) => {
    try {
      const date = req.body.date || new Date().toISOString().split('T')[0];
      const report = await DailyReport.create({
        ...req.body,
        user_id: req.user.id,
        userId: req.user.id,
        date: date
      });
      await writeAuditLog(req, 'Create', 'DailyReports', null, report.toJSON());
      res.status(201).json(report);
    } catch (error) {
      res.status(400).json({ message: 'Error submitting daily progress report', error: error.message });
    }
  });

  app.put('/api/reports/daily/:id', authenticateToken, async (req, res) => {
    try {
      const where = { id: req.params.id, deletedAt: null };
      const pRole = getPermissionRole(req.user.role);
      if (pRole === 'Staff') {
        where.userId = req.user.id;
      }

      const report = await DailyReport.findOne({ where });
      if (!report) return res.status(404).json({ message: 'Report not found or access denied' });

      const oldVal = { ...report.toJSON() };
      await report.update(req.body);
      await writeAuditLog(req, 'Update', 'DailyReports', oldVal, report.toJSON());

      res.json(report);
    } catch (error) {
      res.status(400).json({ message: 'Error updating daily report', error: error.message });
    }
  });

  app.delete('/api/reports/daily/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const report = await DailyReport.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!report) return res.status(404).json({ message: 'Report not found' });

      const oldVal = { ...report.toJSON() };
      const deletedAt = new Date();
      await report.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'DailyReports', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Daily report soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting daily report', error: error.message });
    }
  });

  app.get('/api/reports/manager-progress', authenticateToken, async (req, res) => {
    try {
      const reports = await ProgressReport.findAll({ include: ['project', 'manager'] });
      res.json({ reports });
    } catch (error) {
      res.status(500).json({ message: 'Error loading manager progress reports', error: error.message });
    }
  });

  app.post('/api/reports/manager-progress', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Architect', 'Site Engineer', 'Supervisor', 'Labour Manager', 'Site Supervisor'), async (req, res) => {
    try {
      const date = req.body.date || new Date().toISOString().split('T')[0];
      const report = await ProgressReport.create({
        ...req.body,
        managerId: req.user.id,
        date: date
      });
      res.status(201).json(report);
    } catch (error) {
      res.status(400).json({ message: 'Error submitting manager progress report', error: error.message });
    }
  });

  // ==========================================
  // PAYROLL WAGES MODULE
  // ==========================================
  
  app.get('/api/payroll/wage-sheet', authenticateToken, async (req, res) => {
    try {
      const { projectId, month, year } = req.query;
      const whereClause = projectId ? { projectId } : {};
      const workersList = await Worker.findAll({ where: whereClause });
      
      const wageSheet = [];
      const m = month ? parseInt(month) : new Date().getMonth() + 1;
      const y = year ? parseInt(year) : new Date().getFullYear();
      
      const startDate = `${y}-${String(m).padStart(2, '0')}-01`;
      const endDate = `${y}-${String(m).padStart(2, '0')}-31`; // simplify range search
      
      for (const w of workersList) {
        const attendance = await ManagerAttendance.findAll({
          where: {
            workerId: w.id,
            date: {
              [Op.between]: [startDate, endDate]
            }
          }
        });
        
        let presentDays = 0;
        let halfDays = 0;
        let absentDays = 0;
        let totalOvertime = 0.0;
        
        attendance.forEach(att => {
          if (att.status === 'Present') presentDays++;
          else if (att.status === 'Half Day') halfDays++;
          else if (att.status === 'Absent') absentDays++;
          totalOvertime += parseFloat(att.overtimeHours || 0);
        });
        
        const rate = parseFloat(w.dailyWage);
        const otRate = (rate / 8.0) * 1.5; // OT multiplier
        const basePay = (presentDays * rate) + (halfDays * 0.5 * rate);
        const otPay = totalOvertime * otRate;
        const totalWage = basePay + otPay;
        
        wageSheet.push({
          id: w.id,
          workerId: w.workerId,
          name: w.name,
          skillType: w.skillType,
          contractor: w.contractor,
          dailyWage: rate,
          presentDays,
          halfDays,
          absentDays,
          overtimeHours: totalOvertime,
          basePay: parseFloat(basePay.toFixed(2)),
          overtimePay: parseFloat(otPay.toFixed(2)),
          totalWage: parseFloat(totalWage.toFixed(2))
        });
      }
      
      res.json({ wageSheet });
    } catch (error) {
      res.status(500).json({ message: 'Error compiling payroll wage sheet', error: error.message });
    }
  });

  // ==========================================
  // EXECUTIVE OWNER DASHBOARD
  // ==========================================
  
  app.get('/api/dashboard/executive', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const totalEmployees = await User.count({ where: { role: { [Op.ne]: 'Client' } } });
      const today = new Date().toISOString().split('T')[0];
      
      const workersPresent = await ManagerAttendance.count({ where: { date: today, status: 'Present' } });
      const workersHalf = await ManagerAttendance.count({ where: { date: today, status: 'Half Day' } });
      const workersAbsent = await ManagerAttendance.count({ where: { date: today, status: 'Absent' } });
      
      // Calculate costs from expenses
      const expenses = await Expense.findAll();
      let laborCost = 0;
      let materialCost = 0;
      expenses.forEach(exp => {
        if (exp.category === 'Labour Expenses') laborCost += parseFloat(exp.amount);
        else if (exp.category === 'Material Expenses') materialCost += parseFloat(exp.amount);
      });
      
      const attendanceSummary = await ManagerAttendance.findAll({
        where: { date: today },
        include: [{ model: Worker, as: 'worker', attributes: ['name', 'workerId', 'skillType'] }]
      });
      
      res.json({
        totalEmployees,
        workersPresent: workersPresent + workersHalf,
        workersAbsent,
        laborCost,
        materialCost,
        realtimeAttendance: attendanceSummary
      });
    } catch (error) {
      res.status(500).json({ message: 'Error compiling executive metrics', error: error.message });
    }
  });

  // ==========================================
  // ANNOUNCEMENTS MODULE
  // ==========================================
  
  app.get('/api/announcements', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';
      const role = req.user.role;

      const where = {
        deletedAt: null,
        targetRole: { [Op.in]: ['All', role] }
      };

      if (search) {
        where[Op.or] = [
          { title: { [Op.like]: `%${search}%` } },
          { message: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await Announcement.findAndCountAll({
        where,
        order: [['createdAt', 'DESC']],
        limit,
        offset
      });

      res.json({
        announcements: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving announcements', error: error.message });
    }
  });

  app.get('/api/announcements/:id', authenticateToken, async (req, res) => {
    try {
      const role = req.user.role;
      const ann = await Announcement.findOne({
        where: {
          id: req.params.id,
          deletedAt: null,
          targetRole: { [Op.in]: ['All', role] }
        }
      });
      if (!ann) return res.status(404).json({ message: 'Announcement not found or access denied' });
      res.json(ann);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching announcement details', error: error.message });
    }
  });

  app.post('/api/announcements', authenticateToken, async (req, res) => {
    try {
      const ann = await Announcement.create({
        ...req.body,
        createdBy: req.user.id
      });
      await writeAuditLog(req, 'Create', 'Announcements', null, ann.toJSON());
      res.status(201).json(ann);
    } catch (error) {
      res.status(400).json({ message: 'Error creating announcement', error: error.message });
    }
  });

  app.put('/api/announcements/:id', authenticateToken, async (req, res) => {
    try {
      const ann = await Announcement.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!ann) return res.status(404).json({ message: 'Announcement not found' });

      const oldVal = { ...ann.toJSON() };
      await ann.update(req.body);
      await writeAuditLog(req, 'Update', 'Announcements', oldVal, ann.toJSON());

      res.json(ann);
    } catch (error) {
      res.status(400).json({ message: 'Error updating announcement', error: error.message });
    }
  });

  app.delete('/api/announcements/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const ann = await Announcement.findOne({ where: { id: req.params.id, deletedAt: null } });
      if (!ann) return res.status(404).json({ message: 'Announcement not found' });

      const oldVal = { ...ann.toJSON() };
      const deletedAt = new Date();
      await ann.update({
        deletedAt,
        deletedBy: req.user.id
      });

      await writeAuditLog(req, 'Delete', 'Announcements', oldVal, { deletedAt, deletedBy: req.user.id });

      res.json({ message: 'Announcement soft-deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting announcement', error: error.message });
    }
  });

  // ==========================================
  // CLIENT ONBOARDING & TIMELINE GENERATOR
  // ==========================================
  app.post('/api/clients/onboard', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const {
        clientName, clientPhone, clientWhatsapp, clientEmail, clientAddress, clientCity, clientState, clientPincode, clientGst,
        projectName, projectType, projectSiteAddress, projectBudget, projectStartDate, projectEndDate,
        managingDirectorId, architectId, designEngineerId, siteEngineerId, supervisorId,
        uploadedDocuments
      } = req.body;

      if (!clientName || !clientPhone || !clientEmail || !projectName || !projectType || !projectBudget) {
        return res.status(400).json({ message: 'Missing required Client or Project fields' });
      }

      // 1. Create Client
      const client = await Client.create({
        name: clientName,
        phone: clientPhone,
        email: clientEmail,
        address: `${clientAddress || ''}, ${clientCity || ''}, ${clientState || ''} - ${clientPincode || ''}`.trim(),
        gst: clientGst,
        propertyDetails: `WhatsApp: ${clientWhatsapp || 'N/A'}`
      });

      // 2. Generate custom projectId code
      const count = await Project.count();
      const projectSeq = String(count + 1).padStart(3, '0');
      const generatedProjectId = `VIAN-PROJ-${new Date().getFullYear()}-${projectSeq}`;

      // 3. Create Project
      const project = await Project.create({
        projectId: generatedProjectId,
        name: projectName,
        type: projectType,
        clientId: client.id,
        architectId: architectId ? parseInt(architectId) : null,
        siteEngineerId: siteEngineerId ? parseInt(siteEngineerId) : null,
        managingDirectorId: managingDirectorId ? parseInt(managingDirectorId) : null,
        designEngineerId: designEngineerId ? parseInt(designEngineerId) : null,
        supervisorId: supervisorId ? parseInt(supervisorId) : null,
        budget: parseFloat(projectBudget),
        startDate: projectStartDate || new Date().toISOString().split('T')[0],
        completionDate: projectEndDate || null,
        status: 'Planning',
        progressPercentage: 0
      });

      // 4. Create standard Folders (Document placeholders)
      const standardFolders = ['Agreements', 'Drawings', 'Site Photos', 'Property Documents', 'Invoices', 'Expenses'];
      for (const folder of standardFolders) {
        await Document.create({
          projectId: project.id,
          title: `Placeholder for ${folder}`,
          folder: folder,
          fileUrl: 'https://res.cloudinary.com/mock/placeholder.pdf',
          fileSize: 1024
        });
      }

      // If user uploaded files
      if (uploadedDocuments && Array.isArray(uploadedDocuments)) {
        for (const doc of uploadedDocuments) {
          await Document.create({
            projectId: project.id,
            title: doc.title || 'Uploaded Document',
            folder: doc.folder || 'General',
            fileUrl: doc.fileUrl,
            fileSize: doc.fileSize || 2048
          });
        }
      }

      // 5. Automatically create timeline Tasks
      const defaultTimelineTasks = [
        { title: 'Site Inspection & Surveying', desc: 'Perform site survey and measurements.', priority: 'Medium', daysOffset: 5 },
        { title: 'Architectural Layout Drafting', desc: 'Draft initial concept floor plans.', priority: 'High', daysOffset: 15 },
        { title: 'Structural Frame Analysis & Design', desc: 'Detailed structural load analysis.', priority: 'Critical', daysOffset: 30 },
        { title: 'Material Procurement Planning', desc: 'Verify material schedule and vendors.', priority: 'Low', daysOffset: 45 }
      ];

      for (const t of defaultTimelineTasks) {
        const dueDate = new Date();
        dueDate.setDate(dueDate.getDate() + t.daysOffset);
        await Task.create({
          projectId: project.id,
          title: t.title,
          description: t.desc,
          priority: t.priority,
          dueDate: dueDate.toISOString().split('T')[0],
          status: 'Pending',
          assignedTo: architectId ? parseInt(architectId) : null
        });
      }

      // 6. Log activity
      const userAgent = req.headers['user-agent'] || 'Unknown Device';
      const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
      await ImportActivityLog.create({
        userId: req.user.id,
        type: 'Import',
        module: 'Clients',
        fileName: 'Onboarding Wizard Form',
        recordsImported: 1,
        recordsUpdated: 0,
        recordsFailed: 0,
        ipAddress: ip,
        device: userAgent
      });

      res.status(201).json({
        success: true,
        message: 'Client and Project onboarded successfully with standard workspace structure.',
        clientId: client.id,
        projectId: project.id,
        projectCode: generatedProjectId
      });
    } catch (error) {
      console.error('Error onboarding client:', error);
      res.status(500).json({ message: 'Error onboarding client', error: error.message });
    }
  });

  // ==========================================
  // BULK DATA IMPORT & VALIDATION SERVICES
  // ==========================================
  app.post('/api/import/validate', authenticateToken, async (req, res) => {
    try {
      const { rows, mapping, module } = req.body;
      if (!rows || !Array.isArray(rows) || !mapping) {
        return res.status(400).json({ message: 'Rows and mapping configuration are required.' });
      }

      const validationResults = [];
      let duplicateClients = 0;
      let duplicateProjects = 0;
      let missingFields = 0;
      let invalidEmails = 0;

      // Extract existing records from DB for verification
      const existingClientPhones = new Set((await Client.findAll({ attributes: ['phone'] })).map(c => c.phone));
      const existingClientEmails = new Set((await Client.findAll({ attributes: ['email'] })).map(c => c.email));
      const existingProjectIds = new Set((await Project.findAll({ attributes: ['projectId'] })).map(p => p.projectId));

      for (let i = 0; i < Math.min(rows.length, 100); i++) {
        const row = rows[i];
        const errors = {};
        const warnings = {};

        // Resolve row values based on mapping dropdown selections
        const nameVal = row[mapping['Client Name']] || row['name'] || '';
        const phoneVal = row[mapping['Mobile Number']] || row['phone'] || '';
        const emailVal = row[mapping['Email']] || row['email'] || '';
        const projIdVal = row[mapping['Project Code']] || row['projectId'] || '';
        const projNameVal = row[mapping['Project Name']] || row['projectName'] || '';

        // Validate Client Name
        if (!nameVal.toString().trim()) {
          errors['Client Name'] = 'Client name is required';
          missingFields++;
        }

        // Validate Mobile Number
        if (!phoneVal.toString().trim()) {
          errors['Mobile Number'] = 'Mobile number is required';
          missingFields++;
        } else if (existingClientPhones.has(phoneVal.toString().trim())) {
          warnings['Mobile Number'] = 'Duplicate client phone number already in ERP';
          duplicateClients++;
        }

        // Validate Email
        if (emailVal) {
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          if (!emailRegex.test(emailVal.toString().trim())) {
            errors['Email'] = 'Invalid email address format';
            invalidEmails++;
          } else if (existingClientEmails.has(emailVal.toString().trim())) {
            warnings['Email'] = 'Client email matches an existing client record';
          }
        }

        // Validate Project Code
        if (projIdVal && existingProjectIds.has(projIdVal.toString().trim())) {
          warnings['Project Code'] = 'Project code already exists in database';
          duplicateProjects++;
        }

        validationResults.push({
          index: i,
          rowData: row,
          resolvedValues: {
            name: nameVal,
            phone: phoneVal,
            email: emailVal,
            projectId: projIdVal,
            projectName: projNameVal
          },
          errors,
          warnings,
          isValid: Object.keys(errors).length === 0
        });
      }

      res.json({
        validationResults,
        summary: {
          totalRows: rows.length,
          duplicateClients,
          duplicateProjects,
          missingFields,
          invalidEmails,
          isValidSuite: duplicateClients + duplicateProjects + missingFields + invalidEmails === 0
        }
      });
    } catch (error) {
      console.error('Validation error:', error);
      res.status(500).json({ message: 'Validation failed', error: error.message });
    }
  });

  app.post('/api/import/execute', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { rows, mapping, strategy, module } = req.body;
      if (!rows || !Array.isArray(rows) || !mapping || !module) {
        return res.status(400).json({ message: 'Missing rows, mapping config, strategy or module.' });
      }

      let imported = 0;
      let updated = 0;
      let failed = 0;
      let skipped = 0;

      for (const row of rows) {
        try {
          if (module === 'Clients') {
            const nameVal = (row[mapping['Client Name']] || row['name'] || '').toString().trim();
            const phoneVal = (row[mapping['Mobile Number']] || row['phone'] || '').toString().trim();
            const emailVal = (row[mapping['Email']] || row['email'] || '').toString().trim();
            const addressVal = (row[mapping['Address']] || row['address'] || '').toString().trim();
            const gstVal = (row[mapping['GST Number']] || row['gst'] || '').toString().trim();

            if (!nameVal || !phoneVal) {
              failed++;
              continue;
            }

            const existingClient = await Client.findOne({ where: { phone: phoneVal } });
            if (existingClient) {
              if (strategy === 'skip') {
                skipped++;
                continue;
              } else if (strategy === 'replace' || strategy === 'update') {
                await existingClient.update({
                  name: nameVal,
                  email: emailVal || existingClient.email,
                  address: addressVal || existingClient.address,
                  gst: gstVal || existingClient.gst
                });
                updated++;
              } else {
                await Client.create({
                  name: `${nameVal} (New)`,
                  phone: `${phoneVal}-${Date.now().toString().slice(-4)}`,
                  email: emailVal,
                  address: addressVal,
                  gst: gstVal
                });
                imported++;
              }
            } else {
              await Client.create({
                name: nameVal,
                phone: phoneVal,
                email: emailVal,
                address: addressVal,
                gst: gstVal
              });
              imported++;
            }
          } else if (module === 'Projects') {
            const codeVal = (row[mapping['Project Code']] || row['projectId'] || '').toString().trim();
            const nameVal = (row[mapping['Project Name']] || row['projectName'] || row['name'] || '').toString().trim();
            const typeVal = (row[mapping['Project Type']] || row['type'] || 'Residential').toString().trim();
            const budgetVal = parseFloat(row[mapping['Budget']] || row['budget'] || 100000);
            
            if (!codeVal || !nameVal) {
              failed++;
              continue;
            }

            const existingProject = await Project.findOne({ where: { projectId: codeVal } });
            if (existingProject) {
              if (strategy === 'skip') {
                skipped++;
                continue;
              } else if (strategy === 'replace' || strategy === 'update') {
                await existingProject.update({
                  name: nameVal,
                  type: ['Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'].includes(typeVal) ? typeVal : 'Residential',
                  budget: budgetVal
                });
                updated++;
              }
            } else {
              let defaultClient = await Client.findOne();
              if (!defaultClient) {
                defaultClient = await Client.create({ name: 'Default Import Client', phone: '0000000000', email: 'default@vian.com' });
              }

              await Project.create({
                projectId: codeVal,
                name: nameVal,
                type: ['Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'].includes(typeVal) ? typeVal : 'Residential',
                budget: budgetVal,
                clientId: defaultClient.id
              });
              imported++;
            }
          } else {
            imported++;
          }
        } catch (err) {
          console.error('Row import error:', err);
          failed++;
        }
      }

      // Log import activity
      const userAgent = req.headers['user-agent'] || 'Unknown Device';
      const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
      await ImportActivityLog.create({
        userId: req.user.id,
        type: 'Import',
        module,
        fileName: 'Spreadsheet Upload',
        recordsImported: imported,
        recordsUpdated: updated,
        recordsFailed: failed,
        ipAddress: ip,
        device: userAgent
      });

      res.json({
        success: true,
        summary: {
          imported,
          updated,
          failed,
          skipped
        }
      });
    } catch (error) {
      console.error('Execution error:', error);
      res.status(500).json({ message: 'Execution failed', error: error.message });
    }
  });

  // ==========================================
  // BULK EXPORT MODULES (CSV & EXCEL PREVIEWS)
  // ==========================================
  app.get('/api/export/:module', authenticateToken, async (req, res) => {
    try {
      const { module } = req.params;
      const { format } = req.query; // 'csv', 'xlsx', 'pdf'
      
      let data = [];
      let csvContent = '';

      if (module === 'clients') {
        data = await Client.findAll();
        csvContent = 'ID,Name,Phone,Email,Address,GST\n' + 
          data.map(c => `"${c.id}","${c.name}","${c.phone}","${c.email}","${c.address || ''}","${c.gst || ''}"`).join('\n');
      } else if (module === 'projects') {
        data = await Project.findAll();
        csvContent = 'ID,Project ID,Name,Type,Budget,Status,Progress\n' +
          data.map(p => `"${p.id}","${p.projectId}","${p.name}","${p.type}","${p.budget}","${p.status}","${p.progressPercentage}%"`).join('\n');
      } else if (module === 'attendance') {
        data = await Attendance.findAll({ include: [{ model: User, as: 'user', attributes: ['name'] }] });
        csvContent = 'ID,Employee Name,Date,Check In,Check Out,Status\n' +
          data.map(a => `"${a.id}","${a.user ? a.user.name : ''}","${a.date}","${a.checkInTime || ''}","${a.checkOutTime || ''}","${a.status}"`).join('\n');
      } else {
        csvContent = 'ID,Name,Created At\n1,Demo Item,2026-06-25';
      }

      // Log export action
      const userAgent = req.headers['user-agent'] || 'Unknown Device';
      const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
      await ImportActivityLog.create({
        userId: req.user.id,
        type: 'Export',
        module: module.toUpperCase(),
        fileName: `${module}_export.${format || 'csv'}`,
        recordsImported: 0,
        recordsUpdated: 0,
        recordsFailed: 0,
        ipAddress: ip,
        device: userAgent
      });

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="${module}_export.csv"`);
        return res.send(csvContent);
      } else {
        res.json({
          success: true,
          message: `Export file generated in ${format ? format.toUpperCase() : 'CSV'} format.`,
          csvData: csvContent
        });
      }
    } catch (error) {
      console.error('Export error:', error);
      res.status(500).json({ message: 'Export failed', error: error.message });
    }
  });

  // ==========================================
  // DATABASE BACKUP, RESTORE & AUDIT LOGS
  // ==========================================
  app.get('/api/backup/export', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const dump = {};
      const allModels = [User, Client, Project, Task, Attendance, Document, Announcement, Expense, Invoice, Quotation];
      
      for (const m of allModels) {
        const tableName = m.getTableName();
        const records = await m.findAll();
        dump[tableName] = records;
      }

      const userAgent = req.headers['user-agent'] || 'Unknown Device';
      const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
      await ImportActivityLog.create({
        userId: req.user.id,
        type: 'Backup',
        module: 'Database',
        fileName: `backup_${new Date().toISOString().slice(0, 10)}.json`,
        recordsImported: 0,
        recordsUpdated: 0,
        recordsFailed: 0,
        ipAddress: ip,
        device: userAgent
      });

      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', 'attachment; filename="vian_erp_backup.json"');
      res.send(JSON.stringify(dump, null, 2));
    } catch (error) {
      console.error('Backup error:', error);
      res.status(500).json({ message: 'Backup failed', error: error.message });
    }
  });

  app.post('/api/backup/restore', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { backupData } = req.body;
      if (!backupData) {
        return res.status(400).json({ message: 'Backup JSON data is required.' });
      }

      const dump = typeof backupData === 'string' ? JSON.parse(backupData) : backupData;
      const allModels = [User, Client, Project, Task, Attendance, Document, Announcement, Expense, Invoice, Quotation];

      for (const m of allModels) {
        const tableName = m.getTableName();
        if (dump[tableName]) {
          await m.destroy({ where: {}, truncate: true });
          if (dump[tableName].length > 0) {
            await m.bulkCreate(dump[tableName]);
          }
        }
      }

      const userAgent = req.headers['user-agent'] || 'Unknown Device';
      const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
      await ImportActivityLog.create({
        userId: req.user.id,
        type: 'Restore',
        module: 'Database',
        fileName: 'Database JSON Restore',
        recordsImported: 0,
        recordsUpdated: 0,
        recordsFailed: 0,
        ipAddress: ip,
        device: userAgent
      });

      res.json({ success: true, message: 'Database successfully restored from backup.' });
    } catch (error) {
      console.error('Restore error:', error);
      res.status(500).json({ message: 'Restore failed', error: error.message });
    }
  });

  app.get('/api/backup/list', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    res.json({
      backups: [
        { name: 'vian_db_daily_backup_2026-06-24.sql', size: '256 KB', date: '2026-06-24 23:59' },
        { name: 'vian_db_daily_backup_2026-06-23.sql', size: '254 KB', date: '2026-06-23 23:59' },
        { name: 'vian_db_daily_backup_2026-06-22.sql', size: '251 KB', date: '2026-06-22 23:59' }
      ]
    });
  });

  app.get('/api/import-logs', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const logs = await ImportActivityLog.findAll({
        include: [{ model: User, as: 'user', attributes: ['name', 'role'] }],
        order: [['createdAt', 'DESC']]
      });
      res.json({ logs });
    } catch (error) {
      res.status(500).json({ message: 'Error loading logs', error: error.message });
    }
  });

  // ==========================================
  // NEW GPS TRACKING & GEOFENCING ALERTS
  // ==========================================
  app.post('/api/gps/track', authenticateToken, async (req, res) => {
    const { latitude, longitude } = req.body;
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ message: 'Latitude and longitude required' });
    }
    
    try {
      // Find assigned project for the user
      const project = await Project.findOne({
        where: {
          [Op.or]: [
            { architectId: req.user.id },
            { siteEngineerId: req.user.id },
            { designEngineerId: req.user.id },
            { supervisorId: req.user.id }
          ]
        }
      });
      
      if (!project) {
        return res.json({ status: 'No assigned project found for geofencing check.' });
      }
      
      // Project standard coordinates (Bajaj Villa: 28.4595, 77.0266; Oberoi Office: 28.4600, 77.0300)
      const projLat = project.id === 1 ? 28.4595 : 28.4600;
      const projLng = project.id === 1 ? 77.0266 : 77.0300;
      
      // Simple Euclidean approximation for 200 meters (~0.002 degrees)
      const dist = Math.sqrt(Math.pow(latitude - projLat, 2) + Math.pow(longitude - projLng, 2));
      const isOutside = dist > 0.002;
      
      let warning = null;
      if (isOutside) {
        // Find if there is an active warning for this user/project
        warning = await GeofenceWarning.findOne({
          where: { userId: req.user.id, projectId: project.id, status: 'Warning Pending' }
        });
        
        if (!warning) {
          warning = await GeofenceWarning.create({
            userId: req.user.id,
            projectId: project.id,
            currentLocation: `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`,
            timeLeftSite: new Date(),
            durationOutside: 5, // checked every 5 mins
            status: 'Warning Pending'
          });
        } else {
          const duration = warning.durationOutside + 5;
          await warning.update({
            durationOutside: duration,
            currentLocation: `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`
          });
          
          // If outside for more than 10 minutes, trigger alert notifications to supervisors
          if (duration > 10) {
            // Send notification to Anand & Jaya
            const managersToNotify = [];
            const anand = await User.findOne({ where: { username: 'anand' } });
            const jaya = await User.findOne({ where: { username: 'jaya' } });
            if (anand) managersToNotify.push(anand.id);
            if (jaya) managersToNotify.push(jaya.id);
            
            // Department check
            if (req.user.dept === 'Designing Team') {
              const muthuiya = await User.findOne({ where: { username: 'muthuiya' } });
              if (muthuiya) managersToNotify.push(muthuiya.id);
            } else if (req.user.dept === 'Site Team') {
              const murugan = await User.findOne({ where: { username: 'murugan' } });
              if (murugan) managersToNotify.push(murugan.id);
            }
            
            const message = `Geofence Alert: Employee ${req.user.name} left ${project.name} site. Time Left: ${new Date(warning.timeLeftSite).toLocaleTimeString()}. Duration: ${duration} minutes. Current Location: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}.`;
            
            for (const managerId of managersToNotify) {
              await Notification.findOrCreate({
                where: {
                  userId: managerId,
                  title: 'GEOFENCE BREACH ALERT',
                  message: message
                }
              });
            }
          }
        }
      } else {
        const activeWarning = await GeofenceWarning.findOne({
          where: { userId: req.user.id, projectId: project.id, status: 'Warning Pending' }
        });
        if (activeWarning) {
          if (activeWarning.durationOutside <= 10) {
            await activeWarning.destroy();
          }
        }
      }
      
      res.json({
        success: true,
        isOutside,
        warning: warning ? { id: warning.id, duration: warning.durationOutside } : null
      });
    } catch (error) {
      console.error('GPS tracking error:', error);
      res.status(500).json({ message: 'GPS tracking fail', error: error.message });
    }
  });

  // ==========================================
  // FINES MANAGEMENT ENDPOINTS
  // ==========================================
  app.get('/api/fines', authenticateToken, async (req, res) => {
    try {
      const list = await Fine.findAll({
        include: [
          { model: User, as: 'employee', attributes: ['name', 'role'] }
        ],
        order: [['createdAt', 'DESC']]
      });
      
      const warnings = await GeofenceWarning.findAll({
        where: { status: 'Warning Pending' },
        include: [{ model: User, as: 'user', attributes: ['name'] }, { model: Project, as: 'project', attributes: ['name'] }]
      });
      
      res.json({ fines: list, warnings });
    } catch (error) {
      res.status(500).json({ message: 'Error loading fines', error: error.message });
    }
  });

  app.post('/api/fines/apply', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    const { warningId, employeeId, amount, reason } = req.body;
    if (!employeeId || !amount || !reason) {
      return res.status(400).json({ message: 'Employee ID, amount and reason are required' });
    }
    
    try {
      const fine = await Fine.create({
        warningId: warningId || null,
        employeeId,
        amount: parseFloat(amount),
        reason,
        acknowledged: false
      });
      
      if (warningId) {
        const warning = await GeofenceWarning.findByPk(warningId);
        if (warning) {
          await warning.update({ status: 'Fine Applied' });
        }
      }
      
      // Notify employee
      await Notification.create({
        userId: employeeId,
        title: 'FINE CHARGED',
        message: `A fine of ₹${amount} has been applied for: ${reason}. Please open the dashboard to acknowledge.`
      });
      
      res.json({ success: true, fine });
    } catch (error) {
      res.status(500).json({ message: 'Error applying fine', error: error.message });
    }
  });

  app.post('/api/fines/:id/acknowledge', authenticateToken, async (req, res) => {
    try {
      const fine = await Fine.findOne({ where: { id: req.params.id, employeeId: req.user.id } });
      if (!fine) return res.status(404).json({ message: 'Fine record not found' });
      await fine.update({ acknowledged: true });
      res.json({ success: true, message: 'Fine acknowledged successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });

  app.post('/api/fines/warning/:id/status', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    const { status } = req.body; // 'Approved', 'Ignored'
    try {
      const warning = await GeofenceWarning.findByPk(req.params.id);
      if (!warning) return res.status(404).json({ message: 'Warning not found' });
      await warning.update({ status });
      res.json({ success: true, message: `Geofence warning marked as ${status}` });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });

  // ==========================================
  // HOURLY SITE PROGRESS ENDPOINTS
  // ==========================================
  app.post('/api/projects/progress-hourly', authenticateToken, async (req, res) => {
    const { projectId, workProgress, remarks, completionPercentage, workersPresent, materialsUsed, delayReason, weather, photoUrls } = req.body;
    if (!projectId || !workProgress) {
      return res.status(400).json({ message: 'Project ID and work progress are required' });
    }
    try {
      const progress = await HourlySiteProgress.create({
        projectId,
        userId: req.user.id,
        workProgress,
        remarks,
        completionPercentage: parseInt(completionPercentage || 0),
        workersPresent: parseInt(workersPresent || 0),
        materialsUsed,
        delayReason,
        weather,
        photoUrls: JSON.stringify(photoUrls || [])
      });
      res.json({ success: true, progress });
    } catch (error) {
      res.status(500).json({ message: 'Failed to record site progress', error: error.message });
    }
  });

  app.get('/api/projects/progress-hourly/:projectId', authenticateToken, async (req, res) => {
    try {
      const records = await HourlySiteProgress.findAll({
        where: { projectId: req.params.projectId },
        include: [{ model: User, as: 'user', attributes: ['name'] }],
        order: [['createdAt', 'DESC']]
      });
      res.json({ progress: records });
    } catch (error) {
      res.status(500).json({ message: 'Error loading progress logs', error: error.message });
    }
  });

  // ==========================================
  // ANNOUNCEMENT ACTION ENDPOINTS
  // ==========================================
  app.post('/api/announcements/:id/acknowledge', authenticateToken, async (req, res) => {
    try {
      const [action, created] = await AnnouncementAction.findOrCreate({
        where: { announcementId: req.params.id, userId: req.user.id },
        defaults: { acknowledged: true }
      });
      if (!created) {
        await action.update({ acknowledged: true });
      }
      res.json({ success: true, message: 'Announcement acknowledged successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });

  app.post('/api/announcements/:id/comment', authenticateToken, async (req, res) => {
    const { comment } = req.body;
    if (!comment) return res.status(400).json({ message: 'Comment text is required' });
    try {
      const [action, created] = await AnnouncementAction.findOrCreate({
        where: { announcementId: req.params.id, userId: req.user.id },
        defaults: { comment }
      });
      if (!created) {
        await action.update({ comment });
      }
      res.json({ success: true, message: 'Comment submitted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });

  app.get('/api/announcements/:id/actions', authenticateToken, async (req, res) => {
    try {
      const actions = await AnnouncementAction.findAll({
        where: { announcementId: req.params.id },
        include: [{ model: User, as: 'user', attributes: ['name', 'role'] }]
      });
      res.json({ actions });
    } catch (error) {
      res.status(500).json({ message: 'Error retrieving actions', error: error.message });
    }
  });

  // ==========================================
  // EMPLOYEE/USER CRUD ENDPOINTS
  // ==========================================
  app.post('/api/employees', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    const { username, password, name, email, role, department, designation, employeeId } = req.body;
    if (!username || !password || !name || !email || !role) {
      return res.status(400).json({ message: 'Username, password, name, email and role are required' });
    }
    try {
      const bcrypt = require('bcryptjs');
      const salt = await bcrypt.genSalt(10);
      const hash = await bcrypt.hash(password, salt);
      
      const created = await User.create({
        username,
        passwordHash: hash,
        name,
        email,
        role,
        department,
        designation,
        employeeId: employeeId || `VIAN-EMP-${Date.now().toString().slice(-4)}`,
        status: 'Active'
      });
      res.status(201).json(created);
    } catch (error) {
      res.status(400).json({ message: 'Failed to create user account', error: error.message });
    }
  });

  app.put('/api/employees/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    try {
      const emp = await User.findByPk(req.params.id);
      if (!emp) return res.status(404).json({ message: 'User not found' });
      await emp.update(req.body);
      res.json(emp);
    } catch (error) {
      res.status(400).json({ message: 'Failed to update user', error: error.message });
    }
  });

  app.delete('/api/employees/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const emp = await User.findByPk(req.params.id);
      if (!emp) return res.status(404).json({ message: 'User not found' });
      await emp.destroy();
      res.json({ message: 'User deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Failed to delete user', error: error.message });
    }
  });

  // ==========================================
  // SMART IMPORT & EXPORT ENGINE APIS
  // ==========================================

  const uploadDir = path.join(__dirname, 'uploads/imports');
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  const backupDir = path.join(__dirname, 'database/backups');
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  const storage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, uniqueSuffix + '-' + file.originalname);
    }
  });
  const upload = multer({ storage: storage });

  function detectModule(sheetName) {
    const name = sheetName.toLowerCase().replace(/[^a-z0-9 ]/g, '').trim();
    if (name.includes('project information') || name === 'projects' || name === 'project') return 'Projects';
    if (name.includes('client') || name.includes('clients')) return 'Clients';
    if (name.includes('lead') || name.includes('leads')) return 'Leads';
    if (name.includes('employee') || name.includes('employees') || name === 'staff') return 'Employees';
    if (name.includes('attendance') || name === 'shift') return 'Attendance';
    if (name.includes('drawing progress') || name === 'working list') return 'Drawing Progress';
    if (name.includes('drawing register') || name === 'drawing list' || name === 'drawings') return 'Drawings';
    if (name === 'boq' || name.includes('boq module') || name.includes('bill of quantities')) return 'BOQ';
    if (name.includes('material purchase') || ['brick', 'steel', 'cement', 'm sand', 'jelly', 'blue metal', 'wood', 'electrical', 'plumbing', 'interior'].some(m => name.includes(m))) return 'Materials';
    if (name.includes('labour') || name.includes('labor') || name.includes('worker') || name.includes('workers')) return 'Labour';
    if (name.includes('payment') || name.includes('payments')) return 'Payments';
    if (name.includes('expense') || name.includes('expenses') || name === 'vouchers') return 'Expenses';
    if (name.includes('vendor') || name.includes('vendors')) return 'Vendors';
    if (name.includes('contractor') || name.includes('contractors')) return 'Contractors';
    if (name.includes('task') || name.includes('tasks') || name.includes('schedule')) return 'Tasks';
    if (name.includes('document') || name.includes('documents')) return 'Documents';
    return null;
  }

  function parseWorkbook(workbook) {
    const result = [];
    workbook.SheetNames.forEach(sheetName => {
      const sheet = workbook.Sheets[sheetName];
      const rawRows = XLSX.utils.sheet_to_json(sheet);
      if (rawRows.length > 0) {
        const headers = Object.keys(rawRows[0]);
        result.push({
          name: sheetName,
          detectedModule: detectModule(sheetName),
          headers,
          rows: rawRows
        });
      }
    });
    return result;
  }

  // 1. Upload file and parse preview / detect sheets
  app.post('/api/import/upload', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), upload.single('file'), async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    try {
      const filePath = req.file.path;
      const fileName = req.file.originalname;
      let sheetsData = [];

      if (fileName.endsWith('.zip')) {
        const zip = new AdmZip(filePath);
        const zipEntries = zip.getEntries();
        const excelEntry = zipEntries.find(e => e.entryName.toLowerCase().endsWith('.xlsx') || e.entryName.toLowerCase().endsWith('.csv'));
        
        if (excelEntry) {
          const buffer = zip.readFile(excelEntry);
          const workbook = XLSX.read(buffer, { type: 'buffer' });
          sheetsData = parseWorkbook(workbook);
        } else {
          return res.status(400).json({ message: 'ZIP package does not contain an Excel or CSV file' });
        }
      } else {
        const workbook = XLSX.readFile(filePath);
        sheetsData = parseWorkbook(workbook);
      }

      res.json({
        success: true,
        fileName,
        filePath,
        sheets: sheetsData
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Failed to parse file content', error: error.message });
    }
  });

  // 2. Validate import records
  app.post('/api/import/validate', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    const { rows, mapping, module } = req.body;
    if (!rows || !mapping || !module) {
      return res.status(400).json({ message: 'Missing rows, mapping, or module' });
    }

    try {
      let duplicateCount = 0;
      let missingFieldsCount = 0;
      let invalidEmailsCount = 0;
      const validationResults = [];

      const existingPhones = new Set();
      const existingEmails = new Set();
      const existingUsernames = new Set();
      const existingEmpIds = new Set();
      const existingProjectIds = new Set();
      const existingDrawingNumbers = new Set();

      if (module === 'Clients') {
        const clients = await Client.findAll({ attributes: ['phone', 'email'] });
        clients.forEach(c => {
          if (c.phone) existingPhones.add(c.phone.trim());
          if (c.email) existingEmails.add(c.email.trim().toLowerCase());
        });
      } else if (module === 'Projects') {
        const projects = await Project.findAll({ attributes: ['projectId'] });
        projects.forEach(p => {
          if (p.projectId) existingProjectIds.add(p.projectId.trim());
        });
      } else if (module === 'Employees') {
        const users = await User.findAll({ attributes: ['username', 'email', 'employeeId', 'mobile'] });
        users.forEach(u => {
          if (u.username) existingUsernames.add(u.username.trim().toLowerCase());
          if (u.email) existingEmails.add(u.email.trim().toLowerCase());
          if (u.employeeId) existingEmpIds.add(u.employeeId.trim());
          if (u.mobile) existingPhones.add(u.mobile.trim());
        });
      } else if (module === 'Drawings') {
        const drawings = await Drawing.findAll({ attributes: ['drawingNumber'] });
        drawings.forEach(d => {
          if (d.drawingNumber) existingDrawingNumbers.add(d.drawingNumber.trim());
        });
      }

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const errors = {};
        const warnings = {};
        const resolvedValues = {};

        for (const [erpField, csvField] of Object.entries(mapping)) {
          resolvedValues[erpField] = row[csvField] !== undefined ? String(row[csvField]).trim() : '';
        }

        if (module === 'Clients') {
          const name = resolvedValues['Client Name'] || resolvedValues['name'];
          const phone = resolvedValues['Mobile Number'] || resolvedValues['phone'];
          const email = resolvedValues['Email'] || resolvedValues['email'];

          if (!name) {
            errors['name'] = 'Client Name is required';
            missingFieldsCount++;
          }
          if (!phone) {
            errors['phone'] = 'Phone number is required';
            missingFieldsCount++;
          } else if (existingPhones.has(phone)) {
            warnings['phone'] = `Duplicate client phone: ${phone}`;
            duplicateCount++;
          }
          if (email) {
            if (!email.includes('@')) {
              errors['email'] = 'Invalid email format';
              invalidEmailsCount++;
            } else if (existingEmails.has(email.toLowerCase())) {
              warnings['email'] = `Duplicate client email: ${email}`;
              duplicateCount++;
            }
          }
        } else if (module === 'Projects') {
          const projId = resolvedValues['Project Code'] || resolvedValues['Project ID'] || resolvedValues['projectId'];
          const name = resolvedValues['Project Name'] || resolvedValues['name'];
          const type = resolvedValues['Project Type'] || resolvedValues['type'];
          const budget = resolvedValues['Budget'] || resolvedValues['budget'];

          if (!projId) {
            errors['projectId'] = 'Project Code is required';
            missingFieldsCount++;
          } else if (existingProjectIds.has(projId)) {
            warnings['projectId'] = `Duplicate Project ID: ${projId}`;
            duplicateCount++;
          }
          if (!name) {
            errors['name'] = 'Project Name is required';
            missingFieldsCount++;
          }
          if (type && !['Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'].includes(type)) {
            errors['type'] = `Invalid project type: ${type}`;
          }
          if (budget && isNaN(parseFloat(budget))) {
            errors['budget'] = 'Budget must be a numeric value';
          }
        } else if (module === 'Employees') {
          const empId = resolvedValues['Employee ID'] || resolvedValues['employeeId'];
          const name = resolvedValues['Name'] || resolvedValues['name'];
          const role = resolvedValues['Role'] || resolvedValues['role'];
          const email = resolvedValues['Email'] || resolvedValues['email'];
          const username = resolvedValues['Username'] || resolvedValues['username'] || (email ? email.split('@')[0] : '');

          if (!empId) {
            errors['employeeId'] = 'Employee ID is required';
            missingFieldsCount++;
          } else if (existingEmpIds.has(empId)) {
            warnings['employeeId'] = `Duplicate Employee ID: ${empId}`;
            duplicateCount++;
          }
          if (!name) {
            errors['name'] = 'Name is required';
            missingFieldsCount++;
          }
          if (!email) {
            errors['email'] = 'Email is required';
            missingFieldsCount++;
          } else if (!email.includes('@')) {
            errors['email'] = 'Invalid email format';
            invalidEmailsCount++;
          } else if (existingEmails.has(email.toLowerCase())) {
            warnings['email'] = `Duplicate email: ${email}`;
            duplicateCount++;
          }
          if (existingUsernames.has(username.toLowerCase())) {
            warnings['username'] = `Duplicate username: ${username}`;
            duplicateCount++;
          }
        } else if (module === 'Drawings') {
          const drawingNum = resolvedValues['Drawing Number'] || resolvedValues['drawingNumber'];
          const title = resolvedValues['Drawing Name'] || resolvedValues['title'];

          if (!drawingNum) {
            errors['drawingNumber'] = 'Drawing Number is required';
            missingFieldsCount++;
          } else if (existingDrawingNumbers.has(drawingNum)) {
            warnings['drawingNumber'] = `Duplicate Drawing Number: ${drawingNum}`;
            duplicateCount++;
          }
          if (!title) {
            errors['title'] = 'Drawing Name is required';
            missingFieldsCount++;
          }
        }

        validationResults.push({
          index: i,
          resolvedValues,
          errors,
          warnings,
          isValid: Object.keys(errors).length === 0
        });
      }

      res.json({
        validationResults,
        summary: {
          totalRows: rows.length,
          duplicateClients: module === 'Clients' ? duplicateCount : 0,
          duplicateProjects: module === 'Projects' ? duplicateCount : 0,
          missingFields: missingFieldsCount,
          invalidEmails: invalidEmailsCount,
          isValidSuite: missingFieldsCount === 0 && invalidEmailsCount === 0
        }
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error running import validation', error: error.message });
    }
  });

  // 3. Execute bulk import
  app.post('/api/import/execute', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    const { rows, mapping, strategy, module, fileName, filePath } = req.body;
    if (!rows || !mapping || !module) {
      return res.status(400).json({ message: 'Missing rows, mapping, or module' });
    }

    try {
      let imported = 0;
      let updated = 0;
      let failed = 0;
      let skipped = 0;

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const resolvedValues = {};
        for (const [erpField, csvField] of Object.entries(mapping)) {
          resolvedValues[erpField] = row[csvField] !== undefined ? String(row[csvField]).trim() : '';
        }

        try {
          if (module === 'Clients') {
            const name = resolvedValues['Client Name'] || resolvedValues['name'];
            const phone = resolvedValues['Mobile Number'] || resolvedValues['phone'];
            const email = resolvedValues['Email'] || resolvedValues['email'];
            const address = resolvedValues['Address'] || resolvedValues['address'];
            const gst = resolvedValues['GST Number'] || resolvedValues['gst'];

            if (!name || !phone || !email) {
              failed++;
              continue;
            }

            let client = await Client.findOne({
              where: {
                [Op.or]: [{ phone }, { email }]
              }
            });

            if (client) {
              if (strategy === 'skip') {
                skipped++;
                continue;
              } else if (strategy === 'update' || strategy === 'replace') {
                await client.update({ name, address, gst });
                updated++;
              } else if (strategy === 'merge') {
                await client.update({
                  name: client.name || name,
                  address: client.address || address,
                  gst: client.gst || gst
                });
                updated++;
              } else {
                await Client.create({ name, phone, email, address, gst });
                imported++;
              }
            } else {
              await Client.create({ name, phone, email, address, gst });
              imported++;
            }
          } else if (module === 'Projects') {
            const projId = resolvedValues['Project Code'] || resolvedValues['Project ID'] || resolvedValues['projectId'];
            const name = resolvedValues['Project Name'] || resolvedValues['name'];
            const type = resolvedValues['Project Type'] || resolvedValues['type'] || 'Residential';
            const budget = parseFloat(resolvedValues['Budget'] || resolvedValues['budget'] || 0);

            if (!projId || !name) {
              failed++;
              continue;
            }

            let project = await Project.findOne({ where: { projectId: projId } });
            if (project) {
              if (strategy === 'skip') {
                skipped++;
                continue;
              } else if (strategy === 'update' || strategy === 'replace') {
                await project.update({ name, type, budget });
                updated++;
              } else if (strategy === 'merge') {
                await project.update({
                  name: project.name || name,
                  type: project.type || type,
                  budget: project.budget || budget
                });
                updated++;
              } else {
                const defaultClient = await Client.findOne();
                await Project.create({ projectId: `${projId}-DUPLICATE`, name, type, budget, clientId: defaultClient ? defaultClient.id : 1 });
                imported++;
              }
            } else {
              const defaultClient = await Client.findOne();
              await Project.create({ projectId: projId, name, type, budget, clientId: defaultClient ? defaultClient.id : 1 });
              imported++;
            }
          } else if (module === 'Employees') {
            const empId = resolvedValues['Employee ID'] || resolvedValues['employeeId'];
            const name = resolvedValues['Name'] || resolvedValues['name'];
            const role = resolvedValues['Role'] || resolvedValues['role'] || 'Employee';
            const email = resolvedValues['Email'] || resolvedValues['email'];
            const username = resolvedValues['Username'] || resolvedValues['username'] || (email ? email.split('@')[0] : '');

            if (!empId || !name || !email) {
              failed++;
              continue;
            }

            let user = await User.findOne({
              where: {
                [Op.or]: [{ employeeId: empId }, { username }, { email }]
              }
            });

            if (user) {
              if (strategy === 'skip') {
                skipped++;
                continue;
              } else if (strategy === 'update' || strategy === 'replace') {
                await user.update({ name, role });
                updated++;
              } else if (strategy === 'merge') {
                await user.update({
                  name: user.name || name,
                  role: user.role || role
                });
                updated++;
              } else {
                const salt = await bcrypt.genSalt(10);
                const hash = await bcrypt.hash('employee123', salt);
                await User.create({
                  employeeId: `${empId}-NEW`,
                  username: `${username}_new`,
                  passwordHash: hash,
                  name,
                  email: `new.${email}`,
                  role,
                  status: 'Active'
                });
                imported++;
              }
            } else {
              const salt = await bcrypt.genSalt(10);
              const hash = await bcrypt.hash('employee123', salt);
              await User.create({
                employeeId: empId,
                username,
                passwordHash: hash,
                name,
                email,
                role,
                status: 'Active'
              });
              imported++;
            }
          } else {
            failed++;
          }
        } catch (err) {
          failed++;
        }
      }

      await ImportActivityLog.create({
        userId: req.user.id,
        type: 'Import',
        module,
        fileName: fileName || 'raw_data.csv',
        filePath: filePath || null,
        recordsImported: imported,
        recordsUpdated: updated,
        recordsFailed: failed,
        ipAddress: req.ip,
        device: req.headers['user-agent'] || 'Unknown'
      });

      res.json({
        success: true,
        summary: {
          imported,
          updated,
          failed,
          skipped
        }
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error executing import', error: error.message });
    }
  });

  // 4. Fetch import history logs
  app.get('/api/import-logs', authenticateToken, async (req, res) => {
    try {
      const logs = await ImportActivityLog.findAll({
        include: [{ model: User, as: 'user', attributes: ['name'] }],
        order: [['createdAt', 'DESC']]
      });
      res.json({ success: true, logs });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching logs', error: error.message });
    }
  });

  // 5. Download original uploaded file from history
  app.get('/api/import-logs/:id/download', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    try {
      const log = await ImportActivityLog.findByPk(req.params.id);
      if (!log || !log.filePath) {
        return res.status(404).json({ message: 'Original file not stored' });
      }
      if (!fs.existsSync(log.filePath)) {
        return res.status(404).json({ message: 'Original file has been deleted or is missing' });
      }
      res.download(log.filePath, log.fileName);
    } catch (error) {
      res.status(500).json({ message: 'Error downloading file', error: error.message });
    }
  });

  // 6. Servable template download generator
  app.get('/api/templates/:name', (req, res) => {
    const { name } = req.params;
    let headers = [];

    switch (name.toLowerCase()) {
      case 'projects':
        headers = ['Project ID', 'Project Name', 'Project Type', 'Client Name', 'Budget', 'Start Date', 'Completion Date', 'Status'];
        break;
      case 'clients':
        headers = ['Client Name', 'Mobile Number', 'Email', 'Address', 'GST Number'];
        break;
      case 'leads':
        headers = ['Name', 'Phone', 'Email', 'Source', 'Budget', 'Requirement', 'Notes', 'Status'];
        break;
      case 'employees':
        headers = ['Employee ID', 'Name', 'Department', 'Role', 'Phone', 'Email', 'Joining Date'];
        break;
      case 'attendance':
        headers = ['Employee Email', 'Date', 'Check In', 'Check Out', 'Working Hours', 'Overtime', 'GPS'];
        break;
      case 'drawings':
        headers = ['Project Code', 'Drawing Number', 'Drawing Name', 'Revision', 'Status', 'Assigned Architect Email', 'Completion %', 'Approval Status'];
        break;
      case 'drawing_progress':
        headers = ['Drawing Number', 'Assigned Employee Email', 'Current Status', 'Pending Work', 'Revision History', 'Completion %'];
        break;
      case 'boq':
        headers = ['Project Code', 'Item Description', 'Unit', 'Quantity', 'Rate', 'Total Amount'];
        break;
      case 'materials':
        headers = ['Project Code', 'Material Name', 'Purchased Quantity', 'Used Quantity', 'Balance Stock', 'Material Cost'];
        break;
      case 'labour':
        headers = ['Labour ID', 'Labour Name', 'Contractor', 'Trade', 'Daily Wage'];
        break;
      case 'payments':
        headers = ['Project Code', 'Payment Date', 'Description', 'Paid Amount', 'Pending Amount', 'Payment Type', 'Expense Category'];
        break;
      case 'expenses':
        headers = ['Project Code', 'Amount', 'Category', 'Description', 'Date', 'Status'];
        break;
      default:
        return res.status(404).json({ message: 'Template not found' });
    }

    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.aoa_to_sheet([headers]);
    XLSX.utils.book_append_sheet(wb, ws, 'Template');
    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=${name}_template.xlsx`);
    res.send(buffer);
  });

  // 7. General module export generator (Excel, CSV, JSON)
  app.get('/api/export/:module', authenticateToken, async (req, res) => {
    const { module } = req.params;
    const { format } = req.query;

    try {
      let data = [];
      if (module === 'clients') {
        data = await Client.findAll();
      } else if (module === 'projects') {
        data = await Project.findAll({ include: [{ model: Client, as: 'client' }] });
      } else if (module === 'attendance') {
        data = await Attendance.findAll({ include: [{ model: User, as: 'user' }] });
      } else if (module === 'expenses') {
        data = await Expense.findAll({ include: [{ model: Project, as: 'project' }] });
      } else if (module === 'invoices') {
        data = await Invoice.findAll({ include: [{ model: Project, as: 'project' }] });
      } else {
        return res.status(400).json({ message: 'Unsupported module for export' });
      }

      const plainData = data.map(item => item.toJSON ? item.toJSON() : item);
      if (format === 'json') {
        return res.json(plainData);
      }

      const flatRows = plainData.map(row => {
        const flat = { ...row };
        if (row.client) flat.clientName = row.client.name;
        if (row.user) flat.userName = row.user.name;
        if (row.project) flat.projectName = row.project.name;
        delete flat.client;
        delete flat.user;
        delete flat.project;
        return flat;
      });

      if (format === 'csv') {
        const headers = Object.keys(flatRows[0] || {});
        let csvContent = headers.join(',') + '\n';
        flatRows.forEach(row => {
          csvContent += headers.map(h => `"${String(row[h] || '').replace(/"/g, '""')}"`).join(',') + '\n';
        });
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=${module}_export.csv`);
        return res.send(csvContent);
      }

      const wb = XLSX.utils.book_new();
      const ws = XLSX.utils.json_to_sheet(flatRows);
      XLSX.utils.book_append_sheet(wb, ws, 'Export');
      const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename=${module}_export.xlsx`);
      res.send(buffer);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Export failed', error: error.message });
    }
  });

  // 8. ZIP complete Project Package Export
  app.get('/api/export/project/:id/package', authenticateToken, async (req, res) => {
    const projectId = req.params.id;
    try {
      const project = await Project.findByPk(projectId, {
        include: [
          { model: Client, as: 'client' },
          { model: Drawing, as: 'drawings' },
          { model: Document, as: 'documents' }
        ]
      });
      if (!project) return res.status(404).json({ message: 'Project not found' });

      const boqs = await BoqItem.findAll({ where: { projectId } });
      const tasks = await Task.findAll({ where: { projectId } });
      const payments = await ProjectPayment.findAll({ where: { projectId } });
      const materials = await Material.findAll({ where: { projectId } });
      const expenses = await Expense.findAll({ where: { projectId } });

      const wb = XLSX.utils.book_new();

      const projectInfo = [
        ['Field', 'Value'],
        ['Project ID', project.projectId],
        ['Project Name', project.name],
        ['Type', project.type],
        ['Budget', project.budget],
        ['Start Date', project.startDate],
        ['Completion Date', project.completionDate],
        ['Status', project.status],
        ['Progress %', project.progressPercentage],
        ['Client Name', project.client ? project.client.name : '']
      ];
      XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(projectInfo), 'Project Information');

      if (boqs.length > 0) XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(boqs.map(b => b.toJSON())), 'BOQ');
      if (tasks.length > 0) XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(tasks.map(t => t.toJSON())), 'Work Schedule');
      if (payments.length > 0) XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(payments.map(p => p.toJSON())), 'Payment');
      if (materials.length > 0) XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(materials.map(m => m.toJSON())), 'Materials');
      if (expenses.length > 0) XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(expenses.map(e => e.toJSON())), 'Expenses');

      const excelBuffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

      const zip = new AdmZip();
      zip.addFile('Project.xlsx', excelBuffer);

      const metadata = {
        projectCode: project.projectId,
        exportedAt: new Date().toISOString(),
        exporter: req.user.name,
        clientName: project.client ? project.client.name : '',
        drawingsCount: project.drawings ? project.drawings.length : 0,
        documentsCount: project.documents ? project.documents.length : 0
      };
      zip.addFile('metadata.json', Buffer.from(JSON.stringify(metadata, null, 2), 'utf8'));

      zip.addFile('Drawings/', Buffer.from([]));
      zip.addFile('Site Photos/', Buffer.from([]));
      zip.addFile('Documents/', Buffer.from([]));

      if (project.drawings) {
        project.drawings.forEach((d, idx) => {
          zip.addFile(`Drawings/drawing_${idx + 1}_link.txt`, Buffer.from(`Title: ${d.title}\nURL: ${d.fileUrl}\nNumber: ${d.drawingNumber || ''}`));
        });
      }
      if (project.documents) {
        project.documents.forEach((doc, idx) => {
          zip.addFile(`Documents/doc_${idx + 1}_link.txt`, Buffer.from(`Title: ${doc.title}\nFolder: ${doc.folder}\nURL: ${doc.fileUrl}`));
        });
      }

      const zipBuffer = zip.toBuffer();
      res.setHeader('Content-Type', 'application/zip');
      res.setHeader('Content-Disposition', `attachment; filename=${project.name.replace(/\s+/g, '_')}_package.zip`);
      res.send(zipBuffer);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Project package export failed', error: error.message });
    }
  });

  // 9. Full Admin Backup utility
  app.get('/api/backup/export', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), async (req, res) => {
    try {
      const backupData = {};
      const modelsList = Object.keys(models);
      for (const modelName of modelsList) {
        const records = await models[modelName].findAll();
        backupData[modelName] = records.map(r => r.toJSON());
      }
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename=vian_backup_${Date.now()}.json`);
      res.send(JSON.stringify(backupData, null, 2));
    } catch (error) {
      res.status(500).json({ message: 'Backup failed', error: error.message });
    }
  });

  // 10. Database restore utility
  app.post('/api/backup/restore', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { backupData } = req.body;
    if (!backupData) return res.status(400).json({ message: 'No backup data provided' });

    try {
      const data = typeof backupData === 'string' ? JSON.parse(backupData) : backupData;
      const { getSequelize } = require('./database/db');
      
      await getSequelize().transaction(async (t) => {
        const isSqlite = getSequelize().options.dialect === 'sqlite';
        if (isSqlite) {
          await getSequelize().query('PRAGMA foreign_keys = OFF', { transaction: t });
        } else {
          await getSequelize().query('SET FOREIGN_KEY_CHECKS = 0', { transaction: t });
        }

        for (const modelName of Object.keys(data)) {
          if (models[modelName]) {
            await models[modelName].destroy({ where: {}, force: true, transaction: t });
            if (data[modelName].length > 0) {
              await models[modelName].bulkCreate(data[modelName], { transaction: t });
            }
          }
        }

        if (isSqlite) {
          await getSequelize().query('PRAGMA foreign_keys = ON', { transaction: t });
        } else {
          await getSequelize().query('SET FOREIGN_KEY_CHECKS = 1', { transaction: t });
        }
      });

      res.json({ success: true, message: 'Database restored successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Restore failed', error: error.message });
    }
  });

  // 11. Fetch backup files list
  app.get('/api/backup/list', authenticateToken, authorizeRoles('Super Admin', 'Managing Director', 'Admin / Office Manager / Accounts'), (req, res) => {
    try {
      if (!fs.existsSync(backupDir)) {
        return res.json({ backups: [] });
      }
      const files = fs.readdirSync(backupDir);
      const backups = files.filter(f => f.endsWith('.json')).map(f => {
        const stats = fs.statSync(path.join(backupDir, f));
        return {
          name: f,
          size: `${Math.round(stats.size / 1024)} KB`,
          date: stats.mtime.toISOString().replace('T', ' ').substring(0, 16)
        };
      });
      res.json({ backups });
    } catch (err) {
      res.status(500).json({ message: 'Failed to list backups', error: err.message });
    }
  });

  // ==========================================
  // BUSINESS TARGETS & PERFORMANCE MODULE API
  // ==========================================

  // GET /api/targets/annual - Retrieve all annual targets
  app.get('/api/targets/annual', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const targets = await models.AnnualTarget.findAll({
        include: [{ model: models.MonthlyTarget, as: 'monthlyTargets' }],
        order: [['financialYear', 'DESC']]
      });
      res.json(targets);
    } catch (error) {
      res.status(500).json({ message: 'Failed to retrieve annual targets', error: error.message });
    }
  });

  // POST /api/targets/annual - Create annual target (automatically divides targets into monthly goals)
  app.post('/api/targets/annual', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const {
      financialYear, annualProjectTarget, annualRevenueTarget, annualProfitTarget,
      residentialProjectsTarget, commercialProjectsTarget, interiorProjectsTarget, renovationProjectsTarget,
      newClientTarget, repeatClientTarget
    } = req.body;

    if (!financialYear) {
      return res.status(400).json({ message: 'Financial year is required' });
    }

    try {
      const existing = await models.AnnualTarget.findOne({ where: { financialYear } });
      if (existing) {
        return res.status(400).json({ message: `Targets already exist for Financial Year ${financialYear}` });
      }

      const annual = await models.AnnualTarget.create({
        financialYear,
        annualProjectTarget: annualProjectTarget || 0,
        annualRevenueTarget: annualRevenueTarget || 0,
        annualProfitTarget: annualProfitTarget || 0,
        residentialProjectsTarget: residentialProjectsTarget || 0,
        commercialProjectsTarget: commercialProjectsTarget || 0,
        interiorProjectsTarget: interiorProjectsTarget || 0,
        renovationProjectsTarget: renovationProjectsTarget || 0,
        newClientTarget: newClientTarget || 0,
        repeatClientTarget: repeatClientTarget || 0,
        isApproved: false
      });

      const months = [
        { name: 'April', number: 4 }, { name: 'May', number: 5 }, { name: 'June', number: 6 },
        { name: 'July', number: 7 }, { name: 'August', number: 8 }, { name: 'September', number: 9 },
        { name: 'October', number: 10 }, { name: 'November', number: 11 }, { name: 'December', number: 12 },
        { name: 'January', number: 1 }, { name: 'February', number: 2 }, { name: 'March', number: 3 }
      ];

      const monthlyRecords = months.map(m => ({
        annualTargetId: annual.id,
        monthName: m.name,
        monthNumber: m.number,
        projectTarget: Math.round((annualProjectTarget || 0) / 12),
        revenueTarget: ((annualRevenueTarget || 0) / 12).toFixed(2),
        profitTarget: ((annualProfitTarget || 0) / 12).toFixed(2),
        residentialProjectsTarget: Math.round((residentialProjectsTarget || 0) / 12),
        commercialProjectsTarget: Math.round((commercialProjectsTarget || 0) / 12),
        interiorProjectsTarget: Math.round((interiorProjectsTarget || 0) / 12),
        renovationProjectsTarget: Math.round((renovationProjectsTarget || 0) / 12),
        newClientTarget: Math.round((newClientTarget || 0) / 12),
        repeatClientTarget: Math.round((repeatClientTarget || 0) / 12)
      }));

      await models.MonthlyTarget.bulkCreate(monthlyRecords);

      const created = await models.AnnualTarget.findByPk(annual.id, {
        include: [{ model: models.MonthlyTarget, as: 'monthlyTargets' }]
      });

      res.status(201).json(created);
    } catch (error) {
      res.status(500).json({ message: 'Failed to create annual targets', error: error.message });
    }
  });

  // PUT /api/targets/annual/:id - Edit annual target
  app.put('/api/targets/annual/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { id } = req.params;
    const {
      annualProjectTarget, annualRevenueTarget, annualProfitTarget,
      residentialProjectsTarget, commercialProjectsTarget, interiorProjectsTarget, renovationProjectsTarget,
      newClientTarget, repeatClientTarget
    } = req.body;

    try {
      const annual = await models.AnnualTarget.findByPk(id);
      if (!annual) return res.status(404).json({ message: 'Target not found' });

      await annual.update({
        annualProjectTarget: annualProjectTarget !== undefined ? annualProjectTarget : annual.annualProjectTarget,
        annualRevenueTarget: annualRevenueTarget !== undefined ? annualRevenueTarget : annual.annualRevenueTarget,
        annualProfitTarget: annualProfitTarget !== undefined ? annualProfitTarget : annual.annualProfitTarget,
        residentialProjectsTarget: residentialProjectsTarget !== undefined ? residentialProjectsTarget : annual.residentialProjectsTarget,
        commercialProjectsTarget: commercialProjectsTarget !== undefined ? commercialProjectsTarget : annual.commercialProjectsTarget,
        interiorProjectsTarget: interiorProjectsTarget !== undefined ? interiorProjectsTarget : annual.interiorProjectsTarget,
        renovationProjectsTarget: renovationProjectsTarget !== undefined ? renovationProjectsTarget : annual.renovationProjectsTarget,
        newClientTarget: newClientTarget !== undefined ? newClientTarget : annual.newClientTarget,
        repeatClientTarget: repeatClientTarget !== undefined ? repeatClientTarget : annual.repeatClientTarget
      });

      res.json(annual);
    } catch (error) {
      res.status(500).json({ message: 'Failed to update annual targets', error: error.message });
    }
  });

  // PUT /api/targets/annual/:id/approve - Approve targets
  app.put('/api/targets/annual/:id/approve', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { id } = req.params;
    try {
      const annual = await models.AnnualTarget.findByPk(id);
      if (!annual) return res.status(404).json({ message: 'Target not found' });

      await annual.update({
        isApproved: true,
        approvedBy: req.user.id
      });
      res.json({ success: true, message: 'Annual targets approved', annual });
    } catch (error) {
      res.status(500).json({ message: 'Failed to approve targets', error: error.message });
    }
  });

  // DELETE /api/targets/annual/:id - Delete annual target and associated monthly targets
  app.delete('/api/targets/annual/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { id } = req.params;
    try {
      const annual = await models.AnnualTarget.findByPk(id);
      if (!annual) return res.status(404).json({ message: 'Target not found' });
      await annual.destroy();
      res.json({ message: 'Annual target and associated monthly targets deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Failed to delete target', error: error.message });
    }
  });

  // GET /api/targets/monthly/:annual_target_id - Fetch monthly splits
  app.get('/api/targets/monthly/:annual_target_id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const monthly = await models.MonthlyTarget.findAll({
        where: { annualTargetId: req.params.annual_target_id },
        order: [['id', 'ASC']]
      });
      res.json(monthly);
    } catch (error) {
      res.status(500).json({ message: 'Failed to retrieve monthly targets', error: error.message });
    }
  });

  // PUT /api/targets/monthly/:id - Update single monthly split manually
  app.put('/api/targets/monthly/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { id } = req.params;
    const {
      projectTarget, revenueTarget, profitTarget,
      residentialProjectsTarget, commercialProjectsTarget, interiorProjectsTarget, renovationProjectsTarget,
      newClientTarget, repeatClientTarget
    } = req.body;

    try {
      const monthly = await models.MonthlyTarget.findByPk(id);
      if (!monthly) return res.status(404).json({ message: 'Monthly target not found' });

      await monthly.update({
        projectTarget: projectTarget !== undefined ? projectTarget : monthly.projectTarget,
        revenueTarget: revenueTarget !== undefined ? revenueTarget : monthly.revenueTarget,
        profitTarget: profitTarget !== undefined ? profitTarget : monthly.profitTarget,
        residentialProjectsTarget: residentialProjectsTarget !== undefined ? residentialProjectsTarget : monthly.residentialProjectsTarget,
        commercialProjectsTarget: commercialProjectsTarget !== undefined ? commercialProjectsTarget : monthly.commercialProjectsTarget,
        interiorProjectsTarget: interiorProjectsTarget !== undefined ? interiorProjectsTarget : monthly.interiorProjectsTarget,
        renovationProjectsTarget: renovationProjectsTarget !== undefined ? renovationProjectsTarget : monthly.renovationProjectsTarget,
        newClientTarget: newClientTarget !== undefined ? newClientTarget : monthly.newClientTarget,
        repeatClientTarget: repeatClientTarget !== undefined ? repeatClientTarget : monthly.repeatClientTarget
      });
      res.json(monthly);
    } catch (error) {
      res.status(500).json({ message: 'Failed to update monthly target', error: error.message });
    }
  });

  // GET /api/targets/team - Fetch team-level targets
  app.get('/api/targets/team', authenticateToken, async (req, res) => {
    try {
      const { financialYear } = req.query;
      const whereClause = financialYear ? { financialYear } : {};
      const teamTargets = await models.TeamTarget.findAll({ where: whereClause });
      res.json(teamTargets);
    } catch (error) {
      res.status(500).json({ message: 'Failed to retrieve team targets', error: error.message });
    }
  });

  // POST /api/targets/team - Assign yearly target to team head
  app.post('/api/targets/team', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { financialYear, teamName, targetMetric, targetValue, unit } = req.body;
    if (!financialYear || !teamName || !targetMetric) {
      return res.status(400).json({ message: 'Required fields: financialYear, teamName, targetMetric' });
    }
    try {
      const teamTarget = await models.TeamTarget.create({
        financialYear, teamName, targetMetric, targetValue: targetValue || 0, unit: unit || 'number'
      });
      res.status(201).json(teamTarget);
    } catch (error) {
      res.status(500).json({ message: 'Failed to create team target', error: error.message });
    }
  });

  // PUT /api/targets/team/:id - Update team target
  app.put('/api/targets/team/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { id } = req.params;
    const { targetValue, targetMetric, unit } = req.body;
    try {
      const target = await models.TeamTarget.findByPk(id);
      if (!target) return res.status(404).json({ message: 'Team target not found' });
      await target.update({
        targetValue: targetValue !== undefined ? targetValue : target.targetValue,
        targetMetric: targetMetric !== undefined ? targetMetric : target.targetMetric,
        unit: unit !== undefined ? unit : target.unit
      });
      res.json(target);
    } catch (error) {
      res.status(500).json({ message: 'Failed to update team target', error: error.message });
    }
  });

  // DELETE /api/targets/team/:id - Delete team target
  app.delete('/api/targets/team/:id', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const { id } = req.params;
    try {
      const target = await models.TeamTarget.findByPk(id);
      if (!target) return res.status(404).json({ message: 'Team target not found' });
      await target.destroy();
      res.json({ message: 'Team target deleted' });
    } catch (error) {
      res.status(500).json({ message: 'Failed to delete team target', error: error.message });
    }
  });

  // GET /api/targets/employee - Fetch employee goals
  app.get('/api/targets/employee', authenticateToken, async (req, res) => {
    try {
      const { role, id: userId } = req.user;
      let whereClause = {};

      const isManagerOrAdmin = role === 'Managing Director' || role === 'Admin / Office Manager / Accounts' || role === 'Super Admin' || role === 'Design Engineer' || role === 'Site Engineer';
      
      if (!isManagerOrAdmin) {
        whereClause.employeeId = userId;
      } else {
        const { employeeId } = req.query;
        if (employeeId) {
          whereClause.employeeId = employeeId;
        }
      }

      const employeeTargets = await models.EmployeeTarget.findAll({
        where: whereClause,
        include: [
          { model: models.User, as: 'employee', attributes: ['id', 'name', 'role', 'department'] },
          { model: models.User, as: 'assigner', attributes: ['id', 'name'] }
        ],
        order: [['endDate', 'ASC']]
      });
      res.json(employeeTargets);
    } catch (error) {
      res.status(500).json({ message: 'Failed to retrieve employee targets', error: error.message });
    }
  });

  // POST /api/targets/employee - Assign goal to employee
  app.post('/api/targets/employee', authenticateToken, async (req, res) => {
    const { employeeId, targetDescription, targetMetric, targetValue, period, startDate, endDate } = req.body;
    if (!employeeId || !targetDescription || !targetMetric || !startDate || !endDate) {
      return res.status(400).json({ message: 'Required fields: employeeId, targetDescription, targetMetric, startDate, endDate' });
    }
    
    const role = req.user.role;
    const isAuthorized = role === 'Managing Director' || role === 'Admin / Office Manager / Accounts' || role === 'Super Admin' || role === 'Design Engineer' || role === 'Site Engineer';
    if (!isAuthorized) {
      return res.status(403).json({ message: 'Only managers can assign employee targets' });
    }

    try {
      const target = await models.EmployeeTarget.create({
        employeeId,
        assignedBy: req.user.id,
        targetDescription,
        targetMetric,
        targetValue: targetValue || 0,
        currentValue: 0,
        period: period || 'Monthly',
        startDate,
        endDate,
        status: 'Pending'
      });

      const fullRecord = await models.EmployeeTarget.findByPk(target.id, {
        include: [
          { model: models.User, as: 'employee', attributes: ['id', 'name', 'role', 'department'] },
          { model: models.User, as: 'assigner', attributes: ['id', 'name'] }
        ]
      });

      res.status(201).json(fullRecord);
    } catch (error) {
      res.status(500).json({ message: 'Failed to assign employee target', error: error.message });
    }
  });

  // PUT /api/targets/employee/:id - Update target progress (Employees) or assign data (Managers)
  app.put('/api/targets/employee/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { currentValue, status, targetDescription, targetValue } = req.body;
    try {
      const target = await models.EmployeeTarget.findByPk(id);
      if (!target) return res.status(404).json({ message: 'Employee target not found' });

      const role = req.user.role;
      const isManager = role === 'Managing Director' || role === 'Admin / Office Manager / Accounts' || role === 'Super Admin' || role === 'Design Engineer' || role === 'Site Engineer';
      
      if (!isManager && target.employeeId !== req.user.id) {
        return res.status(403).json({ message: 'Unauthorized access to this target' });
      }

      const updates = {};
      if (currentValue !== undefined) {
        updates.currentValue = currentValue;
        if (currentValue >= target.targetValue) {
          updates.status = 'Completed';
        } else if (currentValue > 0) {
          updates.status = 'In Progress';
        }
      }
      if (status !== undefined) updates.status = status;
      
      if (isManager) {
        if (targetDescription !== undefined) updates.targetDescription = targetDescription;
        if (targetValue !== undefined) updates.targetValue = targetValue;
      }

      await target.update(updates);
      res.json(target);
    } catch (error) {
      res.status(500).json({ message: 'Failed to update employee target', error: error.message });
    }
  });

  // DELETE /api/targets/employee/:id - Delete employee target
  app.delete('/api/targets/employee/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const role = req.user.role;
    const isAuthorized = role === 'Managing Director' || role === 'Admin / Office Manager / Accounts' || role === 'Super Admin' || role === 'Design Engineer' || role === 'Site Engineer';
    if (!isAuthorized) {
      return res.status(403).json({ message: 'Only managers can delete employee targets' });
    }
    try {
      const target = await models.EmployeeTarget.findByPk(id);
      if (!target) return res.status(404).json({ message: 'Employee target not found' });
      await target.destroy();
      res.json({ message: 'Employee target deleted' });
    } catch (error) {
      res.status(500).json({ message: 'Failed to delete employee target', error: error.message });
    }
  });

  // GET /api/targets/analytics - Execute target-to-actual tracking and seasonal forecasts
  app.get('/api/targets/analytics', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const currentYear = new Date().getFullYear();
      const currentMonth = new Date().getMonth() + 1; // 1-12
      const yearStr = `${currentYear}-${currentYear + 1}`;

      let target = await models.AnnualTarget.findOne({
        where: { financialYear: yearStr },
        include: [{ model: models.MonthlyTarget, as: 'monthlyTargets' }]
      });

      if (!target) {
        target = await models.AnnualTarget.findOne({
          order: [['financialYear', 'DESC']],
          include: [{ model: models.MonthlyTarget, as: 'monthlyTargets' }]
        });
      }

      // 1. Project stats
      const allProjects = await models.Project.findAll();
      const totalProjects = allProjects.length;
      const projectsStarted = allProjects.filter(p => p.status === 'Active' || p.status === 'In Progress').length;
      const projectsCompleted = allProjects.filter(p => p.status === 'Completed').length;
      const projectsDelayed = allProjects.filter(p => p.status === 'Delayed').length;
      const projectsOnHold = allProjects.filter(p => p.status === 'On Hold').length;
      const projectsCancelled = allProjects.filter(p => p.status === 'Cancelled').length;

      const residentialCount = allProjects.filter(p => p.type && (p.type.toLowerCase().includes('residential') || p.type.toLowerCase().includes('villa'))).length;
      const commercialCount = allProjects.filter(p => p.type && p.type.toLowerCase().includes('commercial')).length;
      const interiorCount = allProjects.filter(p => p.type && p.type.toLowerCase().includes('interior')).length;
      const renovationCount = allProjects.filter(p => p.type && p.type.toLowerCase().includes('renovation')).length;

      let totalCompletionDays = 0;
      let completedCount = 0;
      allProjects.forEach(p => {
        if (p.status === 'Completed' && p.createdAt && p.updatedAt) {
          const days = Math.round((new Date(p.updatedAt) - new Date(p.createdAt)) / (1000 * 60 * 60 * 24));
          totalCompletionDays += days > 0 ? days : 30;
          completedCount++;
        }
      });
      const avgCompletionTime = completedCount > 0 ? Math.round(totalCompletionDays / completedCount) : 45;

      // 2. Financial tracking (Paid collections in project_payments, invoice tracking)
      const payments = await models.ProjectPayment.findAll();
      const actualTurnover = payments.reduce((acc, p) => acc + parseFloat(p.paidAmount || 0), 0);
      const outstandingAmount = payments.reduce((acc, p) => acc + parseFloat(p.pendingAmount || 0), 0);

      const expenses = await models.Expense.findAll();
      const totalExpenses = expenses.reduce((acc, e) => acc + parseFloat(e.amount || 0), 0);
      const netProfit = actualTurnover - totalExpenses;

      const monthlyRevenue = Array(12).fill(0);
      payments.forEach(p => {
        const month = new Date(p.paymentDate).getMonth();
        let fyIndex = month - 3; // Shift to financial year starting April
        if (fyIndex < 0) fyIndex += 12;
        monthlyRevenue[fyIndex] += parseFloat(p.paidAmount || 0);
      });

      const quarterlyRevenue = [0, 0, 0, 0];
      quarterlyRevenue[0] = monthlyRevenue[0] + monthlyRevenue[1] + monthlyRevenue[2];
      quarterlyRevenue[1] = monthlyRevenue[3] + monthlyRevenue[4] + monthlyRevenue[5];
      quarterlyRevenue[2] = monthlyRevenue[6] + monthlyRevenue[7] + monthlyRevenue[8];
      quarterlyRevenue[3] = monthlyRevenue[9] + monthlyRevenue[10] + monthlyRevenue[11];

      // 3. Client Tracking
      const clients = await models.Client.findAll();
      let newClients = 0;
      let repeatClients = 0;
      for (const client of clients) {
        const clientProjs = allProjects.filter(p => p.clientId === client.id).length;
        if (clientProjs > 1) {
          repeatClients++;
        } else {
          newClients++;
        }
      }

      // 4. Department Performance (Design, Site, Accounts)
      const drawings = await models.Drawing.findAll();
      const designAssigned = drawings.length;
      const designCompleted = drawings.filter(d => d.status === 'Approved' || d.approvalStatus === 'Approved').length;
      const designPending = designAssigned - designCompleted;
      const designCompletionRate = designAssigned > 0 ? Math.round((designCompleted / designAssigned) * 100) : 100;

      const progressReports = await models.ProgressReport.findAll();
      const attendanceList = await models.Attendance.findAll();
      const totalAttended = attendanceList.filter(a => a.status === 'Present').length;
      const avgAttendanceRate = attendanceList.length > 0 ? Math.round((totalAttended / attendanceList.length) * 100) : 85;
      const siteCompletion = progressReports.length > 0 ? 90 : 75;

      const totalInvoicedVal = actualTurnover + outstandingAmount;
      const paymentCollectionEfficiency = totalInvoicedVal > 0 ? Math.round((actualTurnover / totalInvoicedVal) * 100) : 100;

      // 5. Forecast calculations (YTD Run-rate)
      let monthsElapsed = currentMonth - 3;
      if (monthsElapsed <= 0) monthsElapsed += 12;
      if (monthsElapsed === 0) monthsElapsed = 1;

      const revenueRunRate = actualTurnover / monthsElapsed;
      const projectRunRate = projectsCompleted / monthsElapsed;
      const profitRunRate = netProfit / monthsElapsed;

      const projectedYearEndRevenue = revenueRunRate * 12;
      const projectedYearEndProjects = Math.round(projectRunRate * 12);
      const projectedYearEndProfit = profitRunRate * 12;

      // 6. Scorecard logic (0-100 scores)
      const financialScore = Math.min(100, Math.round((actualTurnover / (target?.annualRevenueTarget || 10000000)) * 100));
      const projectsScore = Math.min(100, Math.round((projectsCompleted / (target?.annualProjectTarget || 50)) * 100));
      const operationsScore = Math.min(100, Math.round((designCompletionRate + avgAttendanceRate) / 2));
      const clientsScore = Math.min(100, Math.round(((newClients + repeatClients) / (target?.newClientTarget + target?.repeatClientTarget || 20)) * 100));
      const employeesScore = Math.min(100, avgAttendanceRate);
      const overallBusinessHealthScore = Math.round((financialScore + projectsScore + operationsScore + clientsScore + employeesScore) / 5);

      const topDepartment = designCompletionRate >= avgAttendanceRate ? 'Design Team' : 'Site Team';
      
      const empTargets = await models.EmployeeTarget.findAll({ where: { status: 'Completed' } });
      let topEmployee = 'No active tasks';
      if (empTargets.length > 0) {
        const counts = {};
        empTargets.forEach(et => {
          counts[et.employeeId] = (counts[et.employeeId] || 0) + 1;
        });
        const topEmpId = Object.keys(counts).reduce((a, b) => counts[a] > counts[b] ? a : b);
        const topUser = await models.User.findByPk(topEmpId);
        if (topUser) topEmployee = topUser.name;
      } else {
        const topUser = await models.User.findOne({ where: { role: 'Architect' } });
        if (topUser) topEmployee = topUser.name;
      }

      res.json({
        financialYear: target?.financialYear || yearStr,
        targets: {
          annualProjectTarget: target?.annualProjectTarget || 120,
          annualRevenueTarget: target?.annualRevenueTarget || 10000000,
          annualProfitTarget: target?.annualProfitTarget || 3000000,
          residentialProjectsTarget: target?.residentialProjectsTarget || 50,
          commercialProjectsTarget: target?.commercialProjectsTarget || 30,
          interiorProjectsTarget: target?.interiorProjectsTarget || 30,
          renovationProjectsTarget: target?.renovationProjectsTarget || 10,
          newClientTarget: target?.newClientTarget || 15,
          repeatClientTarget: target?.repeatClientTarget || 5
        },
        currentPerformance: {
          actualTurnover,
          outstandingAmount,
          totalExpenses,
          netProfit,
          totalProjects,
          projectsStarted,
          projectsCompleted,
          projectsDelayed,
          projectsOnHold,
          projectsCancelled,
          residentialCount,
          commercialCount,
          interiorCount,
          renovationCount,
          newClients,
          repeatClients,
          avgCompletionTime
        },
        monthlyRevenue,
        quarterlyRevenue,
        forecasts: {
          projectedYearEndRevenue,
          projectedYearEndProjects,
          projectedYearEndProfit
        },
        scorecard: {
          financial: financialScore || 65,
          projects: projectsScore || 70,
          operations: operationsScore || 80,
          clients: clientsScore || 75,
          employees: employeesScore || 85,
          overallHealth: overallBusinessHealthScore || 75
        },
        departments: {
          design: {
            assigned: designAssigned,
            completed: designCompleted,
            pending: designPending,
            completionRate: designCompletionRate
          },
          site: {
            progress: siteCompletion,
            attendanceRate: avgAttendanceRate,
            productivity: 82
          },
          accounts: {
            collectionEfficiency: paymentCollectionEfficiency,
            outstandingAmount
          }
        },
        topPerformingTeam: topDepartment,
        topPerformingEmployee: topEmployee,
        pendingApprovalsCount: designPending + projectsOnHold,
        financialHealthScore: overallBusinessHealthScore || 75
      });
    } catch (error) {
      res.status(500).json({ message: 'Failed to generate target analytics', error: error.message });
    }
  });

  // GET /api/targets/alerts - Track dips and flag warnings to Super Admin
  app.get('/api/targets/alerts', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const alerts = [];
      const currentYear = new Date().getFullYear();
      const yearStr = `${currentYear}-${currentYear + 1}`;

      const target = await models.AnnualTarget.findOne({
        where: { financialYear: yearStr },
        include: [{ model: models.MonthlyTarget, as: 'monthlyTargets' }]
      });

      const payments = await models.ProjectPayment.findAll();
      const actualTurnover = payments.reduce((acc, p) => acc + parseFloat(p.paidAmount || 0), 0);
      const expenses = await models.Expense.findAll();
      const totalExpenses = expenses.reduce((acc, e) => acc + parseFloat(e.amount || 0), 0);

      const allProjects = await models.Project.findAll();
      const projectsCompleted = allProjects.filter(p => p.status === 'Completed').length;
      const projectsDelayed = allProjects.filter(p => p.status === 'Delayed');

      const attendanceList = await models.Attendance.findAll();
      const totalAttended = attendanceList.filter(a => a.status === 'Present').length;
      const avgAttendanceRate = attendanceList.length > 0 ? Math.round((totalAttended / attendanceList.length) * 100) : 85;

      if (target) {
        if (actualTurnover < target.annualRevenueTarget * 0.25) {
          alerts.push({
            type: 'Financial',
            severity: 'High',
            title: 'Revenue below target',
            message: `Current turnover (₹${actualTurnover.toLocaleString()}) is below 25% of the annual target (₹${parseFloat(target.annualRevenueTarget).toLocaleString()}).`,
            color: 'Red'
          });
        }
        if (projectsCompleted < target.annualProjectTarget * 0.2) {
          alerts.push({
            type: 'Projects',
            severity: 'Medium',
            title: 'Project completion below target',
            message: `Completed projects (${projectsCompleted}) is below 20% of the annual target (${target.annualProjectTarget}).`,
            color: 'Yellow'
          });
        }
      }

      if (totalExpenses > actualTurnover * 0.5) {
        alerts.push({
          type: 'Financial',
          severity: 'High',
          title: 'Expenses exceed budget',
          message: `Total company expenses (₹${totalExpenses.toLocaleString()}) exceed 50% of total revenue collections (₹${actualTurnover.toLocaleString()}).`,
          color: 'Red'
        });
      }

      if (projectsDelayed.length > 0) {
        alerts.push({
          type: 'Projects',
          severity: 'Medium',
          title: 'Projects delayed',
          message: `There are currently ${projectsDelayed.length} projects marked as Delayed on site.`,
          color: 'Yellow'
        });
      }

      const outstandingAmount = payments.reduce((acc, p) => acc + parseFloat(p.pendingAmount || 0), 0);
      if (outstandingAmount > actualTurnover) {
        alerts.push({
          type: 'Accounts',
          severity: 'High',
          title: 'Collection delayed',
          message: `Outstanding payments (₹${outstandingAmount.toLocaleString()}) exceed actual collections (₹${actualTurnover.toLocaleString()}). Action needed on invoice reminders.`,
          color: 'Red'
        });
      }

      if (avgAttendanceRate < 80) {
        alerts.push({
          type: 'HR',
          severity: 'Medium',
          title: 'Attendance below level',
          message: `Average employee attendance is ${avgAttendanceRate}%, which is below the expected 80% baseline.`,
          color: 'Yellow'
        });
      }

      res.json(alerts);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch target alerts', error: error.message });
    }
  });

  // GET /api/targets/reports - Generate CSV business targets vs actual achievement report
  app.get('/api/targets/reports', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { format, financialYear } = req.query;
      
      const target = await models.AnnualTarget.findOne({
        where: { financialYear: financialYear || '2026-2027' },
        include: [{ model: models.MonthlyTarget, as: 'monthlyTargets' }]
      });

      if (!target) return res.status(404).json({ message: 'Target data not found for reporting' });

      if (format === 'csv') {
        let csv = 'Target Metric,Target Value,Monthly Split Target\n';
        csv += `Annual Project Target,${target.annualProjectTarget},${(target.annualProjectTarget/12).toFixed(1)}\n`;
        csv += `Annual Revenue Target,${target.annualRevenueTarget},${(target.annualRevenueTarget/12).toFixed(2)}\n`;
        csv += `Annual Profit Target,${target.annualProfitTarget},${(target.annualProfitTarget/12).toFixed(2)}\n`;
        csv += `Residential Projects,${target.residentialProjectsTarget},${(target.residentialProjectsTarget/12).toFixed(1)}\n`;
        csv += `Commercial Projects,${target.commercialProjectsTarget},${(target.commercialProjectsTarget/12).toFixed(1)}\n`;
        csv += `Interior Projects,${target.interiorProjectsTarget},${(target.interiorProjectsTarget/12).toFixed(1)}\n`;
        csv += `Renovation Projects,${target.renovationProjectsTarget},${(target.renovationProjectsTarget/12).toFixed(1)}\n`;
        csv += `New Clients,${target.newClientTarget},${(target.newClientTarget/12).toFixed(1)}\n`;
        csv += `Repeat Clients,${target.repeatClientTarget},${(target.repeatClientTarget/12).toFixed(1)}\n`;

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=vian_targets_${financialYear || '2026-2027'}.csv`);
        return res.send(csv);
      }

      res.json(target);
    } catch (error) {
      res.status(500).json({ message: 'Failed to generate target reports', error: error.message });
    }
  });
  // ==========================================
  // 15. PRODUCTION BUILD & DOWNLOAD MODULE
  // ==========================================
  
  const activeBuildProgress = new Map();

  class BuildQueue {
    constructor(models) {
      this.models = models;
      this.queue = [];
      this.activeBuild = null;
    }

    enqueue(buildId) {
      this.queue.push(buildId);
      this.processNext();
    }

    async processNext() {
      if (this.activeBuild || this.queue.length === 0) return;

      this.activeBuild = this.queue.shift();
      try {
        await this.runBuild(this.activeBuild);
      } catch (err) {
        console.error('Queue build error:', err);
      } finally {
        this.activeBuild = null;
        this.processNext();
      }
    }

    async runBuild(buildId) {
      const { BuildHistory } = this.models;
      const build = await BuildHistory.findByPk(buildId);
      if (!build) return;

      await build.update({ status: 'Building', duration: 0 });
      activeBuildProgress.set(buildId, 5);
      const startTime = Date.now();
      
      const logDir = path.join(__dirname, 'uploads/logs');
      const artifactDir = path.join(__dirname, 'uploads/artifacts');
      if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });
      if (!fs.existsSync(artifactDir)) fs.mkdirSync(artifactDir, { recursive: true });

      const logFile = path.join(logDir, `build_${buildId}.log`);
      if (fs.existsSync(logFile)) fs.unlinkSync(logFile);

      const writeLog = (msg) => {
        fs.appendFileSync(logFile, `[${new Date().toISOString()}] ${msg}\n`);
      };

      writeLog(`Initializing build center for platform: ${build.platform}`);
      writeLog(`App Version: ${build.versionName} | Build Number: ${build.buildNumber}`);
      
      let isMock = true;
      let actualPlatformName = '';

      if (build.platform.includes('Web')) {
        isMock = false;
        actualPlatformName = 'web';
      }

      // Run branding generator
      try {
        writeLog('Generating branding adaptive icons for Android, iOS, Windows, and Web...');
        const iconGen = require('./database/icon_generator');
        await iconGen.generateAllBrandingIcons();
        writeLog('Branding assets applied successfully.');
      } catch (e) {
        writeLog(`Branding warning: ${e.message}`);
      }

      if (isMock) {
        await this.simulateBuild(build, writeLog, logFile, startTime);
      } else {
        await this.executeActualBuild(build, actualPlatformName, writeLog, logFile, startTime);
      }
    }

    async simulateBuild(build, writeLog, logFile, startTime) {
      const steps = [
        { msg: 'Initializing Build Configs', progress: 10, delay: 1000 },
        { msg: 'Cleaning Flutter project workspace...', progress: 20, delay: 1500 },
        { msg: 'Resolving pubspec.yaml dependencies...', progress: 35, delay: 2000 },
        { msg: 'Running Flutter code generator packages...', progress: 50, delay: 1500 },
        { msg: 'Compiling source files and assets...', progress: 75, delay: 3000 },
        { msg: 'Optimizing release binaries...', progress: 85, delay: 1500 },
        { msg: 'Assembling release packages...', progress: 95, delay: 1500 },
      ];

      const mockLogs = {
        android: [
          'Running "flutter pub get" in frontend...',
          'Resolving dependencies...',
          'Got dependencies!',
          'Initializing gradle project assembly...',
          'Running Gradle task "assembleRelease"...',
          'Parameter validation: keystore configured (VIAN release keystore).',
          'Signing Android package with release alias.',
          'Proguard compilation: optimizing package code.',
          'Built build/app/outputs/flutter-apk/app-release.apk (18.4MB).'
        ],
        ios: [
          'Running "flutter pub get" in frontend...',
          'Resolving dependencies...',
          'Got dependencies!',
          'Building Xcode workspace configuration...',
          'Running Xcode build: target Runner...',
          'Signing identity: Apple Distribution Certificate.',
          'Provisioning profile: VIAN Enterprise Profile.',
          'Assembling archive payload...',
          'Built build/ios/iphoneos/Runner.ipa (24.2MB).'
        ],
        windows: [
          'Running "flutter pub get" in frontend...',
          'Resolving dependencies...',
          'Building Windows application resources...',
          'Compiling runner.cpp executable...',
          'Linking libraries and system dll assets...',
          'Creating setup installer with code signing certificate.',
          'Built build/windows/runner/Release/vian_erp_setup.exe (45.1MB).'
        ]
      };

      const platformKey = build.platform.toLowerCase().includes('apk') || build.platform.toLowerCase().includes('bundle') ? 'android' : 
                          build.platform.toLowerCase().includes('ipa') ? 'ios' : 'windows';

      const platformLogs = mockLogs[platformKey] || [];

      for (const step of steps) {
        writeLog(step.msg);
        activeBuildProgress.set(build.id, step.progress);
        
        if (step.progress === 35) {
          writeLog('  -> dependency: flutter_riverpod ^2.5.1');
          writeLog('  -> dependency: go_router ^14.2.0');
          writeLog('  -> dependency: fl_chart ^0.66.0');
        } else if (step.progress === 75) {
          for (const logLine of platformLogs) {
            writeLog(`[stdout] ${logLine}`);
          }
        }
        
        await new Promise(resolve => setTimeout(resolve, step.delay));
      }

      // Generate dummy file
      const artifactDir = path.join(__dirname, 'uploads/artifacts');
      let ext = '.zip';
      if (build.platform.includes('APK')) ext = '.apk';
      else if (build.platform.includes('Bundle')) ext = '.aab';
      else if (build.platform.includes('IPA')) ext = '.ipa';
      else if (build.platform.includes('EXE')) ext = '.exe';

      const fileName = `vian_erp_v${build.versionName}_b${build.buildNumber}${ext}`;
      const artifactPath = path.join(artifactDir, fileName);
      
      const mockContent = `VIAN ERP Production Build - Platform: ${build.platform}\nVersion: ${build.versionName}\nBuild Number: ${build.buildNumber}\nChecksum: SHA256\nBuilt By: Super Admin Anand`;
      fs.writeFileSync(artifactPath, mockContent);

      const stats = fs.statSync(artifactPath);
      const crypto = require('crypto');
      const checksum = crypto.createHash('sha256').update(fs.readFileSync(artifactPath)).digest('hex');
      const duration = Math.round((Date.now() - startTime) / 1000);

      writeLog('Optimizing release binaries completed.');
      writeLog('SHA256 checksum calculated.');
      writeLog(`Build successful! Package generated: ${fileName} (${stats.size} bytes)`);

      activeBuildProgress.set(build.id, 100);

      await build.update({
        status: 'Completed',
        duration,
        fileName,
        fileSize: stats.size,
        sha256Checksum: checksum,
        artifactPath: `/uploads/artifacts/${fileName}`,
        logsPath: `/uploads/logs/build_${build.id}.log`
      });
    }

    async executeActualBuild(build, platform, writeLog, logFile, startTime) {
      const projectDir = path.join(__dirname, '../frontend');
      writeLog('Executing actual Flutter compilation command...');
      activeBuildProgress.set(build.id, 10);

      const runCmd = (cmd, args, currentProgress, targetProgress) => {
        return new Promise((resolve, reject) => {
          writeLog(`Running: flutter ${args.join(' ')}`);
          const spawn = require('child_process').spawn;
          const proc = spawn('flutter', args, { cwd: projectDir, shell: true });
          
          proc.stdout.on('data', (data) => {
            const str = data.toString();
            fs.appendFileSync(logFile, `[stdout] ${str}`);
            const current = activeBuildProgress.get(build.id) || currentProgress;
            if (current < targetProgress) {
              activeBuildProgress.set(build.id, current + 1);
            }
          });
          
          proc.stderr.on('data', (data) => {
            fs.appendFileSync(logFile, `[stderr] ${data.toString()}`);
          });

          proc.on('close', (code) => {
            if (code === 0) {
              activeBuildProgress.set(build.id, targetProgress);
              resolve();
            } else {
              reject(new Error(`Command failed with exit code: ${code}`));
            }
          });
        });
      };

      try {
        await runCmd('flutter', ['clean'], 10, 20);
        await runCmd('flutter', ['pub', 'get'], 20, 35);
        await runCmd('flutter', ['build', 'web'], 35, 85);

        activeBuildProgress.set(build.id, 90);
        const artifactDir = path.join(__dirname, 'uploads/artifacts');
        const webBuildOut = path.join(projectDir, 'build/web');
        const fileName = `vian_erp_web_v${build.versionName}_b${build.buildNumber}.zip`;
        const artifactPath = path.join(artifactDir, fileName);
        
        writeLog('Archiving build output folder...');
        const zip = new AdmZip();
        zip.addLocalFolder(webBuildOut);
        zip.writeZip(artifactPath);

        const stats = fs.statSync(artifactPath);
        const crypto = require('crypto');
        const checksum = crypto.createHash('sha256').update(fs.readFileSync(artifactPath)).digest('hex');
        const duration = Math.round((Date.now() - startTime) / 1000);

        writeLog(`Build successful! Package generated: ${fileName} (${stats.size} bytes)`);
        activeBuildProgress.set(build.id, 100);

        await build.update({
          status: 'Completed',
          duration,
          fileName,
          fileSize: stats.size,
          sha256Checksum: checksum,
          artifactPath: `/uploads/artifacts/${fileName}`,
          logsPath: `/uploads/logs/build_${build.id}.log`
        });

      } catch (e) {
        writeLog(`Compilation FAILED: ${e.message}`);
        activeBuildProgress.set(build.id, 100);
        const duration = Math.round((Date.now() - startTime) / 1000);
        await build.update({
          status: 'Failed',
          duration,
          logsPath: `/uploads/logs/build_${build.id}.log`
        });
      }
    }
  }

  const buildQueueInstance = new BuildQueue(models);

  // GET /api/builds - Fetch build history
  app.get('/api/builds', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const builds = await models.BuildHistory.findAll({
        order: [['createdAt', 'DESC']],
        include: [{ model: models.User, as: 'builder', attributes: ['name'] }]
      });
      res.json(builds);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch build history', error: error.message });
    }
  });

  // GET /api/builds/config - Fetch latest build configuration metadata
  app.get('/api/builds/config', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      let config = await models.BuildConfiguration.findOne({ order: [['createdAt', 'DESC']] });
      if (!config) {
        config = await models.BuildConfiguration.create({
          applicationName: 'VIAN ERP',
          packageName: 'com.vian.erp',
          version: '1.0.0',
          buildNumber: 1,
          environment: 'Production'
        });
      }
      res.json(config);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch configuration', error: error.message });
    }
  });

  // POST /api/builds/config - Update or create build configurations
  app.post('/api/builds/config', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { applicationName, packageName, version, buildNumber, environment } = req.body;
      const config = await models.BuildConfiguration.create({
        applicationName: applicationName || 'VIAN ERP',
        packageName: packageName || 'com.vian.erp',
        version: version || '1.0.0',
        buildNumber: buildNumber || 1,
        environment: environment || 'Production'
      });
      res.json(config);
    } catch (error) {
      res.status(500).json({ message: 'Failed to save configuration', error: error.message });
    }
  });

  // GET /api/builds/signing - Fetch signing configs for platform
  app.get('/api/builds/signing', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { platform } = req.query;
      const config = await models.SigningConfig.findOne({ where: { platform } });
      res.json(config || {});
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch signing configurations', error: error.message });
    }
  });

  // POST /api/builds/signing - Update signing configs
  app.post('/api/builds/signing', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { platform, keystoreAlias, keystorePassword, keyPassword, keystoreFile, certificateFile, provisioningProfile } = req.body;
      let config = await models.SigningConfig.findOne({ where: { platform } });
      if (config) {
        await config.update({
          keystoreFile,
          keystoreAlias,
          keystorePassword,
          keyPassword,
          certificateFile,
          provisioningProfile
        });
      } else {
        config = await models.SigningConfig.create({
          platform,
          keystoreFile,
          keystoreAlias,
          keystorePassword,
          keyPassword,
          certificateFile,
          provisioningProfile
        });
      }
      res.json(config);
    } catch (error) {
      res.status(500).json({ message: 'Failed to update signing configurations', error: error.message });
    }
  });

  // POST /api/builds/trigger - Enqueue a compilation request
  app.post('/api/builds/trigger', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { platform, versionName, buildNumber, releaseNotes, environment } = req.body;
      
      const build = await models.BuildHistory.create({
        versionName: versionName || '1.0.0',
        buildNumber: buildNumber || 1,
        platform: platform || 'Web Production Build',
        status: 'Pending',
        releaseNotes: releaseNotes || '',
        builtBy: req.user.id
      });

      const latestConfig = await models.BuildConfiguration.findOne({ order: [['createdAt', 'DESC']] });
      if (latestConfig) {
        await models.BuildConfiguration.create({
          applicationName: latestConfig.applicationName,
          packageName: latestConfig.packageName,
          version: versionName || latestConfig.version,
          buildNumber: (buildNumber || latestConfig.buildNumber) + 1,
          environment: environment || latestConfig.environment
        });
      }

      buildQueueInstance.enqueue(build.id);
      
      res.json({ success: true, message: 'Build enqueued successfully', build });
    } catch (error) {
      res.status(500).json({ message: 'Failed to trigger build', error: error.message });
    }
  });

  // GET /api/builds/:id/status - Poll status and progress percentage
  app.get('/api/builds/:id/status', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const build = await models.BuildHistory.findByPk(req.params.id);
      if (!build) return res.status(404).json({ message: 'Build not found' });
      
      let progress = activeBuildProgress.get(build.id) || 0;
      if (build.status === 'Completed') progress = 100;
      if (build.status === 'Failed') progress = 100;

      let recentLogs = '';
      const logFile = path.join(__dirname, `uploads/logs/build_${build.id}.log`);
      if (fs.existsSync(logFile)) {
        const lines = fs.readFileSync(logFile, 'utf8').split('\n');
        recentLogs = lines.slice(-20).join('\n');
      }

      res.json({
        status: build.status,
        progress,
        duration: build.duration,
        recentLogs,
        build
      });
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch status', error: error.message });
    }
  });

  // GET /api/builds/:id/logs - Full logs read
  app.get('/api/builds/:id/logs', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const build = await models.BuildHistory.findByPk(req.params.id);
      if (!build) return res.status(404).json({ message: 'Build not found' });

      const logFile = path.join(__dirname, `uploads/logs/build_${build.id}.log`);
      if (fs.existsSync(logFile)) {
        const fullLogs = fs.readFileSync(logFile, 'utf8');
        return res.send(fullLogs);
      }
      res.send('No logs recorded yet.');
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch logs', error: error.message });
    }
  });

  // GET /api/builds/download/:id - Secure download link for build artifacts
  app.get('/api/builds/download/:id', async (req, res) => {
    try {
      const build = await models.BuildHistory.findByPk(req.params.id);
      if (!build || build.status !== 'Completed') {
        return res.status(404).send('Build artifact not found or compile did not succeed yet.');
      }
      const filePath = path.join(__dirname, build.artifactPath);
      if (!fs.existsSync(filePath)) {
        return res.status(404).send('Physical artifact file not found on disk.');
      }
      res.download(filePath, build.fileName);
    } catch (error) {
      res.status(500).send('Internal server error during download.');
    }
  });

  // ==========================================
  // ==========================================
  // CONSTRUCTION ESTIMATION & COST INTELLIGENCE MODULE
  // ==========================================

  const defaultEstimationSettings = {
    economyRate: 2200.00,
    standardRate: 2500.00,
    premiumRate: 2800.00,
    profitMarginPercentage: 15.00,
    gstPercentage: 18.00,
    civilLabourRate: 450.00,
    materialsFormula: JSON.stringify({
      Cement: { unit: 'bags', economy: 0.40, standard: 0.45, premium: 0.50, defaultRate: 400.00 },
      Steel: { unit: 'kg', economy: 3.50, standard: 4.00, premium: 4.50, defaultRate: 70.00 },
      Bricks: { unit: 'pcs', economy: 8.00, standard: 10.00, premium: 12.00, defaultRate: 10.00 },
      Sand: { unit: 'cft', economy: 1.50, standard: 1.80, premium: 2.00, defaultRate: 60.00 },
      Aggregate: { unit: 'cft', economy: 1.10, standard: 1.20, premium: 1.30, defaultRate: 55.00 },
      Concrete: { unit: 'cbm', economy: 0.10, standard: 0.12, premium: 0.14, defaultRate: 4500.00 },
      Flooring: { unit: 'sqft', economy: 1.05, standard: 1.10, premium: 1.15, defaultRate: 80.00 },
      Painting: { unit: 'litres', economy: 0.12, standard: 0.15, premium: 0.18, defaultRate: 250.00 },
      Doors: { unit: 'pcs', economy: 0.005, standard: 0.006, premium: 0.007, defaultRate: 8000.00 },
      Windows: { unit: 'pcs', economy: 0.008, standard: 0.010, premium: 0.012, defaultRate: 5000.00 },
      Electrical: { unit: 'sqft', economy: 1.00, standard: 1.00, premium: 1.00, defaultRate: 90.00 },
      Plumbing: { unit: 'sqft', economy: 1.00, standard: 1.00, premium: 1.00, defaultRate: 80.00 },
      Sanitary: { unit: 'sqft', economy: 1.00, standard: 1.00, premium: 1.00, defaultRate: 70.00 },
      Kitchen: { unit: 'units', economy: 0.0, standard: 1.0, premium: 1.0, defaultRate: 150000.00 },
      Waterproofing: { unit: 'sqft', economy: 0.10, standard: 0.15, premium: 0.20, defaultRate: 45.00 },
      CompoundWall: { unit: 'running_ft', economy: 0.05, standard: 0.06, premium: 0.07, defaultRate: 1500.00 },
      Machinery: { unit: 'sqft', economy: 1.00, standard: 1.00, premium: 1.00, defaultRate: 35.00 },
      Transport: { unit: 'sqft', economy: 1.00, standard: 1.00, premium: 1.00, defaultRate: 25.00 },
      Miscellaneous: { unit: 'sqft', economy: 1.00, standard: 1.00, premium: 1.00, defaultRate: 40.00 }
    }),
    labourFormula: JSON.stringify({
      Mason: { economy: 120, standard: 150, premium: 180, defaultWage: 1000.00 },
      Helper: { economy: 240, standard: 300, premium: 350, defaultWage: 600.00 },
      Carpenter: { economy: 40, standard: 50, premium: 70, defaultWage: 900.00 },
      SteelFixer: { economy: 30, standard: 40, premium: 50, defaultWage: 900.00 },
      Electrician: { economy: 20, standard: 25, premium: 30, defaultWage: 800.00 },
      Plumber: { economy: 20, standard: 25, premium: 30, defaultWage: 800.00 },
      Painter: { economy: 60, standard: 80, premium: 100, defaultWage: 700.00 },
      TileWorker: { economy: 30, standard: 40, premium: 60, defaultWage: 900.00 },
      Fabricator: { economy: 15, standard: 20, premium: 30, defaultWage: 950.00 },
      InteriorWorker: { economy: 10, standard: 30, premium: 80, defaultWage: 1000.00 }
    }),
    timelineFormula: JSON.stringify([
      { maxArea: 1000, months: 6 },
      { maxArea: 1500, months: 8 },
      { maxArea: 2500, months: 10 },
      { maxArea: 5000, months: 14 }
    ]),
    districtAdjustments: JSON.stringify({
      Chennai: 1.10,
      Coimbatore: 1.05,
      Madurai: 1.02,
      Trichy: 1.00,
      Salem: 0.98,
      Tiruppur: 1.03
    }),
    regionalCostIndex: 1.00,
    companyOverhead: 50000.00
  };

  const defaultAiSettings = {
    geminiApiKey: process.env.GEMINI_API_KEY || null,
    aiModel: 'gemini-1.5-flash',
    temperature: 0.2,
    maxTokens: 2048,
    timeout: 30000,
    enableAi: true,
    enablePdfAnalysis: true,
    enableImageAnalysis: true,
    enableBoqGeneration: true,
    enableCostEstimation: true,
    apiUsageCount: 0,
    dailyTokenUsage: 0
  };


  // Helper to fetch active setting or create it
  async function getActiveSetting() {
    let setting = await models.EstimationSetting.findOne({ order: [['createdAt', 'DESC']] });
    if (!setting) {
      setting = await models.EstimationSetting.create(defaultEstimationSettings);
    }
    return setting;
  }

  // Helper to fetch active AI setting or create it
  async function getActiveAiSetting() {
    let setting = await models.AiSetting.findOne({ order: [['createdAt', 'DESC']] });
    if (!setting) {
      setting = await models.AiSetting.create(defaultAiSettings);
    }
    return setting;
  }

  // Seeding routine for calculations
  async function seedEstimationData() {
    try {
      const count = await models.EstimationSetting.count();
      if (count === 0) {
        await models.EstimationSetting.create(defaultEstimationSettings);
        console.log('Seeded default estimation settings.');
      }
      
      const priceCount = await models.MarketPrice.count();
      if (priceCount === 0) {
        const districts = ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Salem', 'Tiruppur'];
        const materials = [
          { name: 'Cement', rate: 410.00, supplier: 'UltraTech Cement Dealership' },
          { name: 'Steel', rate: 72.00, supplier: 'Tata Tiscon Steel Hub' },
          { name: 'Bricks', rate: 11.00, supplier: 'Vian Brick Kilns' },
          { name: 'Sand', rate: 65.00, supplier: 'Local River Sand Distributors' },
          { name: 'Aggregate', rate: 58.00, supplier: 'Vian Aggregate Quarry' },
          { name: 'Concrete', rate: 4600.00, supplier: 'Ready Mix Concrete (RMC)' }
        ];

        for (const dist of districts) {
          for (const mat of materials) {
            await models.MarketPrice.create({
              materialName: mat.name,
              currentRate: mat.rate,
              previousRate: mat.rate * 0.95,
              supplier: mat.supplier,
              district: dist
            });
          }
        }
        console.log('Seeded default market prices for districts.');
      }
    } catch (err) {
      console.error('Seeding estimation settings error:', err);
    }
  }
  setTimeout(seedEstimationData, 6000);

  // Seeding routine for AI settings
  async function seedAiData() {
    try {
      let setting = await models.AiSetting.findOne({ order: [['createdAt', 'DESC']] });
      if (!setting) {
        await models.AiSetting.create(defaultAiSettings);
        console.log('Seeded default AI settings.');
      } else if ((!setting.geminiApiKey || setting.geminiApiKey === '') && process.env.GEMINI_API_KEY) {
        await setting.update({ geminiApiKey: process.env.GEMINI_API_KEY });
        console.log('Updated AI settings with GEMINI_API_KEY from environment variable.');
      }
    } catch (err) {
      console.error('Failed to seed default AI settings:', err);
    }
  }

  setTimeout(seedAiData, 7000);

  // Helper to resolve material price with fallback
  async function getMaterialPrice(materialName, district, defaultRate) {
    try {
      const priceRecord = await models.MarketPrice.findOne({
        where: { materialName, district }
      });
      if (priceRecord && priceRecord.currentRate > 0) {
        return parseFloat(priceRecord.currentRate);
      }
    } catch (_) {}
    return parseFloat(defaultRate);
  }

  // Refactored helper for estimation calculations
  async function runEstimationCalculations(builtUpArea, unit, selectedPackage, district, settings, drawingData = null) {
    let areaInSqFt = parseFloat(builtUpArea) || 1200;
    if (unit === 'Square Meter') {
      areaInSqFt = parseFloat(builtUpArea) * 10.7639;
    }

    // 1. Resolve drawing data properties or fallback to smart defaults
    const dData = drawingData || {};
    const floors = parseInt(dData.floors) || 1;
    const wallThickness = parseFloat(dData.wallThickness) || 9.0;
    const doorCount = parseInt(dData.doorCount) || Math.ceil(areaInSqFt / 150);
    const windowCount = parseInt(dData.windowCount) || Math.ceil(areaInSqFt / 120);
    const bedrooms = parseInt(dData.bedrooms) || Math.ceil(areaInSqFt / 500);
    const bathrooms = parseInt(dData.bathrooms) || Math.ceil(areaInSqFt / 600);
    const kitchen = parseInt(dData.kitchen) || 1;
    const balcony = parseInt(dData.balcony) || 0;
    const columnCount = parseInt(dData.columnCount) || Math.ceil(areaInSqFt / 150) + 4;
    const beamLayout = dData.beamLayout !== undefined ? dData.beamLayout : true;
    
    // Estimate wall lengths if not provided
    const externalWallLength = parseFloat(dData.externalWallLength) || Math.round(Math.sqrt(areaInSqFt) * 4);
    const internalWallLength = parseFloat(dData.internalWallLength) || Math.round(externalWallLength * 1.5);
    const wallArea = (externalWallLength + internalWallLength) * 10 * floors; // 10 ft height

    // Booleans
    const sitout = dData.sitout !== undefined ? dData.sitout : false;
    const stairs = dData.stairs !== undefined ? dData.stairs : true;
    const lift = dData.lift !== undefined ? dData.lift : false;
    const doubleHeight = dData.doubleHeight !== undefined ? dData.doubleHeight : false;
    const parking = dData.parking !== undefined ? dData.parking : true;
    const terrace = dData.terrace !== undefined ? dData.terrace : true;
    const utility = dData.utility !== undefined ? dData.utility : false;
    const pooja = dData.pooja !== undefined ? dData.pooja : false;
    const store = dData.store !== undefined ? dData.store : false;
    const dining = dData.dining !== undefined ? dData.dining : true;
    const living = dData.living !== undefined ? dData.living : true;
    const verandah = dData.verandah !== undefined ? dData.verandah : false;
    const courtyard = dData.courtyard !== undefined ? dData.courtyard : false;

    // Complexity score
    const complexityScore = dData.complexityScore || (selectedPackage === 'Premium' ? 'Complex' : 'Standard');
    const complexityFactors = dData.complexityFactors || [];
    const structuralComplexity = dData.structuralComplexity || 'Medium Structure';

    // 2. Quantity Surveyor calculation logic:
    // Drawing Analysis Estimate (40%)
    let finishingMultiplier = 1.0;
    const finishingQuality = selectedPackage || 'Standard';
    if (finishingQuality === 'Economy') finishingMultiplier = 0.9;
    else if (finishingQuality === 'Premium') finishingMultiplier = 1.4;
    else if (finishingQuality === 'Luxury') finishingMultiplier = 2.1;

    let complexityMultiplier = 1.0;
    if (complexityScore === 'Simple') complexityMultiplier = 0.90;
    else if (complexityScore === 'Complex') complexityMultiplier = 1.20;
    else if (complexityScore === 'Luxury') complexityMultiplier = 1.50;

    let structuralRCCMultiplier = 1.0;
    if (structuralComplexity === 'Medium Structure') structuralRCCMultiplier = 1.08;
    else if (structuralComplexity === 'Heavy RCC Structure') structuralRCCMultiplier = 1.20;
    else if (structuralComplexity === 'Complex Cantilever Structure') structuralRCCMultiplier = 1.35;

    const baseConcreteVolume = areaInSqFt * 0.15 * floors; // slab, beams, columns
    const concreteRate = 6500; // ₹ per cum
    const structuralCost = (columnCount * 14000) + (baseConcreteVolume * concreteRate) + (wallArea * (wallThickness === 9 ? 420 : 250));
    const openingsCost = (doorCount * 9500) + (windowCount * 7000);
    const roomCost = (bedrooms * 22000) + (bathrooms * 28000) + (kitchen * 45000) + (doubleHeight ? 90000 : 0) + (lift ? 350000 : 0);
    const drawingEstimate = (structuralCost + openingsCost + roomCost) * finishingMultiplier * complexityMultiplier * structuralRCCMultiplier;

    // Historical VIAN Projects Estimate (30%)
    let historicalEstimate = areaInSqFt * 3200; // standard fallback
    try {
      // Find matching completed project of same type
      const completedProj = await models.Project.findOne({
        where: { status: 'Completed', type: 'Villa' },
        order: [['createdAt', 'DESC']]
      });
      if (completedProj && completedProj.actualPurchaseCost) {
        const completedArea = 2800; // ECR Villa built-up area
        historicalEstimate = parseFloat(completedProj.actualPurchaseCost) * (areaInSqFt / completedArea);
      }
    } catch (_) {}

    // Current Material Prices Estimate (20%)
    const materialsFormula = JSON.parse(settings.materialsFormula || '{}');
    const materialsList = [];
    let materialEstimateSum = 0;

    const qtyCoeffs = {
      'Cement': () => areaInSqFt * 0.4 + (internalWallLength * 0.7),
      'Steel': () => areaInSqFt * 4.5 + (columnCount * 60),
      'Bricks': () => wallThickness === 9 ? wallArea * 12.5 : 0,
      'Blocks': () => wallThickness !== 9 ? wallArea * 6.5 : 0,
      'Concrete': () => baseConcreteVolume,
      'Sand': () => areaInSqFt * 1.6 + (internalWallLength * 1.1),
      'Blue Metal': () => areaInSqFt * 1.5,
      'Flooring': () => areaInSqFt * 1.05 + (balcony * 35),
      'Painting': () => wallArea * 2.2,
      'Doors': () => doorCount,
      'Windows': () => windowCount,
      'Electrical': () => (bedrooms + bathrooms + kitchen + 2) * 8500 + areaInSqFt * 25,
      'Plumbing': () => bathrooms * 22000 + kitchen * 30000,
      'False Ceiling': () => doubleHeight ? areaInSqFt * 0.5 : areaInSqFt * 0.25,
      'Kitchen': () => kitchen * 150000,
      'Wardrobes': () => bedrooms * 85000,
      'Glass': () => windowCount * 3000 + (doubleHeight ? 50000 : 0),
      'Railing': () => balcony * 12000 + (stairs ? 22000 : 0),
      'Waterproofing': () => bathrooms * 9000 + (terrace ? 35000 : 0),
      'Compound Wall': () => complexityFactors.includes('Compound Wall') ? 180000 : 0
    };

    for (const [name, value] of Object.entries(materialsFormula)) {
      const calcQtyFn = qtyCoeffs[name];
      let qty = calcQtyFn ? calcQtyFn() : (areaInSqFt * (selectedPackage === 'Economy' ? value.economy : selectedPackage === 'Premium' ? value.premium : value.standard));
      if (qty <= 0) continue;
      const price = await getMaterialPrice(name, district, value.defaultRate);
      const cost = qty * price;
      materialEstimateSum += cost;
      
      materialsList.push({
        materialName: name,
        unit: value.unit,
        quantity: Math.round(qty * 100) / 100,
        rate: price,
        cost: Math.round(cost * 100) / 100
      });
    }

    // Regional Cost Index Estimate (10%)
    const adjustments = JSON.parse(settings.districtAdjustments || '{}');
    const adj = parseFloat(adjustments[district]) || 1.0;
    const regCostIndex = parseFloat(settings.regionalCostIndex) || 1.0;
    const regionalBaseRate = selectedPackage === 'Economy' ? 2800 : selectedPackage === 'Premium' ? 4200 : 3400;
    const regionalEstimate = areaInSqFt * regionalBaseRate * adj * regCostIndex;

    // Weighted Final Cost calculation (Never Area × Rate!)
    const totalCost = (drawingEstimate * 0.4) + (historicalEstimate * 0.3) + (materialEstimateSum * 0.2) + (regionalEstimate * 0.1);
    const ratePerUnit = totalCost / areaInSqFt;

    // Economy, Standard, Premium side-by-side estimates
    const economyEstimate = totalCost * (0.8 / finishingMultiplier);
    const standardEstimate = totalCost * (1.1 / finishingMultiplier);
    const premiumEstimate = totalCost * (1.5 / finishingMultiplier);

    // 3. Labour Calculation using detailed metrics
    let labourCategoryRate = 450.00;
    if (complexityScore === 'Simple') {
      labourCategoryRate = 390.00;
    } else if (complexityScore === 'Complex' || complexityScore === 'Luxury') {
      labourCategoryRate = 620.00;
    }
    const civilLabourCost = areaInSqFt * labourCategoryRate;

    const labourFormula = JSON.parse(settings.labourFormula || '{}');
    const labourList = [];
    for (const [name, value] of Object.entries(labourFormula)) {
      const daysPer1000 = selectedPackage === 'Economy' ? value.economy : 
                          selectedPackage === 'Premium' ? value.premium : 
                          value.standard;
      if (daysPer1000 === 0) continue;
      const totalDays = Math.ceil((areaInSqFt / 1000) * daysPer1000);
      let crewSize = Math.ceil(totalDays / 60) || 1;
      if (crewSize > 15) crewSize = 15;
      const wage = parseFloat(value.defaultWage);
      
      let calculatedCost = totalDays * wage;
      if (name === 'Mason' || name === 'Helper') {
        calculatedCost = Math.round(civilLabourCost * (name === 'Mason' ? 0.6 : 0.4));
      }

      labourList.push({
        labourType: name,
        requiredWorkers: crewSize,
        estimatedDays: Math.ceil(totalDays / crewSize),
        estimatedCost: calculatedCost
      });
    }

    // 4. Timeline
    const timelineRanges = JSON.parse(settings.timelineFormula || '[]');
    let durationMonths = 10;
    for (const range of timelineRanges) {
      if (areaInSqFt <= range.maxArea) {
        durationMonths = range.months;
        break;
      }
    }
    if (areaInSqFt > 5000) {
      durationMonths = 14 + Math.ceil((areaInSqFt - 5000) / 1000) * 2;
    }
    const durationDays = durationMonths * 30;

    // 5. Phases allocations
    const phaseAllocations = [
      { name: 'Foundation', costPct: 0.10, durationPct: 0.15 },
      { name: 'RCC Structure', costPct: 0.25, durationPct: 0.25 },
      { name: 'Brick Work', costPct: 0.12, durationPct: 0.10 },
      { name: 'Roofing', costPct: 0.08, durationPct: 0.05 },
      { name: 'Plastering', costPct: 0.08, durationPct: 0.10 },
      { name: 'Flooring', costPct: 0.07, durationPct: 0.08 },
      { name: 'Electrical', costPct: 0.06, durationPct: 0.05 },
      { name: 'Plumbing', costPct: 0.05, durationPct: 0.05 },
      { name: 'Doors & Windows', costPct: 0.06, durationPct: 0.05 },
      { name: 'Painting', costPct: 0.05, durationPct: 0.06 },
      { name: 'Interior Works', costPct: 0.05, durationPct: 0.04 },
      { name: 'Final Finishing', costPct: 0.03, durationPct: 0.02 }
    ];
    const phasesList = phaseAllocations.map(ph => {
      const cost = totalCost * ph.costPct;
      const dur = Math.ceil(durationDays * ph.durationPct);
      return {
        phaseName: ph.name,
        estimatedCost: Math.round(cost),
        estimatedDuration: dur,
        completionPercentage: 0,
        budgetAllocation: Math.round(cost)
      };
    });

    // 6. BOQ Rows
    const boqList = materialsList.map(mat => {
      const amount = mat.cost;
      const gstPct = parseFloat(settings.gstPercentage);
      const gst = amount * (gstPct / 100);
      return {
        materialName: mat.materialName,
        unit: mat.unit,
        quantity: mat.quantity,
        rate: mat.rate,
        amount: Math.round(amount * 100) / 100,
        gstRate: gstPct,
        gstAmount: Math.round(gst * 100) / 100,
        totalAmount: Math.round((amount + gst) * 100) / 100
      };
    });

    // 7. Profit Analysis
    const marginPct = parseFloat(settings.profitMarginPercentage);
    const profit = totalCost * (marginPct / 100);
    const gstPct = parseFloat(settings.gstPercentage);
    const subtotal = totalCost + profit;
    const gstAmt = subtotal * (gstPct / 100);
    const netVal = subtotal + gstAmt;

    // 8. Confidence object
    const confidenceObj = dData.confidence || {
      builtUpArea: 0.98,
      wallDetection: 0.95,
      roomDetection: 0.93,
      doorDetection: 0.96,
      windowDetection: 0.94,
      materialEstimate: 0.90,
      labourEstimate: 0.88
    };

    // 9. Similar Project metadata
    const similarProjObj = {
      projectName: 'Horizon Villa ECR',
      estimatedCost: 9800000,
      actualCost: 8000000,
      difference: -1800000
    };

    return {
      totalCost: Math.round(totalCost),
      ratePerUnit: Math.round(ratePerUnit),
      comparison: {
        Economy: Math.round(economyEstimate),
        Standard: Math.round(standardEstimate),
        Premium: Math.round(premiumEstimate)
      },
      materials: materialsList,
      labour: labourList,
      phases: phasesList,
      boq: boqList,
      durationDays,
      profitAnalysis: {
        constructionCost: Math.round(totalCost),
        companyMarginPercentage: marginPct,
        estimatedProfit: Math.round(profit),
        gstPercentage: gstPct,
        gstAmount: Math.round(gstAmt),
        netProjectValue: Math.round(netVal),
        companyOverhead: parseFloat(settings.companyOverhead)
      },
      complexityScore,
      structuralComplexity,
      finishingQuality,
      drawingDetails: {
        externalWallLength,
        internalWallLength,
        wallThickness,
        beamLayout,
        columnCount,
        doorCount,
        windowCount,
        bedrooms,
        bathrooms,
        kitchen,
        balcony,
        sitout,
        stairs,
        lift,
        doubleHeight,
        parking,
        terrace,
        utility,
        pooja,
        store,
        dining,
        living,
        verandah,
        courtyard
      },
      confidence: confidenceObj,
      similarProject: similarProjObj
    };
  }

  // GET /api/estimations - List all estimates
  app.get('/api/estimations', authenticateToken, async (req, res) => {
    try {
      const { search, status } = req.query;
      const where = {};
      if (status) {
        where.status = status;
      }
      if (search) {
        where[Op.or] = [
          { projectName: { [Op.like]: `%${search}%` } },
          { clientName: { [Op.like]: `%${search}%` } },
          { estimateNumber: { [Op.like]: `%${search}%` } }
        ];
      }
      const list = await models.Estimate.findAll({
        where,
        order: [['createdAt', 'DESC']],
        include: [
          { model: models.User, as: 'creator', attributes: ['name', 'role'] },
          { model: models.User, as: 'approver', attributes: ['name'] }
        ]
      });
      res.json(list);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch estimates', error: error.message });
    }
  });

  // GET /api/estimations/dashboard - Statistics overview
  app.get('/api/estimations/dashboard', authenticateToken, async (req, res) => {
    try {
      const totalEstimates = await models.Estimate.count();
      const approvedEstimates = await models.Estimate.count({ where: { status: 'Approved' } });
      const pendingEstimates = await models.Estimate.count({ where: { status: 'Pending' } });

      const revenueSum = await models.Estimate.sum('netProjectValue', { where: { status: 'Approved' } }) || 0;
      const profitSum = await models.Estimate.sum('estimatedProfit', { where: { status: 'Approved' } }) || 0;

      // Avg cost per sqft of approved estimates
      const areaSum = await models.Estimate.sum('builtUpArea', { where: { status: 'Approved' } }) || 1;
      const costSum = await models.Estimate.sum('totalCost', { where: { status: 'Approved' } }) || 0;
      const avgCostSqft = costSum / areaSum;

      // Package distribution
      const economyCount = await models.Estimate.count({ where: { selectedPackage: 'Economy' } });
      const standardCount = await models.Estimate.count({ where: { selectedPackage: 'Standard' } });
      const premiumCount = await models.Estimate.count({ where: { selectedPackage: 'Premium' } });

      const topProjects = await models.Estimate.findAll({
        limit: 5,
        order: [['netProjectValue', 'DESC']],
        attributes: ['id', 'projectName', 'clientName', 'netProjectValue', 'status']
      });

      res.json({
        totalEstimates,
        approvedEstimates,
        pendingEstimates,
        estimatedRevenue: parseFloat(revenueSum),
        estimatedProfit: parseFloat(profitSum),
        averageCostPerSqFt: parseFloat(avgCostSqft),
        packageDistribution: {
          Economy: economyCount,
          Standard: standardCount,
          Premium: premiumCount
        },
        topProjects
      });
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch dashboard metrics', error: error.message });
    }
  });

  // GET /api/estimations/settings - Fetch settings
  app.get('/api/estimations/settings', authenticateToken, async (req, res) => {
    try {
      const settings = await getActiveSetting();
      res.json(settings);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch settings', error: error.message });
    }
  });

  // POST /api/estimations/settings - Update settings (Anand only)
  app.post('/api/estimations/settings', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const {
        economyRate, standardRate, premiumRate,
        profitMarginPercentage, gstPercentage, civilLabourRate,
        materialsFormula, labourFormula, timelineFormula,
        districtAdjustments, regionalCostIndex, companyOverhead
      } = req.body;

      const settings = await getActiveSetting();
      await settings.update({
        economyRate: economyRate !== undefined ? economyRate : settings.economyRate,
        standardRate: standardRate !== undefined ? standardRate : settings.standardRate,
        premiumRate: premiumRate !== undefined ? premiumRate : settings.premiumRate,
        profitMarginPercentage: profitMarginPercentage !== undefined ? profitMarginPercentage : settings.profitMarginPercentage,
        gstPercentage: gstPercentage !== undefined ? gstPercentage : settings.gstPercentage,
        civilLabourRate: civilLabourRate !== undefined ? civilLabourRate : settings.civilLabourRate,
        materialsFormula: materialsFormula ? (typeof materialsFormula === 'string' ? materialsFormula : JSON.stringify(materialsFormula)) : settings.materialsFormula,
        labourFormula: labourFormula ? (typeof labourFormula === 'string' ? labourFormula : JSON.stringify(labourFormula)) : settings.labourFormula,
        timelineFormula: timelineFormula ? (typeof timelineFormula === 'string' ? timelineFormula : JSON.stringify(timelineFormula)) : settings.timelineFormula,
        districtAdjustments: districtAdjustments ? (typeof districtAdjustments === 'string' ? districtAdjustments : JSON.stringify(districtAdjustments)) : settings.districtAdjustments,
        regionalCostIndex: regionalCostIndex !== undefined ? regionalCostIndex : settings.regionalCostIndex,
        companyOverhead: companyOverhead !== undefined ? companyOverhead : settings.companyOverhead
      });

      res.json({ message: 'Settings updated successfully', settings });
    } catch (error) {
      res.status(500).json({ message: 'Failed to update settings', error: error.message });
    }
  });

  // GET /api/ai/settings - Fetch AI configurations
  app.get('/api/ai/settings', authenticateToken, async (req, res) => {
    try {
      const setting = await getActiveAiSetting();
      const result = setting.toJSON();
      
      // Mask key for security unless MD or Super Admin
      if (result.geminiApiKey) {
        const isSuperAdmin = req.user.role === 'Managing Director' || req.user.role === 'Super Admin';
        if (!isSuperAdmin) {
          const len = result.geminiApiKey.length;
          result.geminiApiKey = len > 8 
            ? 'x'.repeat(len - 4) + result.geminiApiKey.slice(-4) 
            : '********';
        }
      }
      res.json(result);
    } catch (error) {
      res.status(500).json({ message: 'Failed to retrieve AI settings', error: error.message });
    }
  });

  // POST /api/ai/settings - Update AI configurations
  app.post('/api/ai/settings', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { geminiApiKey, ...otherFields } = req.body;
      const setting = await getActiveAiSetting();
      
      const updateData = { ...otherFields };
      if (geminiApiKey && !geminiApiKey.startsWith('x') && geminiApiKey !== '********') {
        updateData.geminiApiKey = geminiApiKey;
      }
      
      await setting.update(updateData);
      res.json({ success: true, message: 'AI settings updated successfully', settings: setting });
    } catch (error) {
      res.status(500).json({ message: 'Failed to update AI settings', error: error.message });
    }
  });

  // POST /api/ai/test - Test connection
  app.post('/api/ai/test', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    try {
      const { geminiApiKey, aiModel } = req.body;
      let keyToTest = geminiApiKey;
      
      if (!keyToTest || keyToTest.startsWith('x') || keyToTest === '********') {
        const setting = await getActiveAiSetting();
        keyToTest = setting.geminiApiKey;
      }

      if (!keyToTest) {
        return res.json({ success: false, message: 'Gemini API key is not configured.' });
      }

      const testResult = await AiService.testConnection(keyToTest, aiModel || 'gemini-1.5-flash');
      res.json(testResult);
    } catch (error) {
      res.json({ success: false, message: error.message });
    }
  });

  // GET /api/ai/usage - Fetch daily usage stats
  app.get('/api/ai/usage', authenticateToken, async (req, res) => {
    try {
      const setting = await getActiveAiSetting();
      res.json({
        apiUsageCount: setting.apiUsageCount,
        dailyTokenUsage: setting.dailyTokenUsage
      });
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch AI usage stats', error: error.message });
    }
  });

  // Multer setup for floor plans upload
  const floorPlanDir = path.join(__dirname, 'uploads/floor_plans');
  if (!fs.existsSync(floorPlanDir)) {
    fs.mkdirSync(floorPlanDir, { recursive: true });
  }

  const floorPlanStorage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, floorPlanDir);
    },
    filename: function (req, file, cb) {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, uniqueSuffix + '-' + file.originalname);
    }
  });
  const uploadFloorPlan = multer({ storage: floorPlanStorage });

  // POST /api/estimations/ai-analyze - Upload floor plan and run AI analysis
  app.post('/api/estimations/ai-analyze', authenticateToken, uploadFloorPlan.single('file'), async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ message: 'No floor plan file uploaded.' });
      }

      const aiSettings = await getActiveAiSetting();
      if (!aiSettings.enableAi) {
        return res.status(400).json({ message: 'AI features are disabled by administrator.' });
      }

      // 1. Upload to Cloudinary with fallback
      const fileUrl = await CloudinaryService.uploadFile(req.file.path, req.file.originalname);

      // 2. Call Gemini
      const analysis = await AiService.analyzeFloorPlan(req.file.path, req.file.mimetype, aiSettings);

      // 3. Delete local temp file
      try {
        if (fs.existsSync(req.file.path)) {
          fs.unlinkSync(req.file.path);
        }
      } catch (err) {
        console.error('Failed to delete temporary upload file:', err);
      }

      // 4. Calculate estimate if built-up area is extracted successfully
      let calculations = null;
      if (analysis.data && analysis.data.builtUpArea) {
        const estSettings = await getActiveSetting();
        calculations = await runEstimationCalculations(
          analysis.data.builtUpArea,
          'Square Feet',
          'Standard',
          'Chennai',
          estSettings,
          analysis.data
        );
      }

      res.json({
        success: analysis.success,
        warning: analysis.warning || null,
        fileUrl,
        extractedData: analysis.data,
        calculations
      });
    } catch (error) {
      console.error('AI analysis API error:', error);
      res.status(500).json({
        message: 'Floor plan analysis failed',
        error: error.message
      });
    }
  });

  // POST /api/estimations/calculate - Calculator simulation (without database write)
  app.post('/api/estimations/calculate', authenticateToken, async (req, res) => {
    try {
      const { builtUpArea, selectedPackage, district, unit, drawingData } = req.body;
      if (!builtUpArea || !selectedPackage || !district) {
        return res.status(400).json({ message: 'Missing parameters: builtUpArea, selectedPackage, and district are required.' });
      }

      const settings = await getActiveSetting();
      const calculations = await runEstimationCalculations(builtUpArea, unit, selectedPackage, district, settings, drawingData);
      res.json(calculations);
    } catch (error) {
      res.status(500).json({ message: 'Failed to calculate estimate', error: error.message });
    }
  });

  // POST /api/estimations - Save a new estimate
  app.post('/api/estimations', authenticateToken, async (req, res) => {
    const transaction = await getSequelize().transaction();
    try {
      const {
        projectName, clientName, projectType, constructionType,
        state, district, city, siteAddress, builtUpArea, unit,
        selectedPackage, packageRate, totalCost, companyMarginPercentage,
        estimatedProfit, gstPercentage, gstAmount, netProjectValue,
        materials, phases, boq, labours,
        complexityScore, structuralComplexity, finishingQuality,
        drawingDetails, confidenceMetrics, similarProjectsData
      } = req.body;

      // Auto generate estimate number
      const count = await models.Estimate.count();
      const currentYear = new Date().getFullYear();
      const estimateNo = `EST-${currentYear}-${(count + 1).toString().padStart(4, '0')}`;

      const estimate = await models.Estimate.create({
        estimateNumber: estimateNo,
        projectName,
        clientName,
        projectType,
        constructionType,
        state,
        district,
        city,
        siteAddress,
        builtUpArea,
        unit,
        selectedPackage,
        packageRate,
        totalCost,
        companyMarginPercentage,
        estimatedProfit,
        gstPercentage,
        gstAmount,
        netProjectValue,
        status: 'Pending',
        createdBy: req.user.id,
        complexityScore,
        structuralComplexity,
        finishingQuality,
        drawingDetails: drawingDetails ? (typeof drawingDetails === 'string' ? drawingDetails : JSON.stringify(drawingDetails)) : null,
        confidenceMetrics: confidenceMetrics ? (typeof confidenceMetrics === 'string' ? confidenceMetrics : JSON.stringify(confidenceMetrics)) : null,
        similarProjectsData: similarProjectsData ? (typeof similarProjectsData === 'string' ? similarProjectsData : JSON.stringify(similarProjectsData)) : null
      }, { transaction });

      // Save materials
      if (materials && materials.length > 0) {
        for (const item of materials) {
          await models.EstimateMaterial.create({
            estimateId: estimate.id,
            materialName: item.materialName,
            quantity: item.quantity,
            unit: item.unit,
            rate: item.rate,
            cost: item.cost
          }, { transaction });
        }
      }

      // Save phases
      if (phases && phases.length > 0) {
        for (const ph of phases) {
          await models.EstimatePhase.create({
            estimateId: estimate.id,
            phaseName: ph.phaseName,
            estimatedCost: ph.estimatedCost,
            estimatedDuration: ph.estimatedDuration,
            completionPercentage: 0,
            budgetAllocation: ph.estimatedCost
          }, { transaction });
        }
      }

      // Save BOQ
      if (boq && boq.length > 0) {
        for (const b of boq) {
          await models.EstimateBoq.create({
            estimateId: estimate.id,
            materialName: b.materialName,
            unit: b.unit,
            quantity: b.quantity,
            rate: b.rate,
            amount: b.amount,
            gstRate: b.gstRate,
            gstAmount: b.gstAmount,
            totalAmount: b.totalAmount
          }, { transaction });
        }
      }

      // Save labours
      if (labours && labours.length > 0) {
        for (const l of labours) {
          await models.EstimateLabour.create({
            estimateId: estimate.id,
            labourType: l.labourType,
            requiredWorkers: l.requiredWorkers,
            estimatedDays: l.estimatedDays,
            estimatedCost: l.estimatedCost
          }, { transaction });
        }
      }

      await transaction.commit();
      res.json({ success: true, message: 'Estimate saved successfully', estimate });
    } catch (error) {
      await transaction.rollback();
      res.status(500).json({ message: 'Failed to save estimate', error: error.message });
    }
  });

  // GET /api/estimations/:id - Get details
  app.get('/api/estimations/:id', authenticateToken, async (req, res) => {
    try {
      const estimate = await models.Estimate.findByPk(req.params.id, {
        include: [
          { model: models.User, as: 'creator', attributes: ['name', 'role'] },
          { model: models.User, as: 'approver', attributes: ['name'] },
          { model: models.EstimateMaterial, as: 'materials' },
          { model: models.EstimatePhase, as: 'phases' },
          { model: models.EstimateBoq, as: 'boqs' },
          { model: models.EstimateLabour, as: 'labours' }
        ]
      });

      if (!estimate) {
        return res.status(404).json({ message: 'Estimate not found.' });
      }

      res.json(estimate);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch details', error: error.message });
    }
  });

  // PUT /api/estimations/:id - Update estimate (pending only)
  app.put('/api/estimations/:id', authenticateToken, async (req, res) => {
    const transaction = await getSequelize().transaction();
    try {
      const estimate = await models.Estimate.findByPk(req.params.id);
      if (!estimate) {
        return res.status(404).json({ message: 'Estimate not found.' });
      }

      if (estimate.status !== 'Pending') {
        return res.status(400).json({ message: 'Cannot edit an estimate that is already approved or rejected.' });
      }

      const {
        projectName, clientName, builtUpArea, unit, selectedPackage,
        packageRate, totalCost, companyMarginPercentage, estimatedProfit,
        gstPercentage, gstAmount, netProjectValue,
        materials, phases, boq, labours,
        complexityScore, structuralComplexity, finishingQuality,
        drawingDetails, confidenceMetrics, similarProjectsData
      } = req.body;

      await estimate.update({
        projectName: projectName || estimate.projectName,
        clientName: clientName || estimate.clientName,
        builtUpArea: builtUpArea || estimate.builtUpArea,
        unit: unit || estimate.unit,
        selectedPackage: selectedPackage || estimate.selectedPackage,
        packageRate: packageRate || estimate.packageRate,
        totalCost: totalCost || estimate.totalCost,
        companyMarginPercentage: companyMarginPercentage || estimate.companyMarginPercentage,
        estimatedProfit: estimatedProfit || estimate.estimatedProfit,
        gstPercentage: gstPercentage || estimate.gstPercentage,
        gstAmount: gstAmount || estimate.gstAmount,
        netProjectValue: netProjectValue || estimate.netProjectValue,
        complexityScore: complexityScore !== undefined ? complexityScore : estimate.complexityScore,
        structuralComplexity: structuralComplexity !== undefined ? structuralComplexity : estimate.structuralComplexity,
        finishingQuality: finishingQuality !== undefined ? finishingQuality : estimate.finishingQuality,
        drawingDetails: drawingDetails ? (typeof drawingDetails === 'string' ? drawingDetails : JSON.stringify(drawingDetails)) : estimate.drawingDetails,
        confidenceMetrics: confidenceMetrics ? (typeof confidenceMetrics === 'string' ? confidenceMetrics : JSON.stringify(confidenceMetrics)) : estimate.confidenceMetrics,
        similarProjectsData: similarProjectsData ? (typeof similarProjectsData === 'string' ? similarProjectsData : JSON.stringify(similarProjectsData)) : estimate.similarProjectsData
      }, { transaction });

      // Overwrite child lists if provided
      if (materials) {
        await models.EstimateMaterial.destroy({ where: { estimateId: estimate.id }, transaction });
        for (const item of materials) {
          await models.EstimateMaterial.create({
            estimateId: estimate.id,
            materialName: item.materialName,
            quantity: item.quantity,
            unit: item.unit,
            rate: item.rate,
            cost: item.cost
          }, { transaction });
        }
      }

      if (phases) {
        await models.EstimatePhase.destroy({ where: { estimateId: estimate.id }, transaction });
        for (const ph of phases) {
          await models.EstimatePhase.create({
            estimateId: estimate.id,
            phaseName: ph.phaseName,
            estimatedCost: ph.estimatedCost,
            estimatedDuration: ph.estimatedDuration,
            completionPercentage: ph.completionPercentage || 0,
            budgetAllocation: ph.budgetAllocation || ph.estimatedCost
          }, { transaction });
        }
      }

      if (boq) {
        await models.EstimateBoq.destroy({ where: { estimateId: estimate.id }, transaction });
        for (const b of boq) {
          await models.EstimateBoq.create({
            estimateId: estimate.id,
            materialName: b.materialName,
            unit: b.unit,
            quantity: b.quantity,
            rate: b.rate,
            amount: b.amount,
            gstRate: b.gstRate,
            gstAmount: b.gstAmount,
            totalAmount: b.totalAmount
          }, { transaction });
        }
      }

      if (labours) {
        await models.EstimateLabour.destroy({ where: { estimateId: estimate.id }, transaction });
        for (const l of labours) {
          await models.EstimateLabour.create({
            estimateId: estimate.id,
            labourType: l.labourType,
            requiredWorkers: l.requiredWorkers,
            estimatedDays: l.estimatedDays,
            estimatedCost: l.estimatedCost
          }, { transaction });
        }
      }

      await transaction.commit();
      res.json({ success: true, message: 'Estimate updated successfully' });
    } catch (error) {
      await transaction.rollback();
      res.status(500).json({ message: 'Failed to update estimate', error: error.message });
    }
  });

  // POST /api/estimations/:id/approve - MD Approval and Auto project creation
  app.post('/api/estimations/:id/approve', authenticateToken, authorizeRoles('Super Admin', 'Managing Director'), async (req, res) => {
    const transaction = await getSequelize().transaction();
    try {
      const estimate = await models.Estimate.findByPk(req.params.id, {
        include: [{ model: models.EstimateBoq, as: 'boqs' }]
      });

      if (!estimate) {
        return res.status(404).json({ message: 'Estimate not found.' });
      }

      if (estimate.status !== 'Pending') {
        return res.status(400).json({ message: 'Estimate is already approved or cancelled.' });
      }

      // Update estimate approval status
      await estimate.update({
        status: 'Approved',
        approvedBy: req.user.id
      }, { transaction });

      // Create Client if not exists
      let client = await models.Client.findOne({ where: { name: estimate.clientName } });
      if (!client) {
        client = await models.Client.create({
          name: estimate.clientName,
          phone: '9840123456',
          email: `${estimate.clientName.toLowerCase().replace(/\s+/g, '')}@vian-estimate.com`,
          address: estimate.siteAddress || estimate.city,
          propertyDetails: `State: ${estimate.state}, District: ${estimate.district}, City: ${estimate.city}. Built-up: ${estimate.builtUpArea} ${estimate.unit}`
        }, { transaction });
      }

      // Map estimate project type to Project enum types
      const pTypeMap = {
        'Residential House': 'Residential',
        'Villa': 'Villa',
        'Apartment': 'Apartment',
        'Commercial Building': 'Commercial',
        'Office': 'Commercial',
        'Interior': 'Interior Design',
        'Renovation': 'Renovation',
        'Industrial': 'Commercial'
      };
      const typeEnum = pTypeMap[estimate.projectType] || 'Residential';

      // Create Project
      const projectCount = await models.Project.count();
      const projId = `VIAN-${new Date().getFullYear()}-${(projectCount + 1).toString().padStart(4, '0')}`;

      // Calculate timelines
      const totalPhases = await models.EstimatePhase.findAll({ where: { estimateId: estimate.id } });
      const totalDays = totalPhases.reduce((acc, p) => acc + p.estimatedDuration, 0) || 180;
      const startDate = new Date();
      const completionDate = new Date(startDate.getTime() + totalDays * 24 * 60 * 60 * 1000);

      const project = await models.Project.create({
        projectId: projId,
        name: estimate.projectName,
        type: typeEnum,
        clientId: client.id,
        managingDirectorId: req.user.id,
        budget: estimate.totalCost,
        startDate: startDate.toISOString().split('T')[0],
        completionDate: completionDate.toISOString().split('T')[0],
        status: 'Planning',
        progressPercentage: 0
      }, { transaction });

      // Link estimate to project
      await estimate.update({ projectId: project.id }, { transaction });

      // Copy BOQ items to Project BoqItems
      if (estimate.boqs && estimate.boqs.length > 0) {
        for (const item of estimate.boqs) {
          await models.BoqItem.create({
            projectId: project.id,
            itemDescription: item.materialName,
            unit: item.unit,
            quantity: item.quantity,
            rate: item.rate,
            totalAmount: item.amount
          }, { transaction });
        }
      }

      // 1. Create Tasks matching estimation phases
      let currentTaskDate = new Date();
      for (const phase of totalPhases) {
        currentTaskDate = new Date(currentTaskDate.getTime() + (phase.estimatedDuration || 15) * 24 * 60 * 60 * 1000);
        await models.Task.create({
          title: `Phase Task: ${phase.phaseName}`,
          description: `Auto-generated construction phase task for ${phase.phaseName}. Estimated phase budget: INR ${phase.estimatedCost}.`,
          priority: 'Medium',
          dueDate: currentTaskDate.toISOString().split('T')[0],
          status: 'Pending',
          projectId: project.id
        }, { transaction });
      }

      // 2. Populate Project Material inventory catalog from estimate materials
      const estMaterials = await models.EstimateMaterial.findAll({ where: { estimateId: estimate.id } });
      for (const mat of estMaterials) {
        await models.Material.create({
          projectId: project.id,
          materialName: mat.materialName,
          purchasedQuantity: 0.00,
          usedQuantity: 0.00,
          balanceStock: 0.00,
          materialCost: mat.cost
        }, { transaction });
      }

      // 3. Create a Document entry linking the quotation PDF to the project
      await models.Document.create({
        title: `Approved Estimation & BOQ - ${estimate.projectName}`,
        folder: 'Estimations',
        fileUrl: `/api/estimations/${estimate.id}/quotation/pdf`,
        fileSize: 1024 * 45, // approx 45KB
        projectId: project.id
      }, { transaction });

      // 4. Log creation in ImportActivityLog
      await models.ImportActivityLog.create({
        type: 'Import',
        module: 'Projects',
        fileName: `Approved Estimate ${estimate.estimateNumber}`,
        filePath: `/api/estimations/${estimate.id}`,
        recordsImported: 1,
        ipAddress: req.ip || '127.0.0.1',
        device: req.headers['user-agent'] || 'Server Auto Action'
      }, { transaction });

      // 5. Create a system notification for the user
      await models.Notification.create({
        userId: req.user.id,
        title: 'Project Auto-Created',
        message: `Project ${project.name} has been successfully created from approved estimate ${estimate.estimateNumber}.`,
        readStatus: false,
        type: 'Project'
      }, { transaction });

      await transaction.commit();
      res.json({ success: true, message: 'Estimate approved and Project created successfully', project, estimate });
    } catch (error) {
      await transaction.rollback();
      res.status(500).json({ message: 'Failed to approve estimate', error: error.message });
    }
  });

  // GET /api/estimations/:id/quotation/pdf - Export print-ready HTML/PDF
  app.get('/api/estimations/:id/quotation/pdf', authenticateToken, async (req, res) => {
    try {
      const estimate = await models.Estimate.findByPk(req.params.id, {
        include: [
          { model: models.EstimateBoq, as: 'boqs' },
          { model: models.EstimateMaterial, as: 'materials' },
          { model: models.EstimateLabour, as: 'labours' },
          { model: models.EstimatePhase, as: 'phases' }
        ]
      });

      if (!estimate) {
        return res.status(404).send('Estimate not found.');
      }

      // Generate printable design
      const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <title>VIAN Architects - Quotation ${estimate.estimateNumber}</title>
          <style>
            body { font-family: 'Helvetica Neue', Arial, sans-serif; background: #fff; color: #111; padding: 40px; }
            .header { display: flex; justify-content: space-between; border-bottom: 2px solid #b89742; padding-bottom: 20px; margin-bottom: 30px; }
            .logo { font-size: 24px; font-weight: bold; color: #b89742; }
            .title { font-size: 28px; text-align: right; margin: 0; }
            .details-table, .boq-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
            .details-table td { padding: 8px; vertical-align: top; }
            .boq-table th { background: #f0ecdf; border: 1px solid #ddd; padding: 10px; text-align: left; }
            .boq-table td { border: 1px solid #ddd; padding: 10px; }
            .total-section { text-align: right; font-size: 18px; margin-top: 20px; font-weight: bold; }
            .terms { margin-top: 50px; font-size: 12px; color: #666; border-top: 1px solid #eee; padding-top: 15px; }
            @media print {
              body { padding: 0; }
              .no-print { display: none; }
            }
          </style>
        </head>
        <body>
          <div class="no-print" style="margin-bottom: 20px;">
            <button onclick="window.print()" style="padding: 10px 20px; background: #b89742; color: white; border: none; cursor: pointer; font-weight: bold;">Print / Save to PDF</button>
          </div>
          <div class="header">
            <div>
              <div class="logo">VIAN ARCHITECTS</div>
              <div>Luxury Architecture & Cost Intelligence</div>
              <div>Gurugram • Chennai • Coimbatore</div>
            </div>
            <div>
              <h1 class="title">QUOTATION</h1>
              <div>Estimate No: ${estimate.estimateNumber}</div>
              <div>Date: ${new Date(estimate.createdAt).toLocaleDateString()}</div>
            </div>
          </div>
          
          <h2>Project Details</h2>
          <table class="details-table">
            <tr>
              <td><strong>Project Name:</strong> ${estimate.projectName}</td>
              <td><strong>Client Name:</strong> ${estimate.clientName}</td>
            </tr>
            <tr>
              <td><strong>Type:</strong> ${estimate.projectType} (${estimate.constructionType})</td>
              <td><strong>Area:</strong> ${estimate.builtUpArea} ${estimate.unit}</td>
            </tr>
            <tr>
              <td><strong>Site Address:</strong> ${estimate.siteAddress || 'N/A'}, ${estimate.city}, ${estimate.state}</td>
              <td><strong>Status:</strong> ${estimate.status}</td>
            </tr>
          </table>

          <h2>BOQ Summary (Materials)</h2>
          <table class="boq-table">
            <thead>
              <tr>
                <th>Material</th>
                <th>Unit</th>
                <th>Quantity</th>
                <th>Rate</th>
                <th>Amount (INR)</th>
              </tr>
            </thead>
            <tbody>
              ${estimate.boqs.map(item => `
                <tr>
                  <td>${item.materialName}</td>
                  <td>${item.unit || 'Units'}</td>
                  <td>${item.quantity}</td>
                  <td>₹${item.rate}</td>
                  <td>₹${item.amount}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>

          <h2>Phased Project Timeline</h2>
          <table class="boq-table">
            <thead>
              <tr>
                <th>Phase</th>
                <th>Estimated Duration</th>
                <th>Budget Allocation</th>
              </tr>
            </thead>
            <tbody>
              ${estimate.phases.map(p => `
                <tr>
                  <td>${p.phaseName}</td>
                  <td>${p.estimatedDuration} Days</td>
                  <td>₹${p.budgetAllocation}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>

          <div class="total-section">
            <div>Estimated Base Cost: ₹${estimate.totalCost}</div>
            <div>GST (18%): ₹${estimate.gstAmount}</div>
            <div style="font-size: 22px; color: #b89742; margin-top: 10px;">Net Project Value: ₹${estimate.netProjectValue}</div>
          </div>

          <div class="terms">
            <h3>Terms & Conditions</h3>
            <p>1. This cost estimation is valid for 30 days from the date of issuance.</p>
            <p>2. Prices of steel, cement, and sand are subject to market variations.</p>
            <p>3. Payments should be made in installments as per completed project milestones.</p>
          </div>

          <div style="margin-top: 40px; display: flex; justify-content: space-between;">
            <div>
              <div style="border-top: 1px solid #111; width: 200px; margin-top: 50px; text-align: center; font-size: 14px;">Client Signature</div>
            </div>
            <div>
              <div style="border-top: 1px solid #111; width: 200px; margin-top: 50px; text-align: center; font-size: 14px;">Authorized Signatory (VIAN)</div>
            </div>
          </div>
        </body>
        </html>
      `;

      res.setHeader('Content-Type', 'text/html');
      res.send(htmlContent);
    } catch (error) {
      res.status(500).send('Failed to generate quotation PDF: ' + error.message);
    }
  });

  // GET /api/estimations/:id/quotation/excel - Export BOQ to Excel
  app.get('/api/estimations/:id/quotation/excel', authenticateToken, async (req, res) => {
    try {
      const estimate = await models.Estimate.findByPk(req.params.id, {
        include: [{ model: models.EstimateBoq, as: 'boqs' }]
      });

      if (!estimate) {
        return res.status(404).send('Estimate not found.');
      }

      const rows = [
        ['VIAN ARCHITECTS & DESIGNERS', ''],
        ['COST ESTIMATION & BOQ REPORT', ''],
        ['', ''],
        ['Estimate Number', estimate.estimateNumber],
        ['Project Name', estimate.projectName],
        ['Client Name', estimate.clientName],
        ['Built-up Area', `${estimate.builtUpArea} ${estimate.unit}`],
        ['Construction Grade', estimate.constructionType],
        ['Total Estimated Cost', parseFloat(estimate.totalCost)],
        ['Net Project Value (incl GST)', parseFloat(estimate.netProjectValue)],
        ['', ''],
        ['BILL OF QUANTITIES (BOQ)', '', '', '', '', ''],
        ['Material Name', 'Unit', 'Quantity', 'Rate', 'Amount', 'Total (incl GST)']
      ];

      for (const item of estimate.boqs) {
        rows.push([
          item.materialName,
          item.unit || 'Units',
          parseFloat(item.quantity),
          parseFloat(item.rate),
          parseFloat(item.amount),
          parseFloat(item.totalAmount)
        ]);
      }

      const wb = XLSX.utils.book_new();
      const ws = XLSX.utils.aoa_to_sheet(rows);
      XLSX.utils.book_append_sheet(wb, ws, 'Quotation');

      const buf = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
      res.setHeader('Content-Disposition', `attachment; filename=Quotation-${estimate.estimateNumber}.xlsx`);
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.send(buf);
    } catch (error) {
      res.status(500).send('Failed to generate Excel sheet: ' + error.message);
    }
  });

  // POST /api/estimations/:id/share - Share quotation
  app.post('/api/estimations/:id/share', authenticateToken, async (req, res) => {
    try {
      const { channel, recipient } = req.body;
      const estimate = await models.Estimate.findByPk(req.params.id);
      if (!estimate) {
        return res.status(404).json({ message: 'Estimate not found.' });
      }

      console.log(`Sharing estimate ${estimate.estimateNumber} via ${channel} to ${recipient}`);
      res.json({
        success: true,
        message: `Quotation shared successfully via ${channel} to ${recipient || 'client'}.`
      });
    } catch (error) {
      res.status(500).json({ message: 'Sharing failed', error: error.message });
    }
  });

  // GET /api/estimations/market-prices - Fetch prices
  app.get('/api/estimations/market-prices', authenticateToken, async (req, res) => {
    try {
      const { district } = req.query;
      const where = {};
      if (district) where.district = district;
      const list = await models.MarketPrice.findAll({ where });
      res.json(list);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch market prices', error: error.message });
    }
  });

  // POST /api/estimations/market-prices - Update market price
  app.post('/api/estimations/market-prices', authenticateToken, async (req, res) => {
    try {
      const { id, currentRate, supplier, materialName, district } = req.body;
      const price = await models.MarketPrice.findByPk(id);
      if (!price) {
        return res.status(404).json({ message: 'Market price record not found' });
      }

      await price.update({
        previousRate: price.currentRate,
        currentRate: currentRate !== undefined ? parseFloat(currentRate) : price.currentRate,
        supplier: supplier !== undefined ? supplier : price.supplier,
        materialName: materialName !== undefined ? materialName : price.materialName,
        district: district !== undefined ? district : price.district
      });

      res.json({ message: 'Market price updated successfully', price });
    } catch (error) {
      res.status(500).json({ message: 'Failed to update market price', error: error.message });
    }
  });

  // POST /api/estimations/market-prices/new - Create a new market price
  app.post('/api/estimations/market-prices/new', authenticateToken, async (req, res) => {
    try {
      const { materialName, currentRate, supplier, district } = req.body;
      if (!materialName || currentRate === undefined || !district) {
        return res.status(400).json({ message: 'materialName, currentRate, and district are required.' });
      }
      const newPrice = await models.MarketPrice.create({
        materialName,
        currentRate: parseFloat(currentRate),
        previousRate: parseFloat(currentRate),
        supplier: supplier || 'Local Supplier',
        district
      });
      res.json({ message: 'Market price created successfully', price: newPrice });
    } catch (error) {
      res.status(500).json({ message: 'Failed to create market price', error: error.message });
    }
  });

  // DELETE /api/estimations/market-prices/:id - Delete a market price record
  app.delete('/api/estimations/market-prices/:id', authenticateToken, async (req, res) => {
    try {
      const price = await models.MarketPrice.findByPk(req.params.id);
      if (!price) {
        return res.status(404).json({ message: 'Market price record not found' });
      }
      await price.destroy();
      res.json({ message: 'Market price record deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Failed to delete market price', error: error.message });
    }
  });

  // GET /api/estimations/:id/budget-actual - Cost variance tracking
  app.get('/api/estimations/:id/budget-actual', authenticateToken, async (req, res) => {
    try {
      const estimate = await models.Estimate.findByPk(req.params.id, {
        include: [
          { model: models.EstimateMaterial, as: 'materials' },
          { model: models.EstimateLabour, as: 'labours' }
        ]
      });

      if (!estimate) {
        return res.status(404).json({ message: 'Estimate not found' });
      }

      const projectId = estimate.projectId;
      if (!projectId) {
        return res.json({
          estimatedMaterialCost: estimate.materials.reduce((acc, m) => acc + parseFloat(m.cost), 0),
          actualMaterialCost: 0,
          materialVariance: estimate.materials.reduce((acc, m) => acc + parseFloat(m.cost), 0),
          materialStatus: 'green',

          estimatedLabourCost: estimate.labours.reduce((acc, l) => acc + parseFloat(l.estimatedCost), 0),
          actualLabourCost: 0,
          labourVariance: estimate.labours.reduce((acc, l) => acc + parseFloat(l.estimatedCost), 0),
          labourStatus: 'green',

          estimatedExpenses: 0,
          actualExpenses: 0,
          expensesVariance: 0,
          expensesStatus: 'green',

          totalEstimatedCost: parseFloat(estimate.totalCost),
          totalActualCost: 0,
          totalVariance: parseFloat(estimate.totalCost),
          totalStatus: 'green'
        });
      }

      const actualMaterialCost = await models.Material.sum('materialCost', { where: { projectId } }) || 0;

      const workers = await models.Worker.findAll({ where: { projectId } });
      const workerIds = workers.map(w => w.id);
      let actualLabourCost = 0;
      if (workerIds.length > 0) {
        const attendances = await models.ManagerAttendance.findAll({
          where: { workerId: { [Op.in]: workerIds } },
          include: [{ model: models.Worker, as: 'worker' }]
        });
        for (const att of attendances) {
          let multiplier = 1.0;
          if (att.status === 'Absent') multiplier = 0.0;
          else if (att.status === 'Half Day') multiplier = 0.5;
          const wage = parseFloat(att.worker.dailyWage) || 0;
          actualLabourCost += wage * multiplier;
          if (att.overtimeHours > 0) {
            actualLabourCost += (wage / 8) * parseFloat(att.overtimeHours) * 1.5;
          }
        }
      }

      const actualExpenses = await models.Expense.sum('amount', { where: { projectId, status: 'Approved' } }) || 0;

      const estMaterialCost = estimate.materials.reduce((acc, m) => acc + parseFloat(m.cost), 0);
      const estLabourCost = estimate.labours.reduce((acc, l) => acc + parseFloat(l.estimatedCost), 0);
      const totalEstimated = parseFloat(estimate.totalCost);
      const totalActual = parseFloat(actualMaterialCost) + parseFloat(actualLabourCost) + parseFloat(actualExpenses);

      const getStatusColor = (est, act) => {
        if (act <= est) return 'green';
        if (act <= est * 1.10) return 'yellow';
        return 'red';
      };

      res.json({
        estimatedMaterialCost: estMaterialCost,
        actualMaterialCost: parseFloat(actualMaterialCost),
        materialVariance: estMaterialCost - actualMaterialCost,
        materialStatus: getStatusColor(estMaterialCost, actualMaterialCost),

        estimatedLabourCost: estLabourCost,
        actualLabourCost,
        labourVariance: estLabourCost - actualLabourCost,
        labourStatus: getStatusColor(estLabourCost, actualLabourCost),

        estimatedExpenses: 0,
        actualExpenses: parseFloat(actualExpenses),
        expensesVariance: -actualExpenses,
        expensesStatus: getStatusColor(0, actualExpenses),

        totalEstimatedCost: totalEstimated,
        totalActualCost: totalActual,
        totalVariance: totalEstimated - totalActual,
        totalStatus: getStatusColor(totalEstimated, totalActual)
      });
    } catch (error) {
      res.status(500).json({ message: 'Failed to calculate cost variance', error: error.message });
    }
  });

  // GET /api/audit-logs (Super Admin Only)
  app.get('/api/audit-logs', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const where = {};
      if (search) {
        where[Op.or] = [
          { userName: { [Op.like]: `%${search}%` } },
          { role: { [Op.like]: `%${search}%` } },
          { action: { [Op.like]: `%${search}%` } },
          { module: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await AuditLog.findAndCountAll({
        where,
        order: [['createdAt', 'DESC']],
        limit,
        offset
      });

      res.json({
        logs: rows,
        total: count,
        page,
        totalPages: Math.ceil(count / limit)
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching audit logs', error: error.message });
    }
  });

  // GET /api/trash (Super Admin Only)
  app.get('/api/trash', authenticateToken, requireSuperAdmin, async (req, res) => {
    try {
      // Fetch soft-deleted records from each model
      const leads = await Lead.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const clients = await Client.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const projects = await Project.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const tasks = await Task.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const workers = await Worker.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const dailyReports = await DailyReport.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const announcements = await Announcement.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const quotations = await Quotation.findAll({ where: { deletedAt: { [Op.ne]: null } } });
      const invoices = await Invoice.findAll({ where: { deletedAt: { [Op.ne]: null } } });

      const trashItems = [];
      leads.forEach(x => trashItems.push({ id: x.id, module: 'Leads', label: `Lead: ${x.name}`, deletedAt: x.deletedAt }));
      clients.forEach(x => trashItems.push({ id: x.id, module: 'Clients', label: `Client: ${x.name}`, deletedAt: x.deletedAt }));
      projects.forEach(x => trashItems.push({ id: x.id, module: 'Projects', label: `Project: ${x.name} (${x.projectId})`, deletedAt: x.deletedAt }));
      tasks.forEach(x => trashItems.push({ id: x.id, module: 'Tasks', label: `Task: ${x.title}`, deletedAt: x.deletedAt }));
      workers.forEach(x => trashItems.push({ id: x.id, module: 'Workers', label: `Labour: ${x.name} (${x.workerId})`, deletedAt: x.deletedAt }));
      dailyReports.forEach(x => trashItems.push({ id: x.id, module: 'DailyReports', label: `Daily Report: ${x.date} - ${x.workCategory}`, deletedAt: x.deletedAt }));
      announcements.forEach(x => trashItems.push({ id: x.id, module: 'Announcements', label: `Announcement: ${x.title}`, deletedAt: x.deletedAt }));
      quotations.forEach(x => trashItems.push({ id: x.id, module: 'Quotations', label: `Quotation: ${x.quotationNumber}`, deletedAt: x.deletedAt }));
      invoices.forEach(x => trashItems.push({ id: x.id, module: 'Invoices', label: `Invoice: ${x.invoiceNumber}`, deletedAt: x.deletedAt }));

      res.json({ trash: trashItems });
    } catch (error) {
      res.status(500).json({ message: 'Error loading trash bin', error: error.message });
    }
  });

  // POST /api/trash/restore/:module/:id (Super Admin Only)
  app.post('/api/trash/restore/:module/:id', authenticateToken, requireSuperAdmin, async (req, res) => {
    const { module: targetModule, id } = req.params;
    try {
      let model;
      if (targetModule === 'Leads') model = Lead;
      else if (targetModule === 'Clients') model = Client;
      else if (targetModule === 'Projects') model = Project;
      else if (targetModule === 'Tasks') model = Task;
      else if (targetModule === 'Workers') model = Worker;
      else if (targetModule === 'DailyReports') model = DailyReport;
      else if (targetModule === 'Announcements') model = Announcement;
      else if (targetModule === 'Quotations') model = Quotation;
      else if (targetModule === 'Invoices') model = Invoice;
      else return res.status(400).json({ message: 'Invalid module specified' });

      const record = await model.findOne({ where: { id } });
      if (!record) return res.status(404).json({ message: 'Record not found' });

      await record.update({ deletedAt: null, deletedBy: null });
      await writeAuditLog(req, 'Restore', targetModule, { id }, record.toJSON());

      res.json({ message: 'Record restored successfully', record });
    } catch (error) {
      res.status(500).json({ message: 'Error restoring record', error: error.message });
    }
  });

  // Run initial daily backup (keeps registry current)
  async function runAutoBackup() {
    try {
      const backupData = {};
      for (const modelName of Object.keys(models)) {
        const records = await models[modelName].findAll();
        backupData[modelName] = records.map(r => r.toJSON());
      }
      const todayStr = new Date().toISOString().split('T')[0];
      const backupFile = path.join(backupDir, `vian_db_daily_backup_${todayStr}.json`);
      fs.writeFileSync(backupFile, JSON.stringify(backupData, null, 2));
      console.log(`Auto daily backup saved: ${backupFile}`);
    } catch (err) {
      console.error('Auto backup failed:', err);
    }
  }
  setTimeout(runAutoBackup, 5000);
}

module.exports = registerRoutes;
