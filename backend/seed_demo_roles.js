const bcrypt = require('bcryptjs');
const { initModels } = require('./database/models');
const { connectDB, getSequelize } = require('./database/db');
const { Op } = require('sequelize');

const demoUsers = [
  // Core Executive Logins
  {
    employeeId: 'VIAN-MD-01',
    username: 'anand',
    email: 'anand@vianarchitects.com',
    name: 'Ar. Anand Sathiesivam',
    role: 'Managing Director',
    department: 'Executive',
    designation: 'Managing Director',
    password: 'anand123'
  },
  {
    employeeId: 'VIAN-MD-02',
    username: 'vijay',
    email: 'vijay@vianarchitects.com',
    name: 'Ar. Vijay Vinthan',
    role: 'Managing Director',
    department: 'Executive',
    designation: 'Managing Director',
    password: 'vijay123'
  },
  {
    employeeId: 'VIAN-CLT-01',
    username: 'client',
    email: 'client@example.com',
    name: 'Amit Bajaj',
    role: 'Client',
    department: 'External',
    designation: 'Property Owner',
    password: 'client123'
  },

  // Role Showcase Demo Accounts
  {
    employeeId: 'DEMO-SA-01',
    username: 'demo_superadmin',
    email: 'superadmin@vianarchitects.com',
    name: 'Demo Super Admin',
    role: 'Super Admin',
    department: 'Administration',
    designation: 'Super Administrator'
  },
  {
    employeeId: 'DEMO-MD-01',
    username: 'demo_md',
    email: 'md@vianarchitects.com',
    name: 'Soundhararajan Muthuvel',
    role: 'Managing Director',
    department: 'Executive',
    designation: 'Managing Director'
  },
  {
    employeeId: 'DEMO-ADM-01',
    username: 'demo_admin',
    email: 'admin@vianarchitects.com',
    name: 'Demo Admin',
    role: 'Admin / Office Manager / Accounts',
    department: 'Administration',
    designation: 'Office Manager'
  },
  {
    employeeId: 'DEMO-PM-01',
    username: 'demo_pm',
    email: 'pm@vianarchitects.com',
    name: 'Demo Project Manager',
    role: 'Project Manager',
    department: 'Project Management',
    designation: 'Senior Project Manager'
  },
  {
    employeeId: 'DEMO-ARC-01',
    username: 'demo_architect',
    email: 'architect@vianarchitects.com',
    name: 'Demo Architect',
    role: 'Architect',
    department: 'Design',
    designation: 'Lead Architect'
  },
  {
    employeeId: 'DEMO-SE-01',
    username: 'demo_siteengineer',
    email: 'siteengineer@vianarchitects.com',
    name: 'Demo Site Engineer',
    role: 'Site Engineer',
    department: 'Site Team',
    designation: 'Site Engineer'
  },
  {
    employeeId: 'DEMO-ACC-01',
    username: 'demo_accountant',
    email: 'accountant@vianarchitects.com',
    name: 'Demo Accountant',
    role: 'Accountant',
    department: 'Finance',
    designation: 'Accounts Manager'
  },
  {
    employeeId: 'DEMO-CLT-01',
    username: 'demo_client',
    email: 'client@vianarchitects.com',
    name: 'Demo Client',
    role: 'Client',
    department: 'External',
    designation: 'Property Owner'
  }
];

const DEMO_PASSWORD = 'Demo@12345';

async function seedDemoRoles() {
  const isProduction = process.env.NODE_ENV === 'production';
  const explicitlyEnabled = process.env.SEED_DEMO === 'true';

  const sequelize = await connectDB();
  await sequelize.sync({ force: false });
  const { User } = initModels();

  const userCount = await User.count();
  if (isProduction && !explicitlyEnabled && userCount > 0) {
    console.log(`Production environment detected with ${userCount} existing users: Skipping demo role seeding to protect production data.`);
    return;
  }

  const salt = await bcrypt.genSalt(10);
  const defaultPasswordHash = await bcrypt.hash(DEMO_PASSWORD, salt);

  console.log('Seeding Demo Role & Core Executive Accounts...');
  for (const u of demoUsers) {
    const rawPass = u.password || DEMO_PASSWORD;
    const passwordHash = u.password ? await bcrypt.hash(u.password, salt) : defaultPasswordHash;

    let userRecord = await User.findOne({
      where: {
        [Op.or]: [{ email: u.email }, { username: u.username }]
      }
    });

    if (userRecord) {
      // In development or when requested, update user details without destroying custom passwords
      const updateData = {
        employeeId: u.employeeId,
        name: u.name,
        role: u.role,
        department: u.department,
        designation: u.designation,
        status: 'Active'
      };
      // Only reset password if explicitly requested
      if (!isProduction && process.env.FORCE_RESET_DEMO_PASSWORDS === 'true') {
        updateData.passwordHash = passwordHash;
      }
      await userRecord.update(updateData);
      console.log(`Verified existing account: ${u.username} / ${u.email} (${u.role})`);
    } else {
      userRecord = await User.create({
        employeeId: u.employeeId,
        username: u.username,
        passwordHash,
        name: u.name,
        email: u.email,
        role: u.role,
        department: u.department,
        designation: u.designation,
        joiningDate: new Date().toISOString().split('T')[0],
        status: 'Active'
      });
      console.log(`Created new account: ${u.username} / ${u.email} (${u.role})`);
    }
  }

  console.log('Demo role & core accounts seeding completed successfully.');
}

if (require.main === module) {
  seedDemoRoles()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Error seeding demo roles:', err);
      process.exit(1);
    });
}

module.exports = { seedDemoRoles, demoUsers };
