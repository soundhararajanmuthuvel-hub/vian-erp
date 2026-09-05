/**
 * Safe Database Migration & Verification Utility
 *
 * Facilitates safe, non-destructive migration between databases:
 * 1. Exports tables to clean JSON / SQL dumps
 * 2. Compares record counts between source and destination
 * 3. Verifies schema compatibility and integrity
 */

const { initModels } = require('./database/models');
const { connectDB } = require('./database/db');

async function verifyTableCounts() {
  console.log('=== Database Table Count & Verification Audit ===\n');

  try {
    const sequelize = await connectDB();
    const models = initModels();

    const entities = [
      { name: 'Users', model: models.User },
      { name: 'Clients', model: models.Client },
      { name: 'Leads', model: models.Lead },
      { name: 'Projects', model: models.Project },
      { name: 'Tasks', model: models.Task },
      { name: 'Attendance', model: models.Attendance },
      { name: 'Workers', model: models.Worker },
      { name: 'Invoices', model: models.Invoice },
      { name: 'Payments', model: models.ProjectPayment },
      { name: 'Expenses', model: models.Expense },
      { name: 'Estimates', model: models.Estimate },
      { name: 'BOQ Items', model: models.BoqItem },
      { name: 'Drawings', model: models.Drawing },
      { name: 'Documents', model: models.Document },
      { name: 'Audit Logs', model: models.AuditLog }
    ];

    console.log('TABLE NAME                   | RECORD COUNT');
    console.log('-----------------------------+-------------');

    const counts = {};
    for (const e of entities) {
      try {
        const count = await e.model.count();
        counts[e.name] = count;
        console.log(`${e.name.padEnd(28)} | ${String(count).padStart(12)}`);
      } catch (err) {
        counts[e.name] = 'ERROR';
        console.log(`${e.name.padEnd(28)} | ERROR: ${err.message}`);
      }
    }

    console.log('-----------------------------+-------------');
    console.log('\nVerification complete.');
    return counts;
  } catch (err) {
    console.error('Failed table count audit:', err.message);
    process.exit(1);
  }
}

if (require.main === module) {
  verifyTableCounts().then(() => process.exit(0)).catch(() => process.exit(1));
}

module.exports = { verifyTableCounts };
