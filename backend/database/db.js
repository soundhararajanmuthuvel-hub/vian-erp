const { Sequelize } = require('sequelize');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

let sequelize;
const useFallback = process.env.AUTO_FALLBACK_SQLITE === 'true';
const sqlitePath = path.join(__dirname, 'vian_architects.sqlite');

const databaseUrl = process.env.DATABASE_URL;
const dbHost = process.env.DB_HOST;
const dbPort = process.env.DB_PORT;
const dbUser = process.env.DB_USER;
const dbPass = process.env.DB_PASSWORD || process.env.DB_PASS || '';
const dbName = process.env.DB_NAME;

const hasUrl = !!databaseUrl;
const hasComponents = !!(dbHost && dbPort && dbUser && dbName);

if (hasUrl) {
  console.log('Initializing Sequelize with DATABASE_URL connection string...');
  sequelize = new Sequelize(databaseUrl, {
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} else if (hasComponents) {
  console.log(`Initializing Sequelize with MySQL host ${dbHost}:${dbPort}...`);
  sequelize = new Sequelize(dbName, dbUser, dbPass, {
    host: dbHost,
    port: parseInt(dbPort, 10),
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} else if (useFallback) {
  console.log('No MySQL environment variables found. Initializing with local SQLite database...');
  const dbDir = path.dirname(sqlitePath);
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: sqlitePath,
    logging: false
  });
} else {
  console.error('FATAL DATABASE CONFIGURATION ERROR:');
  console.error('MySQL database credentials are not configured, and SQLite fallback is disabled.');
  console.error('Please configure DATABASE_URL or (DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD) in your environment.');
  process.exit(1);
}

// Function to establish connection with fallback logic
async function connectDB() {
  try {
    await sequelize.authenticate();
    if (sequelize.options.dialect === 'mysql') {
      console.log('Successfully connected to MySQL database.');
    } else {
      console.log(`Successfully connected to SQLite database at ${sqlitePath}`);
    }
  } catch (error) {
    if (sequelize.options.dialect === 'mysql' && useFallback) {
      console.warn('MySQL connection failed. Falling back to local SQLite database...');
      const dbDir = path.dirname(sqlitePath);
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
      }
      
      sequelize = new Sequelize({
        dialect: 'sqlite',
        storage: sqlitePath,
        logging: false
      });
      
      await sequelize.authenticate();
      console.log(`Successfully connected to SQLite database at ${sqlitePath}`);
    } else {
      console.error(`Database connection failed: ${error.message}`);
      throw error;
    }
  }
  return sequelize;
}

module.exports = {
  sequelize,
  connectDB,
  getSequelize: () => sequelize
};
