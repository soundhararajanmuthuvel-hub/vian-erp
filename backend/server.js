const express = require('express');
const cors = require('cors');
const compression = require('compression');
const helmet = require('helmet');
const morgan = require('morgan');
const bcrypt = require('bcryptjs');
const { connectDB } = require('./database/db');
const { initModels } = require('./database/models');
const registerRoutes = require('./routes');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();

const allowedOrigins = [
  'https://vianerp.netlify.app',
  'http://localhost:5050',
  'http://localhost:3000',
  'http://127.0.0.1:5050',
  'http://127.0.0.1:3000'
];

app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1 || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      return callback(null, true);
    }
    return callback(new Error('The CORS policy for this site does not allow access from the specified Origin.'), false);
  },
  credentials: true
}));

app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: false
}));
app.use(compression());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const PORT = process.env.PORT || 5050;

async function runMigrations(sequelizeInstance) {
  const dialect = sequelizeInstance.options.dialect;
  
  if (dialect === 'mysql') {
    console.log('Running auto-migrations for MySQL...');
    const addColumnIfMissing = async (tableName, columnName, columnDefinition) => {
      try {
        const [results] = await sequelizeInstance.query(
          `SELECT COUNT(*) as count FROM information_schema.columns 
           WHERE table_schema = DATABASE() AND table_name = '${tableName}' AND column_name = '${columnName}'`
        );
        if (results && results[0] && results[0].count === 0) {
          console.log(`Adding missing column ${columnName} to table ${tableName}...`);
          await sequelizeInstance.query(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnDefinition}`);
        }
      } catch (err) {
        console.error(`Error migrating ${tableName}.${columnName}:`, err.message);
      }
    };

    // leads table columns
    await addColumnIfMissing('leads', 'company_name', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'contact_person', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'city', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'state', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'country', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'gst_number', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'pan', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'industry', 'VARCHAR(255) NULL');
    await addColumnIfMissing('leads', 'attachments', 'TEXT NULL');
    await addColumnIfMissing('leads', 'converted', "ENUM('Yes', 'No') DEFAULT 'No'");
    await addColumnIfMissing('leads', 'converted_date', 'DATETIME NULL');
    await addColumnIfMissing('leads', 'converted_by', 'INT NULL');
    await addColumnIfMissing('leads', 'client_id', 'VARCHAR(255) NULL');

    // clients table columns
    await addColumnIfMissing('clients', 'client_id', 'VARCHAR(255) UNIQUE NULL');
    await addColumnIfMissing('clients', 'company_name', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'contact_person', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'city', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'state', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'country', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'gst_number', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'pan', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'lead_source', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'industry', 'VARCHAR(255) NULL');
    await addColumnIfMissing('clients', 'notes', 'TEXT NULL');
    await addColumnIfMissing('clients', 'attachments', 'TEXT NULL');
    await addColumnIfMissing('clients', 'assigned_to', 'INT NULL');
    await addColumnIfMissing('clients', 'lead_id', 'INT NULL');

    // Soft-delete / is_archived migrations
    await addColumnIfMissing('leads', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('leads', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('clients', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('clients', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('projects', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('projects', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('projects', 'is_archived', 'BOOLEAN DEFAULT FALSE');
    await addColumnIfMissing('tasks', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('tasks', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('workers', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('workers', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('daily_reports', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('daily_reports', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('announcements', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('announcements', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('quotations', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('quotations', 'deleted_by', 'INT NULL');
    await addColumnIfMissing('invoices', 'deleted_at', 'TIMESTAMP NULL');
    await addColumnIfMissing('invoices', 'deleted_by', 'INT NULL');
  } else if (dialect === 'sqlite') {
    console.log('Running auto-migrations for SQLite...');
    const addColumnIfMissingSqlite = async (tableName, columnName, columnDefinition) => {
      try {
        const [results] = await sequelizeInstance.query(`PRAGMA table_info(${tableName});`);
        const exists = results.some(col => col.name === columnName);
        if (!exists) {
          console.log(`Adding missing column ${columnName} to table ${tableName} (SQLite)...`);
          await sequelizeInstance.query(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnDefinition}`);
        }
      } catch (err) {
        console.error(`Error migrating SQLite ${tableName}.${columnName}:`, err.message);
      }
    };
    
    await addColumnIfMissingSqlite('leads', 'company_name', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'contact_person', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'city', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'state', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'country', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'gst_number', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'pan', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'industry', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'attachments', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'converted', "TEXT DEFAULT 'No'");
    await addColumnIfMissingSqlite('leads', 'converted_date', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'converted_by', 'INTEGER');
    await addColumnIfMissingSqlite('leads', 'client_id', 'TEXT');

    await addColumnIfMissingSqlite('clients', 'client_id', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'company_name', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'contact_person', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'city', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'state', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'country', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'gst_number', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'pan', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'lead_source', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'industry', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'notes', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'attachments', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'assigned_to', 'INTEGER');
    await addColumnIfMissingSqlite('clients', 'lead_id', 'INTEGER');

    // Soft-delete / is_archived migrations SQLite
    await addColumnIfMissingSqlite('leads', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('leads', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('clients', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('clients', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('projects', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('projects', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('projects', 'is_archived', 'INTEGER DEFAULT 0');
    await addColumnIfMissingSqlite('tasks', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('tasks', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('workers', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('workers', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('daily_reports', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('daily_reports', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('announcements', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('announcements', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('quotations', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('quotations', 'deleted_by', 'INTEGER');
    await addColumnIfMissingSqlite('invoices', 'deleted_at', 'TEXT');
    await addColumnIfMissingSqlite('invoices', 'deleted_by', 'INTEGER');
  }
}

async function startServer() {
  try {
    // 1. Connect and Fallback logic
    const sequelizeInstance = await connectDB();
    
    // 2. Initialize Models
    const models = initModels();

    // Run auto-migrations for missing columns before synchronizing tables
    await runMigrations(sequelizeInstance);
    
    // 3. Sync Models
    const shouldSeed = process.argv.includes('--seed') || process.env.SEED_DEMO === 'true';
    if (shouldSeed) {
      console.log('Force syncing database tables for seeding demo data...');
      await sequelizeInstance.sync({ force: true });
    } else {
      // Drop empty contractors table so it recreates with the new contractorId column in SQLite
      try {
        const [results] = await sequelizeInstance.query("SELECT count(*) as count FROM sqlite_master WHERE type='table' AND name='contractors';");
        if (results && results[0] && results[0].count > 0) {
          const [countRes] = await sequelizeInstance.query("SELECT COUNT(*) as count FROM contractors;");
          if (countRes && countRes[0] && countRes[0].count === 0) {
            console.log('Contractors table is empty. Dropping to recreate with new schema...');
            await sequelizeInstance.query("DROP TABLE IF EXISTS contractors;");
          }
        }
      } catch (e) {
        console.warn('Could not drop/check contractors table, proceeding with sync:', e.message);
      }
      await sequelizeInstance.sync({ force: false });
    }
    console.log('Database tables verified and synchronized.');
    
    // 4. Seed Default Roles and Accounts
    await seedDatabase(models, shouldSeed);

    // 4b. Seed Contractor specific data if empty
    await seedContractorData(models);

    // 5. Register Routes
    registerRoutes(app, models);

    // Global 404 API handler
    app.use('/api', (req, res) => {
      res.status(404).json({
        success: false,
        message: `API Route Not Found: ${req.method} ${req.originalUrl}`
      });
    });

    // Global 500 error handler
    app.use((err, req, res, next) => {
      console.error('Unhandled server error:', err);
      res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error'
      });
    });

    // 5. Register Health Checks
    app.get('/', async (req, res) => {
      let dbStatus = 'disconnected';
      try {
        await sequelizeInstance.authenticate();
        dbStatus = 'connected';
      } catch (e) {
        dbStatus = 'disconnected';
      }
      res.json({
        status: "online",
        version: "1.0",
        database: dbStatus
      });
    });

    app.get('/api/health', async (req, res) => {
      let dbStatus = 'disconnected';
      try {
        await sequelizeInstance.authenticate();
        dbStatus = 'connected';
      } catch (e) {
        dbStatus = 'disconnected';
      }
      res.json({
        status: true,
        server: "running",
        database: dbStatus,
        timestamp: new Date().toISOString()
      });
    });

    // Serve static frontend assets if built
    const webBuildPath = path.join(__dirname, '../apps/flutter_web/build/web');
    if (fs.existsSync(webBuildPath)) {
      console.log(`Hosting static frontend assets from: ${webBuildPath}`);
      app.use(express.static(webBuildPath));
      // Fallback route for SPA client routing
      app.get('*', (req, res, next) => {
        if (req.path.startsWith('/api')) {
          return next();
        }
        res.sendFile(path.join(webBuildPath, 'index.html'));
      });
    }

    // 6. Listen
    app.listen(PORT, () => {
      console.log(`Server is running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Fatal error during server startup:', error);
    process.exit(1);
  }
}

async function seedDatabase(models, force = false) {
  const {
    User, CompanySettings, Client, Project, Lead, Worker,
    ManagerAttendance, Attendance, DailyReport, ProgressReport,
    Announcement, Task, SiteVisit, Drawing, Document,
    Quotation, Invoice, Expense, Notification, LeadTimeline,
    AnnualTarget, MonthlyTarget, TeamTarget, EmployeeTarget
  } = models;
  
  try {
    const userCount = await User.count();
    if (userCount > 0 && !force) {
      console.log('Database already has users. Skipping seeding.');
      return;
    }

    console.log('Seeding rich, comprehensive system & demo data...');

    // Create Company Settings
    await CompanySettings.create({
      id: 1,
      companyName: 'VIAN Architects & Interior Designers',
      address: 'Plot 42, Galleria Commercial Complex, Phase V, Sector 43, Gurugram, India',
      gst: '07AAAAA1111A1Z1',
      email: 'office@vianarchitects.com',
      phone: '+91 124 4567890'
    });

    const defaultUsers = [
      // Managing Directors
      { employeeId: 'VIAN-MD-01', username: 'anand', rawPass: 'anand123', name: 'Ar. Anand Sathiesivam', email: 'anand@vianarchitects.com', role: 'Managing Director', dept: 'Executive', desig: 'Managing Director' },
      { employeeId: 'VIAN-MD-02', username: 'vijay', rawPass: 'vijay123', name: 'Ar. Vijay Vinthan', email: 'vijay@vianarchitects.com', role: 'Managing Director', dept: 'Executive', desig: 'Managing Director' },
      
      // Admin / Office Manager / Accounts
      { employeeId: 'VIAN-ADM-01', username: 'jaya', rawPass: 'jaya123', name: 'Jaya Sharma', email: 'jaya@vianarchitects.com', role: 'Admin / Office Manager / Accounts', dept: 'Front Office', desig: 'Office Manager' },

      // Tech Head + Senior Architect
      { employeeId: 'VIAN-TECH-01', username: 'muthuiya', rawPass: 'muthuiya123', name: 'Ar. Muthuiya', email: 'muthuiya@vianarchitects.com', role: 'Tech Head + Senior Architect', dept: 'Core Team', desig: 'Tech Head' },

      // Core Team
      { employeeId: 'VIAN-CORE-01', username: 'arun', rawPass: 'arun123', name: 'Er. Arun Mohan', email: 'arun@vianarchitects.com', role: 'Structural Engineer', dept: 'Core Team', desig: 'Structural Engineer' },
      { employeeId: 'VIAN-CORE-02', username: 'jahan', rawPass: 'jahan123', name: 'Er. Jahan Prabhu', email: 'jahan@vianarchitects.com', role: 'Engineering Precision Head', dept: 'Core Team', desig: 'Engineering Precision Head' },
      { employeeId: 'VIAN-CORE-03', username: 'mithulya', rawPass: 'mithulya123', name: 'Ar. Mithulya', email: 'mithulya@vianarchitects.com', role: 'Senior Design Engineer', dept: 'Core Team', desig: 'Senior Design Engineer' },
      { employeeId: 'VIAN-CORE-04', username: 'sasmitha', rawPass: 'sasmitha123', name: 'Ar. Sasmitha', email: 'sasmitha@vianarchitects.com', role: 'Planning Engineer', dept: 'Core Team', desig: 'Planning Engineer' },
      
      // Designing Team
      { employeeId: 'VIAN-DES-01', username: 'gokul_k', rawPass: 'gokulk123', name: 'Ar. Gokul Krishnan', email: 'gokulk@vianarchitects.com', role: 'Design Engineer', dept: 'Designing Team', desig: 'Design Engineer' },
      { employeeId: 'VIAN-DES-08', username: 'gokul', rawPass: 'gokul123', name: 'Ar. Gokul Krishnan', email: 'gokul@vianarchitects.com', role: 'Employee', dept: 'Designing Team', desig: 'Design Engineer' },
      { employeeId: 'VIAN-DES-02', username: 'sivaraman', rawPass: 'sivaraman123', name: 'Sr. Sivaraman', email: 'sivaraman@vianarchitects.com', role: 'Employee', dept: 'Designing Team', desig: '3D Visualization Specialist' },
      { employeeId: 'VIAN-DES-03', username: 'sabith', rawPass: 'sabith123', name: 'Ar. Sabith', email: 'sabith@vianarchitects.com', role: 'Creative Planning Engineer', dept: 'Designing Team', desig: 'Creative Planning Engineer' },
      { employeeId: 'VIAN-DES-04', username: 'edwin', rawPass: 'edwin123', name: 'Ar. Edwin', email: 'edwin@vianarchitects.com', role: 'Creative Design Engineer', dept: 'Designing Team', desig: 'Creative Design Engineer' },
      { employeeId: 'VIAN-DES-05', username: 'nivetha', rawPass: 'nivetha123', name: 'Ar. Nivetha', email: 'nivetha@vianarchitects.com', role: 'Interior Planning Engineer', dept: 'Designing Team', desig: 'Interior Planning Engineer' },
      { employeeId: 'VIAN-DES-06', username: 'gokul_e', rawPass: 'gokule123', name: 'Er. Gokul', email: 'gokule@vianarchitects.com', role: 'Technical Design Engineer', dept: 'Designing Team', desig: 'Technical Design Engineer' },
      { employeeId: 'VIAN-DES-07', username: 'abinaya', rawPass: 'abinaya123', name: 'Ar. Abinaya Bala', email: 'abinaya@vianarchitects.com', role: 'Architectural Designer', dept: 'Designing Team', desig: 'Architectural Designer' },
      
      // Site Team
      { employeeId: 'VIAN-SITE-01', username: 'anthony', rawPass: 'anthony123', name: 'Er. Anthony Richard', email: 'anthony@vianarchitects.com', role: 'Site Engineer', dept: 'Site Team', desig: 'Site Engineer' },
      { employeeId: 'VIAN-SITE-02', username: 'praveen', rawPass: 'praveen123', name: 'Er. Praveen Kumar', email: 'praveen@vianarchitects.com', role: 'Site Coordinator', dept: 'Site Team', desig: 'Site Coordinator' },
      { employeeId: 'VIAN-SITE-03', username: 'mohan', rawPass: 'mohan123', name: 'Er. Mohan', email: 'mohan@vianarchitects.com', role: 'Employee', dept: 'Site Team', desig: 'Site Construction Engineer' },
      { employeeId: 'VIAN-SITE-04', username: 'murugan', rawPass: 'murugan123', name: 'Sr. Murugan', email: 'murugan@vianarchitects.com', role: 'Site Manager', dept: 'Site Team', desig: 'Labour Manager' },
      { employeeId: 'VIAN-SITE-05', username: 'manoj', rawPass: 'manoj123', name: 'Sr. Manoj', email: 'manoj@vianarchitects.com', role: 'Employee', dept: 'Site Team', desig: 'Site Supervisor' },
      { employeeId: 'VIAN-SITE-06', username: 'dharmaraj', rawPass: 'dharmaraj123', name: 'Mr. Dharmaraj', email: 'dharmaraj@vianarchitects.com', role: 'Site Coordinator', dept: 'Site Team', desig: 'Site Coordinator' },
      { employeeId: 'VIAN-SITE-07', username: 'kishore', rawPass: 'kishore123', name: 'Ar. Kishore Kumar', email: 'kishore@vianarchitects.com', role: 'Junior Architect', dept: 'Site Team', desig: 'Junior Architect' },
      { employeeId: 'VIAN-SITE-08', username: 'surya', rawPass: 'surya123', name: 'Ar. Surya Prakash', email: 'surya@vianarchitects.com', role: 'Junior Architect', dept: 'Site Team', desig: 'Junior Architect' },
      { employeeId: 'VIAN-SITE-09', username: 'harshini', rawPass: 'harshini123', name: 'Ar. Harshini', email: 'harshini@vianarchitects.com', role: 'Junior Architect', dept: 'Site Team', desig: 'Junior Architect' },
      { employeeId: 'VIAN-SITE-10', username: 'vijayan', rawPass: 'vijayan123', name: 'Er. Vijayan', email: 'vijayan@vianarchitects.com', role: 'Employee', dept: 'Site Team', desig: 'Site Coordinator' },
      
      // Client, Accountant & Receptionist
      { employeeId: 'VIAN-CLT-01', username: 'client', rawPass: 'client123', name: 'Amit Bajaj', email: 'amit.bajaj@example.com', role: 'Client', dept: 'External', desig: 'Property Owner' },
      { employeeId: 'VIAN-ACC-01', username: 'accountant', rawPass: 'accountant123', name: 'Sneha Jain', email: 'sneha@vianarchitects.com', role: 'Accountant', dept: 'Finance', desig: 'Finance Head' },
      { employeeId: 'VIAN-REC-01', username: 'receptionist', rawPass: 'receptionist123', name: 'Priya Sharma', email: 'priya@vianarchitects.com', role: 'Receptionist', dept: 'Front Office', desig: 'CRM Executive' }
    ];

    const userInstances = {};
    for (const u of defaultUsers) {
      const salt = await bcrypt.genSalt(10);
      const hash = await bcrypt.hash(u.rawPass, salt);
      
      const createdUser = await User.create({
        employeeId: u.employeeId,
        username: u.username,
        passwordHash: hash,
        name: u.name,
        email: u.email,
        role: u.role,
        department: u.dept,
        designation: u.desig,
        joiningDate: new Date().toISOString().split('T')[0],
        status: 'Active'
      });
      userInstances[u.username] = createdUser;
    }

    // 1. Seed Clients
    const client1 = await Client.create({
      userId: userInstances['client'].id,
      name: 'Amit Bajaj',
      phone: '+91 98765 43210',
      email: 'amit.bajaj@example.com',
      address: 'Villa 108, Palm Meadows, Bangalore',
      gst: '29BBBBB2222B1Z2',
      propertyDetails: 'Luxury 4BHK Villa Construction and Interior Work'
    });

    const client2 = await Client.create({
      name: 'Kiran Oberoi',
      phone: '+91 99112 23344',
      email: 'kiran@oberoigroup.com',
      address: 'DLF phase II, Gurugram',
      gst: '07CCCCC3333C1Z3',
      propertyDetails: 'Commercial Corporate Office (3 Floors, Interior & Shell)'
    });

    // 2. Seed Projects
    const project1 = await Project.create({
      projectId: 'VIAN-PROJ-2026-001',
      name: 'The Bajaj Villa',
      type: 'Villa',
      clientId: client1.id,
      architectId: userInstances['mithulya'].id,
      siteEngineerId: userInstances['anthony'].id,
      budget: 25000000.00,
      startDate: '2026-01-10',
      completionDate: '2026-12-15',
      status: 'In Progress',
      progressPercentage: 45
    });

    const project2 = await Project.create({
      projectId: 'VIAN-PROJ-2026-002',
      name: 'Oberoi Office Complex',
      type: 'Commercial',
      clientId: client2.id,
      architectId: userInstances['sasmitha'].id,
      siteEngineerId: userInstances['mohan'].id,
      budget: 58000000.00,
      startDate: '2026-05-01',
      completionDate: '2027-04-30',
      status: 'Planning',
      progressPercentage: 10
    });

    const project3 = await Project.create({
      projectId: 'VIAN-PROJ-2025-001',
      name: 'Horizon Villa ECR',
      type: 'Villa',
      clientId: client1.id,
      architectId: userInstances['mithulya'].id,
      siteEngineerId: userInstances['anthony'].id,
      budget: 9800000.00,
      startDate: '2025-01-10',
      completionDate: '2025-10-15',
      status: 'Completed',
      progressPercentage: 100,
      actualMaterialCost: 4800000.00,
      actualLabourCost: 3200000.00,
      actualTimelineMonths: 9,
      actualPurchaseCost: 8000000.00,
      actualProfit: 1800000.00
    });

    // 3. Seed Workers
    const workers = [
      { workerId: 'WRK-001', name: 'Ramesh Kumar', skillType: 'Mason', dailyWage: 600.00, contractor: 'Verma Contractors', projectId: project1.id },
      { workerId: 'WRK-002', name: 'Sohan Lal', skillType: 'Carpenter', dailyWage: 750.00, contractor: 'Verma Contractors', projectId: project1.id },
      { workerId: 'WRK-003', name: 'Madan Mohan', skillType: 'Painter', dailyWage: 550.00, contractor: 'Singh Painters', projectId: project1.id },
      { workerId: 'WRK-004', name: 'Hari Prasad', skillType: 'Electrician', dailyWage: 700.00, contractor: 'Self', projectId: project2.id },
      { workerId: 'WRK-005', name: 'Vikram Sharma', skillType: 'Plumber', dailyWage: 650.00, contractor: 'Self', projectId: project2.id }
    ];

    const workerInstances = [];
    for (const w of workers) {
      const createdWorker = await Worker.create(w);
      workerInstances.push(createdWorker);
    }

    // 4. Seed Manager Attendance (past 15 days logs for workers)
    console.log('Generating manager attendance logs for workers...');
    const todayDate = new Date();
    const markEntryTime = '18:00:00';
    const gpsLocation = '28.4595° N, 77.0266° E';
    
    for (let i = 15; i >= 1; i--) {
      const d = new Date();
      d.setDate(todayDate.getDate() - i);
      const dateString = d.toISOString().split('T')[0];
      
      // Skip Sundays
      if (d.getDay() === 0) continue;

      for (const w of workerInstances) {
        // Random attendance: 80% Present, 10% Half Day, 10% Absent
        const rand = Math.random();
        let status = 'Present';
        let overtimeHours = 0.0;
        let remarks = 'Completed standard shifts';

        if (rand < 0.1) {
          status = 'Absent';
          remarks = 'Sick leave / Informed';
        } else if (rand < 0.2) {
          status = 'Half Day';
          remarks = 'Personal work in second half';
        } else {
          // Present: occasional overtime
          if (Math.random() < 0.3) {
            overtimeHours = Math.random() < 0.5 ? 2.0 : 4.0;
            remarks = `Completed overtime for ${overtimeHours} hours`;
          }
        }

        await ManagerAttendance.create({
          workerId: w.id,
          date: dateString,
          status: status,
          overtimeHours: overtimeHours,
          remarks: remarks,
          managerId: userInstances['anthony'].id,
          entryTime: markEntryTime,
          gpsLocation: gpsLocation
        });
      }
    }

    // 5. Seed Employee Self Attendance (past 5 days check-ins)
    console.log('Generating employee attendance logs...');
    for (let i = 5; i >= 0; i--) {
      const d = new Date();
      d.setDate(todayDate.getDate() - i);
      const dateString = d.toISOString().split('T')[0];
      if (d.getDay() === 0) continue;

      const rolesToCheckIn = ['anand', 'vijay', 'jaya', 'muthuiya', 'arun', 'jahan', 'mithulya', 'sasmitha', 'gokul', 'sivaraman', 'mohan', 'vijayan', 'manoj', 'murugan', 'accountant'];
      for (const role of rolesToCheckIn) {
        if (!userInstances[role]) continue;
        await Attendance.create({
          userId: userInstances[role].id,
          date: dateString,
          checkInTime: '09:12:00',
          checkInGps: gpsLocation,
          checkInSelfieUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150',
          checkOutTime: '18:30:00',
          checkOutGps: gpsLocation,
          workingHours: 9.3,
          status: 'Present'
        });
      }
    }

    // 6. Seed CRM Leads & timelines
    const lead1 = await Lead.create({
      name: 'Rajesh Malhotra',
      phone: '+91 99887 76655',
      email: 'rajesh@malhotragroup.in',
      source: 'Website Inquiry',
      budget: 50000000.00,
      requirement: 'Full interior design and renovation of 5000 sqft penthouse in DLF Magnolias',
      notes: 'Client looking for ultra-luxury contemporary style. Wants to start by August 2026.',
      status: 'New',
      assignedTo: userInstances['receptionist'].id
    });

    await LeadTimeline.create({
      leadId: lead1.id,
      action: 'Lead Created',
      notes: 'Lead added from website contact form submission.',
      createdBy: userInstances['receptionist'].id
    });

    const lead2 = await Lead.create({
      name: 'Dr. Shruti Kapoor',
      phone: '+91 98989 87878',
      email: 'shruti.k@healthclinic.org',
      source: 'Instagram Reference',
      budget: 15000000.00,
      requirement: 'Design of dental clinic, minimal clean aesthetics with warm lighting',
      notes: 'Scheduled site visit for next Monday. Sent initial portfolio link.',
      status: 'Contacted',
      assignedTo: userInstances['receptionist'].id
    });

    await LeadTimeline.create({
      leadId: lead2.id,
      action: 'Lead Created',
      notes: 'Lead created by CRM receptionist.',
      createdBy: userInstances['receptionist'].id
    });
    await LeadTimeline.create({
      leadId: lead2.id,
      action: 'Contacted Client',
      notes: 'Shared premium dental clinic portfolio files via WhatsApp. Scheduled visit.',
      createdBy: userInstances['receptionist'].id
    });

    // 7. Seed Tasks
    const tasks = [
      { title: 'Structural Foundation Audit', description: 'Perform ultrasound testing on concrete pillars in basement structure.', projectId: project1.id, priority: 'Critical', assignedTo: userInstances['anthony'].id, dueDate: '2026-06-20', status: 'Completed' },
      { title: 'Plumbing Blueprint Layout', description: 'Re-align pipe drainage outlets for the master bathroom on level 2.', projectId: project1.id, priority: 'High', assignedTo: userInstances['mithulya'].id, dueDate: '2026-06-28', status: 'Review' },
      { title: 'Mood Board Approval', description: 'Get approvals from client regarding marble textures for lobby walls.', projectId: project1.id, priority: 'Medium', assignedTo: userInstances['edwin'].id, dueDate: '2026-06-15', status: 'Completed' },
      { title: 'Boundary Wall Masonry', description: 'Complete brickwork section C near rear gardens.', projectId: project1.id, priority: 'Low', assignedTo: userInstances['anthony'].id, dueDate: '2026-07-05', status: 'In Progress' },
      { title: 'HVAC Duct Layout Approval', description: 'Approve centralized air conditioning duct schematic drawings.', projectId: project2.id, priority: 'Critical', assignedTo: userInstances['mithulya'].id, dueDate: '2026-07-01', status: 'Pending' },
      { title: 'Site Safety Clearance Certificate', description: 'Inspect site harness, helmets, safety netting installations for shell work.', projectId: project2.id, priority: 'High', assignedTo: userInstances['anthony'].id, dueDate: '2026-06-25', status: 'In Progress' }
    ];

    for (const t of tasks) {
      await Task.create(t);
    }

    // 8. Seed Site Visits
    await SiteVisit.create({
      projectId: project1.id,
      userId: userInstances['anthony'].id,
      date: '2026-06-21',
      gpsLocation: gpsLocation,
      notes: 'Ground floor column casting completed. Verified concrete mixes on-site. Column templates aligned.',
      photoUrls: JSON.stringify(['https://images.unsplash.com/photo-1541888946425-d81bb19240f5?q=80&w=400']),
      voiceNoteUrl: 'http://localhost:5050/uploads/audio/visit-1.mp3'
    });

    await SiteVisit.create({
      projectId: project1.id,
      userId: userInstances['mithulya'].id,
      date: '2026-06-19',
      gpsLocation: gpsLocation,
      notes: 'Inspected partition layouts in lobby. Height levels are correct. Ceiling drawings approved.',
      photoUrls: JSON.stringify(['https://images.unsplash.com/photo-1503387762-592dedbd82d3?q=80&w=400'])
    });

    // 9. Seed Drawings
    await Drawing.create({
      projectId: project1.id,
      title: 'Ground Floor Architecture Blueprint',
      version: '1.2',
      type: 'Floor Plans',
      fileUrl: 'http://localhost:5050/uploads/drawings/floor-plan-1.2.pdf',
      approvedBy: userInstances['mithulya'].id,
      status: 'Approved'
    });

    await Drawing.create({
      projectId: project1.id,
      title: 'Lobby False Ceiling Lighting Detail',
      version: '1.0',
      type: 'Interior Drawings',
      fileUrl: 'http://localhost:5050/uploads/drawings/ceiling-lighting-1.0.pdf',
      status: 'Pending'
    });

    // 10. Seed Documents
    await Document.create({
      projectId: project1.id,
      title: 'Villa Foundation Structural Stability Report',
      folder: 'Structure Reports',
      fileUrl: 'http://localhost:5050/uploads/docs/stability-report.pdf',
      fileSize: 2450000
    });

    await Document.create({
      projectId: project1.id,
      title: 'GST Business Registration Receipt',
      folder: 'Finance',
      fileUrl: 'http://localhost:5050/uploads/docs/gst-receipt.pdf',
      fileSize: 1040000
    });

    // 11. Seed Quotations
    await Quotation.create({
      projectId: project1.id,
      quotationNumber: 'VIAN-QT-2026-001',
      date: '2026-01-05',
      taxRate: 18.00,
      discount: 200000.00,
      subtotal: 21200000.00,
      total: 25016000.00,
      status: 'Approved',
      items: JSON.stringify([
        { description: 'Foundation & RCC structural works complete', quantity: 1, rate: 12000000, amount: 12000000 },
        { description: 'Brickwork, partitioning & plastering', quantity: 1, rate: 4200000, amount: 4200000 },
        { description: 'Electrical piping & standard wiring runs', quantity: 1, rate: 2500000, amount: 2500000 },
        { description: 'Sanitary fittings & modular plumbing lines', quantity: 1, rate: 2500000, amount: 2500000 }
      ])
    });

    // 12. Seed Invoices
    await Invoice.create({
      projectId: project1.id,
      invoiceNumber: 'VIAN-INV-2026-001',
      date: '2026-01-15',
      dueDate: '2026-02-15',
      taxRate: 18.00,
      discount: 0.00,
      subtotal: 7500000.00,
      total: 8850000.00,
      paidAmount: 8850000.00,
      status: 'Paid',
      items: JSON.stringify([
        { description: 'Advance payment for project mobilization & steel/cement purchase', quantity: 1, rate: 7500000, amount: 7500000 }
      ])
    });

    await Invoice.create({
      projectId: project1.id,
      invoiceNumber: 'VIAN-INV-2026-002',
      date: '2026-06-10',
      dueDate: '2026-07-10',
      taxRate: 18.00,
      discount: 0.00,
      subtotal: 5000000.00,
      total: 5900000.00,
      paidAmount: 0.00,
      status: 'Sent',
      items: JSON.stringify([
        { description: 'Second stage completion invoice - Structural pillars & lintel beam levels', quantity: 1, rate: 5000000, amount: 5000000 }
      ])
    });

    // 13. Seed Expenses
    await Expense.create({
      projectId: project1.id,
      userId: userInstances['anthony'].id,
      amount: 450000.00,
      category: 'Material Expenses',
      description: 'Cement procurement - 800 bags from Ultratech Cement',
      receiptUrl: 'http://localhost:5050/uploads/receipts/exp-1.jpg',
      date: '2026-06-12',
      status: 'Approved'
    });

    await Expense.create({
      projectId: project1.id,
      userId: userInstances['anthony'].id,
      amount: 120000.00,
      category: 'Labour Expenses',
      description: 'Weekly contractor payout for site bricklayers and helper workers',
      receiptUrl: 'http://localhost:5050/uploads/receipts/exp-2.jpg',
      date: '2026-06-18',
      status: 'Approved'
    });

    await Expense.create({
      projectId: project1.id,
      userId: userInstances['anthony'].id,
      amount: 35000.00,
      category: 'Travel Expenses',
      description: 'Fuel logs and site engineer out-station travel allowance',
      receiptUrl: 'http://localhost:5050/uploads/receipts/exp-3.jpg',
      date: '2026-06-20',
      status: 'Pending'
    });

    // 14. Seed Daily Reports
    await DailyReport.create({
      projectId: project1.id,
      userId: userInstances['anthony'].id,
      date: '2026-06-22',
      workCategory: 'Brick Work',
      workDescription: 'Completed brick laying for boundary wall section B near pool site.',
      quantityCompleted: '1200 Sq Ft Completed',
      notes: 'All items completed, verified structural offsets.'
    });

    await DailyReport.create({
      projectId: project1.id,
      userId: userInstances['edwin'].id,
      date: '2026-06-22',
      workCategory: 'Painting Layouts',
      workDescription: 'Completed first coat primer check on level 1 partition walls.',
      quantityCompleted: '3 Partition Sections Checked',
      notes: 'Recommended second coat starting Thursday.'
    });

    // 15. Seed Progress Reports
    await ProgressReport.create({
      projectId: project1.id,
      managerId: userInstances['anthony'].id,
      date: '2026-06-22',
      workersPresent: 12,
      workCompleted: 'Slab casting of second floor completed. Shuttering structural bounds verified.',
      materialsUsed: 'Cement: 150 Bags, Steel Rebars: 1.2 Tons, Sand: 2 Trucks',
      issuesFaced: 'Minor water pressure leakage in basement, pipe repaired.',
      delays: 'No major delay',
      tomorrowPlan: 'Curing of slabs, start scaffolding setup for brick partitioning.',
      voiceNoteUrl: 'http://localhost:5050/uploads/audio/progress-eod.mp3'
    });

    // 16. Seed Announcements
    await Announcement.create({
      title: 'Safety Guidelines Compliance',
      message: 'All site engineers and supervisors must ensure that workers wear safety helmets and harnesses on scaffolding sections at all times.',
      createdBy: userInstances['anand'].id,
      targetRole: 'All'
    });

    await Announcement.create({
      title: 'GST Material Bill Collection Deadline',
      message: 'Accountants must compile all cement/steel procurement receipts for GST audits by the 25th of this month.',
      createdBy: userInstances['anand'].id,
      targetRole: 'Accountant'
    });

    // 17. Seed Notifications
    await Notification.create({
      userId: userInstances['anand'].id,
      title: 'New Task Review Request',
      message: 'Site Engineer Rahul Sen submitted "Structural Foundation Audit" for review.',
      readStatus: false,
      type: 'Task'
    });

    await Notification.create({
      userId: userInstances['anand'].id,
      title: 'Client Payment Success',
      message: 'Client Amit Bajaj cleared Invoice VIAN-INV-2026-001 (₹88,50,000).',
      readStatus: true,
      type: 'Billing'
    });

    // 18. Seed Targets
    const annualTarget = await AnnualTarget.create({
      financialYear: '2026-2027',
      annualProjectTarget: 120,
      annualRevenueTarget: 12000000.00,
      annualProfitTarget: 3600000.00,
      residentialProjectsTarget: 50,
      commercialProjectsTarget: 30,
      interiorProjectsTarget: 30,
      renovationProjectsTarget: 10,
      newClientTarget: 15,
      repeatClientTarget: 5,
      isApproved: true,
      approvedBy: userInstances['anand'].id
    });

    const months = [
      { name: 'April', num: 4 },
      { name: 'May', num: 5 },
      { name: 'June', num: 6 },
      { name: 'July', num: 7 },
      { name: 'August', num: 8 },
      { name: 'September', num: 9 },
      { name: 'October', num: 10 },
      { name: 'November', num: 11 },
      { name: 'December', num: 12 },
      { name: 'January', num: 1 },
      { name: 'February', num: 2 },
      { name: 'March', num: 3 }
    ];

    for (const m of months) {
      await MonthlyTarget.create({
        annualTargetId: annualTarget.id,
        monthName: m.name,
        monthNumber: m.num,
        projectTarget: Math.round(120 / 12),
        revenueTarget: 12000000.00 / 12,
        profitTarget: 3600000.00 / 12,
        residentialProjectsTarget: Math.round(50 / 12),
        commercialProjectsTarget: Math.round(30 / 12),
        interiorProjectsTarget: Math.round(30 / 12),
        renovationProjectsTarget: Math.round(10 / 12),
        newClientTarget: Math.round(15 / 12),
        repeatClientTarget: Math.round(5 / 12)
      });
    }

    await TeamTarget.create({
      financialYear: '2026-2027',
      teamName: 'Design Team',
      targetMetric: 'Drawing Completion',
      targetValue: 100,
      unit: 'number'
    });

    await EmployeeTarget.create({
      employeeId: userInstances['gokul_k'].id,
      assignedBy: userInstances['anand'].id,
      targetDescription: 'Complete 8 drawings this month',
      targetMetric: 'drawings',
      targetValue: 8,
      currentValue: 5,
      period: 'Monthly',
      startDate: '2026-06-01',
      endDate: '2026-06-30',
      status: 'In Progress'
    });

    console.log('Seeding database complete.');
  } catch (error) {
    console.error('Error seeding database:', error);
  }
}
async function seedContractorData(models) {
  const { Contractor, ContractorPaymentStage, ContractorPaymentRelease, Project } = models;
  try {
    const stageCount = await ContractorPaymentStage.count();
    if (stageCount === 0) {
      console.log('Seeding default contractor payment stages...');
      await ContractorPaymentStage.bulkCreate([
        { name: 'BASEMENT', description: 'Foundation and Basement column works' },
        { name: 'SOIL FILLING', description: 'Excavation and Soil backfilling works' },
        { name: 'RCC SLAB', description: 'Reinforced concrete slab casting works' },
        { name: 'PLASTERING', description: 'Internal and external wall plastering' },
        { name: 'TILING', description: 'Flooring and wall tiling works' },
        { name: 'PAINTING', description: 'Wall painting and polishing' }
      ]);
    }

    const contractorCount = await Contractor.count();
    let contractorInstances = [];
    if (contractorCount === 0) {
      console.log('Seeding default contractors...');
      contractorInstances = await Contractor.bulkCreate([
        { contractorId: 'CON-001', name: 'Verma Contractors', phone: '9876543210', email: 'verma@example.com', address: 'Gurugram, Sector 43', serviceType: 'Civil & Foundation' },
        { contractorId: 'CON-002', name: 'Singh Painters', phone: '9876543211', email: 'singh@example.com', address: 'Delhi, Vasant Kunj', serviceType: 'Painting & Polishing' },
        { contractorId: 'CON-003', name: 'Sharma Electricals', phone: '9876543212', email: 'sharma@example.com', address: 'Noida, Sector 62', serviceType: 'Electrical & Wiring' }
      ]);
    } else {
      contractorInstances = await Contractor.findAll();
    }

    const releaseCount = await ContractorPaymentRelease.count();
    if (releaseCount === 0 && contractorInstances.length > 0) {
      const project = await Project.findOne();
      const stage = await ContractorPaymentStage.findOne({ where: { name: 'BASEMENT' } });
      if (project && stage) {
        console.log('Seeding default contractor payment releases...');
        await ContractorPaymentRelease.create({
          contractorId: contractorInstances[0].id,
          projectId: project.id,
          stageId: stage.id,
          amount: 150000.00,
          releaseDate: '2026-06-15',
          paymentMode: 'Bank Transfer',
          referenceNumber: 'TXN-99887766',
          status: 'Released',
          notes: 'Basement column casting completed. Quality team approved.'
        });
      }
    }
  } catch (error) {
    console.error('Error seeding contractor data:', error);
  }
}

startServer();

