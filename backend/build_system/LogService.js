const fs = require('fs');
const path = require('path');

class LogService {
  constructor() {
    this.logDir = path.join(__dirname, '../uploads/logs');
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
  }

  getLogFilePath(buildId) {
    return path.join(this.logDir, `build_${buildId}.log`);
  }

  writeLog(buildId, message) {
    const logFile = this.getLogFilePath(buildId);
    const timestamp = new Date().toISOString();
    fs.appendFileSync(logFile, `[${timestamp}] ${message}\n`);
  }

  readLog(buildId) {
    const logFile = this.getLogFilePath(buildId);
    if (fs.existsSync(logFile)) {
      return fs.readFileSync(logFile, 'utf8');
    }
    return 'No logs recorded yet.';
  }

  deleteLog(buildId) {
    const logFile = this.getLogFilePath(buildId);
    if (fs.existsSync(logFile)) {
      fs.unlinkSync(logFile);
    }
  }
}

module.exports = new LogService();
