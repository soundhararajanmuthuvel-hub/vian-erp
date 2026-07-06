const { Sequelize } = require('sequelize');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

let sequelize;

const dbHost = process.env.DB_HOST || '127.0.0.1';
const dbPort = process.env.DB_PORT || 3306;
const dbUser = process.env.DB_USER || 'root';
const dbPass = process.env.DB_PASS || '';
const dbName = process.env.DB_NAME || 'vian_architects_db';
const useFallback = process.env.AUTO_FALLBACK_SQLITE === 'true';

// SQLite configuration details
const sqlitePath = path.join(__dirname, 'vian_architects.sqlite');

try {
  // We first initialize with MySQL configuration
  console.log(`Connecting to MySQL at ${dbHost}:${dbPort}...`);
  
  // Since we know mysql server isn't active on port 3306 right now, we can write a function to check or try connection.
  // Sequelize constructor does not immediately connect, it connects on authenticate().
  // Therefore, we can configure Sequelize, but we will wrap the authenticate in our server startup.
  
  sequelize = new Sequelize(dbName, dbUser, dbPass, {
    host: dbHost,
    port: dbPort,
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} catch (error) {
  console.error('Failed to initialize MySQL Sequelize client:', error);
}

// Function to establish connection with fallback logic
async function connectDB() {
  try {
    if (sequelize.options.dialect === 'mysql') {
      await sequelize.authenticate();
      console.log('Successfully connected to MySQL database.');
    } else {
      throw new Error('SQLite dialect in use');
    }
  } catch (error) {
    if (useFallback) {
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
      console.error('Database connection failed and SQLite fallback is disabled.');
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
