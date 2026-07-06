const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const path = require('path');

// Configure Cloudinary from environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

class CloudinaryService {
  /**
   * Uploads a local file to Cloudinary.
   * If it fails or is unconfigured, it returns a local relative URL as a fallback.
   */
  async uploadFile(filePath, originalName) {
    try {
      if (!fs.existsSync(filePath)) {
        throw new Error(`File not found at ${filePath}`);
      }

      // Check if Cloudinary is configured
      if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
        throw new Error('Cloudinary credentials are not configured in environment.');
      }

      console.log(`Uploading ${filePath} to Cloudinary...`);
      const result = await cloudinary.uploader.upload(filePath, {
        folder: 'vian_erp/floor_plans',
        resource_type: 'auto',
        public_id: path.parse(originalName || 'drawing').name + '-' + Date.now()
      });

      console.log(`Cloudinary upload successful: ${result.secure_url}`);
      return result.secure_url;
    } catch (error) {
      console.warn(`Cloudinary upload failed: ${error.message}. Falling back to local copy.`);
      
      // Save/copy to a public assets folder if we want to host it locally
      const localPublicDir = path.join(__dirname, '../uploads/floor_plans');
      if (!fs.existsSync(localPublicDir)) {
        fs.mkdirSync(localPublicDir, { recursive: true });
      }

      const destFileName = `${Date.now()}-${originalName || 'floor_plan.pdf'}`;
      const destPath = path.join(localPublicDir, destFileName);
      fs.copyFileSync(filePath, destPath);

      // Return a relative route served by our Express server
      return `/uploads/floor_plans/${destFileName}`;
    }
  }
}

module.exports = new CloudinaryService();
