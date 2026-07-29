const bcrypt = require('bcryptjs');
const { initModels } = require('./database/models');
const { connectDB, getSequelize } = require('./database/db');
const { Op } = require('sequelize');

const demoUsers = [
  {
    employeeId: 'VIAN-SA-01',
    username: 'superadmin',
    email: 'superadmin@vianarchitects.com',
    rawPass: 'superadmin123',
    name: 'Super Admin',
    role: 'Super Admin',
    department: 'Administration',
    designation: 'Super Administrator'
  },
  {
    employeeId: 'VIAN-MD-01',
    username: 'anand',
    email: 'anand@vianarchitects.com',
    rawPass: 'anand123',
    name: 'Ar. Anand Sathiesivam',
    role: 'Managing Director',
    department: 'Executive',
    designation: 'Managing Director'
  },
  {
    employeeId: 'VIAN-ADM-01',
    username: 'admin',
    email: 'admin@vianarchitects.com',
    rawPass: 'admin123',
    name: 'Office Admin',
    role: 'Admin / Office Manager / Accounts',
    department: 'Administration',
    designation: 'Office Manager'
  },
  {
    employeeId: 'VIAN-PM-01',
    username: 'pm',
    email: 'pm@vianarchitects.com',
    rawPass: 'pm123',
    name: 'Senior Project Manager',
    role: 'Project Manager',
    department: 'Project Management',
    designation: 'Senior Project Manager'
  },
  {
    employeeId: 'VIAN-ARC-01',
    username: 'architect',
    email: 'architect@vianarchitects.com',
    rawPass: 'architect123',
    name: 'Lead Architect',
    role: 'Architect',
    department: 'Design',
    designation: 'Lead Architect'
  },
  {
    employeeId: 'VIAN-SE-01',
    username: 'siteengineer',
    email: 'siteengineer@vianarchitects.com',
    rawPass: 'siteengineer123',
    name: 'Site Engineer',
    role: 'Site Engineer',
    department: 'Site Team',
    designation: 'Site Engineer'
  },
  {
    employeeId: 'VIAN-ACC-01',
    username: 'accountant',
    email: 'accountant@vianarchitects.com',
    rawPass: 'accountant123',
    name: 'Sneha Jain',
    role: 'Accountant',
    department: 'Finance',
    designation: 'Finance Head'
  },
  {
    employeeId: 'VIAN-CLT-01',
    username: 'client',
    email: 'client@vianarchitects.com',
    rawPass: 'client123',
    name: 'Amit Bajaj',
    role: 'Client',
    department: 'External',
    designation: 'Property Owner'
  }
];

async function seedDemoRoles() {
  const sequelize = await connectDB();
  await sequelize.sync();
  const { User } = initModels();

  console.log('Seeding Demo Role Accounts...');
  for (const u of demoUsers) {
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(u.rawPass, salt);

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
      console.log(`Updated existing demo account: ${u.username} / ${u.email} (${u.role})`);
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
      console.log(`Created new demo account: ${u.username} / ${u.email} (${u.role})`);
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
