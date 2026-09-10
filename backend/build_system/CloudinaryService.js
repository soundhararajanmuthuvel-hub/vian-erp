require('dotenv').config();
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

  /**
   * Uploads a project photo to Cloudinary.
   * Generates full URL, thumbnail URL, and stores publicId.
   * If unconfigured or failed, falls back to local storage in /uploads/project_photos.
   */
  async uploadProjectPhoto(fileInput, originalName) {
    try {
      const isConfigured = Boolean(
        process.env.CLOUDINARY_CLOUD_NAME &&
        process.env.CLOUDINARY_API_KEY &&
        process.env.CLOUDINARY_API_SECRET
      );

      if (!isConfigured) {
        throw new Error('Cloudinary credentials are not configured in environment.');
      }

      console.log(`Uploading project photo (${originalName || 'photo'}) to Cloudinary...`);
      const uploadOptions = {
        folder: 'vian_erp/project_photos',
        resource_type: 'image'
      };

      const result = await cloudinary.uploader.upload(fileInput, uploadOptions);
      const secureUrl = result.secure_url || result.url;
      const thumbnailUrl = secureUrl.includes('/upload/')
        ? secureUrl.replace('/upload/', '/upload/c_fill,w_400,h_300,g_auto/')
        : secureUrl;

      return {
        url: secureUrl,
        thumbnailUrl: thumbnailUrl,
        publicId: result.public_id
      };
    } catch (error) {
      console.warn(`Cloudinary project photo upload fallback: ${error.message}`);
      
      const localPublicDir = path.join(__dirname, '../uploads/project_photos');
      if (!fs.existsSync(localPublicDir)) {
        fs.mkdirSync(localPublicDir, { recursive: true });
      }

      const safeName = (originalName || 'project_photo.jpg').replace(/[^a-zA-Z0-9_.-]/g, '_');
      const destFileName = `${Date.now()}-${safeName}`;
      const destPath = path.join(localPublicDir, destFileName);

      if (typeof fileInput === 'string' && fileInput.startsWith('data:image/')) {
        const base64Data = fileInput.replace(/^data:image\/\w+;base64,/, '');
        fs.writeFileSync(destPath, Buffer.from(base64Data, 'base64'));
      } else if (typeof fileInput === 'string' && fs.existsSync(fileInput)) {
        fs.copyFileSync(fileInput, destPath);
      } else if (Buffer.isBuffer(fileInput)) {
        fs.writeFileSync(destPath, fileInput);
      } else {
        throw new Error('Unsupported file input type for photo upload fallback.');
      }

      const localUrl = `/uploads/project_photos/${destFileName}`;
      return {
        url: localUrl,
        thumbnailUrl: localUrl,
        publicId: null
      };
    }
  }

  /**
   * Deletes a file from Cloudinary given its public ID.
   */
  async deleteFile(publicId) {
    try {
      if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
        throw new Error('Cloudinary credentials are not configured in environment.');
      }
      const result = await cloudinary.uploader.destroy(publicId);
      return result.result === 'ok';
    } catch (error) {
      console.warn(`Cloudinary deletion failed: ${error.message}`);
      return false;
    }
  }
}

module.exports = new CloudinaryService();
