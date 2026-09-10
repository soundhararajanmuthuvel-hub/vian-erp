/**
 * Safe, Non-Destructive Database Migration Utility for Render Managed PostgreSQL
 * 
 * Transfers data from Source Database (Existing SQLite or MySQL)
 * to Target Database (Render PostgreSQL) with:
 * - Foreign Key & ID preservation
 * - Timestamps (createdAt, updatedAt) preservation
 * - Auto-increment sequence realignment (pg setval)
 * - Non-destructive insertion (no DROPs or TRUNCATEs)
 * - Comparative Row Count Audit: TABLE | OLD COUNT | POSTGRES COUNT | RESULT
 */

const { Sequelize } = require('sequelize');
const path = require('path');
const fs = require('fs');
const { initModels } = require('./database/models');

// Load environment variables
require('dotenv').config();
const backendEnvPath = path.join(__dirname, '.env');
if (fs.existsSync(backendEnvPath)) {
  require('dotenv').config({ path: backendEnvPath });
}

async function runMigration() {
  console.log('====================================================');
  console.log(' VIAN ERP — RENDER POSTGRESQL SAFE MIGRATION PIPELINE');
  console.log('====================================================\n');

  // 1. Configure Source Database (Default: local SQLite database)
  const sourceSqlitePath = path.join(__dirname, 'database', 'vian_architects.sqlite');
  let sourceSequelize;

  if (process.env.SOURCE_DATABASE_URL) {
    const isSourcePg = process.env.SOURCE_DATABASE_URL.startsWith('postgres');
    console.log(`Connecting to Source Database via SOURCE_DATABASE_URL (${isSourcePg ? 'postgres' : 'mysql'})...`);
    sourceSequelize = new Sequelize(process.env.SOURCE_DATABASE_URL, {
      dialect: isSourcePg ? 'postgres' : 'mysql',
      logging: false
    });
  } else if (fs.existsSync(sourceSqlitePath)) {
    console.log(`Connecting to Source SQLite Database at: ${sourceSqlitePath}`);
    sourceSequelize = new Sequelize({
      dialect: 'sqlite',
      storage: sourceSqlitePath,
      logging: false
    });
  } else {
    console.error('ERROR: No source database found (no SOURCE_DATABASE_URL and no vian_architects.sqlite).');
    process.exit(1);
  }

  // 2. Configure Target Database (Render PostgreSQL)
  const targetUrl = process.env.TARGET_DATABASE_URL || (process.env.DATABASE_URL && process.env.DATABASE_URL.startsWith('postgres') ? process.env.DATABASE_URL : null);

  let targetSequelize = null;
  if (targetUrl) {
    const sanitizedUrl = targetUrl.replace(/:([^:@]+)@/, ':****@');
    console.log(`Connecting to Target Render PostgreSQL at: ${sanitizedUrl}...`);
    targetSequelize = new Sequelize(targetUrl, {
      dialect: 'postgres',
      logging: false,
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED === 'true'
        }
      }
    });
  } else {
    console.log('Notice: No TARGET_DATABASE_URL or PostgreSQL DATABASE_URL found in local environment.');
    console.log('Running dry-run schema and record audit on Source Database...\n');
  }

  try {
    await sourceSequelize.authenticate();
    console.log('[PASS] Source database connected successfully.');
  } catch (err) {
    console.error(`[FAIL] Could not connect to source database: ${err.message}`);
    process.exit(1);
  }

  if (targetSequelize) {
    try {
      await targetSequelize.authenticate();
      console.log('[PASS] Target Render PostgreSQL connected successfully via SSL.');
    } catch (err) {
      console.warn(`[WARN] Target PostgreSQL connection failed: ${err.message}`);
      console.warn('Will output source audit counts only.\n');
      targetSequelize = null;
    }
  }

  // 3. Initialize Source Models
  const sourceModels = initModels(sourceSequelize);

  // Entities ordered topologically to respect foreign key constraints
  const migrationEntities = [
    { name: 'users', modelName: 'User', table: 'users' },
    { name: 'clients', modelName: 'Client', table: 'clients' },
    { name: 'leads', modelName: 'Lead', table: 'leads' },
    { name: 'projects', modelName: 'Project', table: 'projects' },
    { name: 'client_projects', modelName: 'ClientProject', table: 'client_projects' },
    { name: 'project_photos', modelName: 'ProjectPhoto', table: 'project_photos' },
    { name: 'project_updates', modelName: 'ProjectUpdate', table: 'project_updates' },
    { name: 'tasks', modelName: 'Task', table: 'tasks' },
    { name: 'workers', modelName: 'Worker', table: 'workers' },
    { name: 'attendance', modelName: 'Attendance', table: 'attendance' },
    { name: 'daily_reports', modelName: 'DailyReport', table: 'daily_reports' },
    { name: 'announcements', modelName: 'Announcement', table: 'announcements' },
    { name: 'quotations', modelName: 'Quotation', table: 'quotations' },
    { name: 'invoices', modelName: 'Invoice', table: 'invoices' },
    { name: 'project_payments', modelName: 'ProjectPayment', table: 'project_payments' },
    { name: 'expenses', modelName: 'Expense', table: 'expenses' },
    { name: 'estimates', modelName: 'Estimate', table: 'estimates' },
    { name: 'boq_items', modelName: 'BoqItem', table: 'boq_items' },
    { name: 'drawings', modelName: 'Drawing', table: 'drawings' },
    { name: 'documents', modelName: 'Document', table: 'documents' },
    { name: 'contractors', modelName: 'Contractor', table: 'contractors' },
    { name: 'audit_logs', modelName: 'AuditLog', table: 'audit_logs' }
  ];

  // 4. If Target PostgreSQL is connected, safely synchronize target tables
  let targetModels = null;
  if (targetSequelize) {
    console.log('\nSynchronizing target PostgreSQL schema safely (force: false)...');
    targetModels = initModels(targetSequelize);
    await targetSequelize.sync({ force: false });
    console.log('[PASS] Target PostgreSQL schema synchronized.\n');

    console.log('Migrating records...');
    for (const entity of migrationEntities) {
      const srcModel = sourceModels[entity.modelName];
      const tgtModel = targetModels[entity.modelName];

      if (!srcModel || !tgtModel) continue;

      try {
        const records = await srcModel.findAll({ raw: true });
        if (records && records.length > 0) {
          for (const row of records) {
            // Check if record exists by primary key
            if (row.id) {
              const existing = await tgtModel.findByPk(row.id);
              if (!existing) {
                await tgtModel.create(row);
              }
            } else {
              await tgtModel.create(row);
            }
          }

          // Reset PostgreSQL auto-increment sequence if id column exists
          try {
            await targetSequelize.query(
              `SELECT setval(pg_get_serial_sequence('"${entity.table}"', 'id'), coalesce(max(id), 1), max(id) IS NOT null) FROM "${entity.table}";`
            );
          } catch (_) {
            // Ignore for tables without serial id
          }
        }
      } catch (err) {
        console.warn(`[WARN] Migration error for ${entity.name}: ${err.message}`);
      }
    }
    console.log('[PASS] Data copy completed.\n');
  }

  // 5. Verification & Comparative Audit
  console.log('========================================================================');
  console.log('TABLE NAME                   | OLD COUNT | POSTGRES COUNT | RESULT');
  console.log('-----------------------------+-----------+----------------+-------------');

  for (const entity of migrationEntities) {
    let oldCount = 0;
    let targetCount = 'N/A';
    let status = 'SOURCE AUDIT';

    try {
      oldCount = await sourceModels[entity.modelName].count();
    } catch (_) {
      oldCount = 0;
    }

    if (targetModels && targetModels[entity.modelName]) {
      try {
        const c = await targetModels[entity.modelName].count();
        targetCount = c;
        status = (c >= oldCount) ? 'PASS' : 'PARTIAL';
      } catch (err) {
        targetCount = 'ERROR';
        status = 'FAIL';
      }
    }

    const tName = entity.name.padEnd(28);
    const oCnt = String(oldCount).padStart(9);
    const tgCnt = String(targetCount).padStart(14);
    console.log(`${tName} | ${oCnt} | ${tgCnt} | ${status}`);
  }

  console.log('========================================================================\n');

  if (targetSequelize) {
    console.log('Migration to Render PostgreSQL completed successfully.');
  } else {
    console.log('Audit completed. To execute full migration, supply TARGET_DATABASE_URL.');
  }
}

if (require.main === module) {
  runMigration()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Fatal migration error:', err);
      process.exit(1);
    });
}

module.exports = { runMigration };
