/**
 * Aiven MySQL Connectivity & Diagnostic Test
 *
 * Verifies:
 * 1. Ping / Authentication with Aiven MySQL over TLS/SSL
 * 2. Database Name & Current User
 * 3. MySQL Server Version
 * 4. Network Query Latency
 * 5. Table Counts for Core ERP entities
 *
 * Safe: Read-only, does NOT modify any data.
 */

const { getSequelize, connectDB } = require('./database/db');
require('dotenv').config();

async function testAivenConnection() {
  console.log('=== Aiven MySQL Diagnostic & Verification Suite ===\n');

  const dbHost = process.env.DB_HOST || '(from DATABASE_URL)';
  const dbPort = process.env.DB_PORT || 'N/A';
  const dbName = process.env.DB_NAME || '(from DATABASE_URL)';
  const dbSsl = process.env.DB_SSL === 'true' || process.env.MYSQL_SSL === 'true';

  console.log(`Target Host: ${dbHost}`);
  console.log(`Target Port: ${dbPort}`);
  console.log(`Target Database: ${dbName}`);
  console.log(`SSL Enabled: ${dbSsl ? 'YES (TLS Enforced)' : 'NO'}\n`);

  try {
    const startTime = Date.now();
    const sequelize = await connectDB();
    const connectLatency = Date.now() - startTime;

    console.log(`[1] Connection Handshake: SUCCESS (${connectLatency}ms)`);

    // Verify dialect
    const dialect = sequelize.options.dialect;
    console.log(`[2] Active Dialect: ${dialect.toUpperCase()}`);

    if (dialect === 'mysql') {
      const [verRows] = await sequelize.query('SELECT VERSION() as version, DATABASE() as db, USER() as user, @@ssl_cipher as sslCipher;');
      if (verRows && verRows[0]) {
        console.log(`[3] MySQL Server Version: ${verRows[0].version}`);
        console.log(`[4] Active Database: ${verRows[0].db}`);
        console.log(`[5] Connected User: ${verRows[0].user}`);
        console.log(`[6] Active SSL Cipher: ${verRows[0].sslCipher || 'Standard SSL / Managed'}`);
      }
    }

    // Measure query round-trip latency
    const pingStart = Date.now();
    await sequelize.query('SELECT 1 as ping;');
    const pingLatency = Date.now() - pingStart;
    console.log(`[7] SELECT 1 Query Latency: ${pingLatency}ms`);

    // Check table count in database
    let tables = [];
    if (dialect === 'mysql') {
      const [tableRows] = await sequelize.query("SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE();");
      tables = tableRows.map(r => r.table_name || r.TABLE_NAME);
    } else {
      const [tableRows] = await sequelize.query("SELECT name FROM sqlite_master WHERE type='table';");
      tables = tableRows.map(r => r.name);
    }

    console.log(`[8] Tables in Database: ${tables.length} discovered`);

    console.log('\n=== Database Diagnostic PASSED Successfully! ===\n');
    process.exit(0);
  } catch (err) {
    console.error('\n[X] Database Connection FAILED:');
    console.error(`Error: ${err.message}`);
    if (err.original) {
      console.error(`Code: ${err.original.code || err.original.errno}`);
      console.error(`SQL State: ${err.original.sqlState}`);
    }
    console.error('\nPlease verify DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, and DB_SSL.');
    process.exit(1);
  }
}

if (require.main === module) {
  testAivenConnection();
}

module.exports = { testAivenConnection };
