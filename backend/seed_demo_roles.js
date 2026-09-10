const bcrypt = require('bcryptjs');
const { initModels } = require('./database/models');
const { connectDB, getSequelize } = require('./database/db');
const { Op } = require('sequelize');

const demoUsers = [
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
  const sequelize = await connectDB();
  await sequelize.sync({ force: false });
  const { User } = initModels();

  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, salt);

  console.log('Seeding Demo Role Accounts...');
  for (const u of demoUsers) {
    let userRecord = await User.findOne({
      where: {
        [Op.or]: [{ email: u.email }, { username: u.username }]
      }
    });

    if (userRecord) {
      await userRecord.update({
        employeeId: u.employeeId,
        username: u.username,
        passwordHash,
        name: u.name,
        email: u.email,
        role: u.role,
        department: u.department,
        designation: u.designation,
        status: 'Active'
      });
      console.log(`Updated existing demo account: ${u.email} (${u.role})`);
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
      console.log(`Created new demo account: ${u.email} (${u.role})`);
    }
  }

  console.log('Demo role accounts seeding completed successfully.');
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
