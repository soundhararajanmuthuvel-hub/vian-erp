const { Sequelize } = require('sequelize');
const path = require('path');
const fs = require('fs');

// Load environment variables from current directory or backend/.env
require('dotenv').config();
const backendEnvPath = path.join(__dirname, '../.env');
if (fs.existsSync(backendEnvPath)) {
  require('dotenv').config({ path: backendEnvPath });
}

const isProduction = process.env.NODE_ENV === 'production';
const useFallback = !isProduction || process.env.AUTO_FALLBACK_SQLITE === 'true';
const sqlitePath = path.join(__dirname, 'vian_architects.sqlite');

const databaseUrl = process.env.DATABASE_URL;
const dbHost = process.env.DB_HOST;
const dbPort = process.env.DB_PORT;
const dbUser = process.env.DB_USER;
const dbPass = process.env.DB_PASSWORD || process.env.DB_PASS || '';
const dbName = process.env.DB_NAME;

// Determine dialect: default to postgres in production or when URL starts with postgres
let activeDialect = 'postgres';
if (databaseUrl) {
  if (databaseUrl.startsWith('mysql://')) {
    activeDialect = 'mysql';
  } else if (databaseUrl.startsWith('sqlite:')) {
    activeDialect = 'sqlite';
  } else {
    activeDialect = 'postgres';
  }
} else if (dbHost && dbPort && dbUser && dbName) {
  // If explicitly specified by components
  activeDialect = process.env.DB_DIALECT || (dbPort === '5432' ? 'postgres' : 'mysql');
} else {
  activeDialect = 'sqlite';
}

// SSL Configuration for Render Managed PostgreSQL / cloud databases
let dialectOptions = {};
const disableSsl = process.env.DB_SSL === 'false' || process.env.PGSSLMODE === 'disable';

if (activeDialect === 'postgres') {
  if (!disableSsl && (isProduction || databaseUrl)) {
    dialectOptions = {
      ssl: {
        require: true,
        rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED === 'true'
      }
    };
  }
} else if (activeDialect === 'mysql') {
  const dbSsl = process.env.DB_SSL === 'true' || process.env.MYSQL_SSL === 'true';
  if (dbSsl) {
    dialectOptions = {
      ssl: {
        require: true,
        rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED === 'true'
      }
    };
  }
}

const hasUrl = !!databaseUrl && !databaseUrl.startsWith('sqlite:');
const hasComponents = !!(dbHost && dbPort && dbUser && dbName);

if (hasUrl) {
  console.log(`Initializing Sequelize with DATABASE_URL (${activeDialect})...`);
  sequelize = new Sequelize(databaseUrl, {
    dialect: activeDialect,
    logging: false,
    dialectOptions,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} else if (hasComponents) {
  console.log(`Initializing Sequelize with ${activeDialect} host ${dbHost}:${dbPort}...`);
  sequelize = new Sequelize(dbName, dbUser, dbPass, {
    host: dbHost,
    port: parseInt(dbPort, 10),
    dialect: activeDialect,
    logging: false,
    dialectOptions,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} else if (useFallback) {
  console.log('No PostgreSQL DATABASE_URL found. Initializing with local SQLite development database...');
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
  console.error('Production database credentials (DATABASE_URL) are not configured, and SQLite fallback is disabled in production.');
  console.error('Please configure DATABASE_URL in your Render environment.');
  process.exit(1);
}

// Function to establish connection with fallback logic
async function connectDB() {
  try {
    await sequelize.authenticate();
    const currentDialect = sequelize.options.dialect;
    if (currentDialect === 'postgres') {
      console.log('Successfully connected to Render PostgreSQL database.');
    } else if (currentDialect === 'mysql') {
      console.log('Successfully connected to MySQL database.');
    } else {
      console.log(`Successfully connected to SQLite database at ${sqlitePath}`);
    }
  } catch (error) {
    if (sequelize.options.dialect !== 'sqlite' && useFallback) {
      console.warn(`Primary ${sequelize.options.dialect} connection failed (${error.message}). Falling back to local SQLite database for development...`);
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
