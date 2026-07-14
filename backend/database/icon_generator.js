const { Jimp } = require('jimp');
const path = require('path');
const fs = require('fs');

const sourcePath = path.join(__dirname, '../../apps/flutter_web/assets/logo.png');
const androidResDir = path.join(__dirname, '../../apps/flutter_web/android/app/src/main/res');
const iosAppIconDir = path.join(__dirname, '../../apps/flutter_web/ios/Runner/Assets.xcassets/AppIcon.appiconset');
const webDir = path.join(__dirname, '../../apps/flutter_web/web');

// Favicon sizes to generate
const faviconSizes = [16, 32, 48, 64, 128, 256, 512];

// Android Icon Configurations
const androidIcons = [
  { dir: 'mipmap-mdpi', size: 48 },
  { dir: 'mipmap-hdpi', size: 72 },
  { dir: 'mipmap-xhdpi', size: 96 },
  { dir: 'mipmap-xxhdpi', size: 144 },
  { dir: 'mipmap-xxxhdpi', size: 192 }
];

// iOS Icon Configurations
const iosIcons = [
  { name: 'Icon-App-20x20@1x.png', size: 20 },
  { name: 'Icon-App-20x20@2x.png', size: 40 },
  { name: 'Icon-App-20x20@3x.png', size: 60 },
  { name: 'Icon-App-29x29@1x.png', size: 29 },
  { name: 'Icon-App-29x29@2x.png', size: 58 },
  { name: 'Icon-App-29x29@3x.png', size: 87 },
  { name: 'Icon-App-40x40@1x.png', size: 40 },
  { name: 'Icon-App-40x40@2x.png', size: 80 },
  { name: 'Icon-App-40x40@3x.png', size: 120 },
  { name: 'Icon-App-60x60@2x.png', size: 120 },
  { name: 'Icon-App-60x60@3x.png', size: 180 },
  { name: 'Icon-App-76x76@1x.png', size: 76 },
  { name: 'Icon-App-76x76@2x.png', size: 152 },
  { name: 'Icon-App-83.5x83.5@2x.png', size: 167 },
  { name: 'ItunesArtwork@2x.png', size: 1024 }
];

async function generateAllBrandingIcons(logoPath = sourcePath) {
  try {
    if (!fs.existsSync(logoPath)) {
      console.warn(`Source logo not found at ${logoPath}. Skipping icon generation.`);
      return false;
    }

    console.log(`Processing branding icons from source: ${logoPath}`);
    const image = await Jimp.read(logoPath);

    // 1. Generate Android Icons
    for (const config of androidIcons) {
      const targetDir = path.join(androidResDir, config.dir);
      if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
      }
      const resized = image.clone().resize({ w: config.size, h: config.size });
      const dest = path.join(targetDir, 'ic_launcher.png');
      await resized.write(dest);
      console.log(`[Android] Generated icon ${config.size}x${config.size} in ${config.dir}`);
    }

    // 2. Generate iOS Icons
    if (!fs.existsSync(iosAppIconDir)) {
      fs.mkdirSync(iosAppIconDir, { recursive: true });
    }
    for (const config of iosIcons) {
      const resized = image.clone().resize({ w: config.size, h: config.size });
      const dest = path.join(iosAppIconDir, config.name);
      await resized.write(dest);
      console.log(`[iOS] Generated icon: ${config.name} (${config.size}x${config.size})`);
    }

    // 3. Generate Web Favicons & PWAs
    const iconsDir = path.join(webDir, 'icons');
    if (!fs.existsSync(webDir)) fs.mkdirSync(webDir, { recursive: true });
    if (!fs.existsSync(iconsDir)) fs.mkdirSync(iconsDir, { recursive: true });

    for (const size of faviconSizes) {
      const resized = image.clone().resize({ w: size, h: size });
      const destFile = path.join(webDir, `favicon-${size}x${size}.png`);
      await resized.write(destFile);
      console.log(`[Web] Generated favicon-${size}x${size}.png`);
    }

    const defaultFavicon = path.join(webDir, 'favicon.png');
    const resizedFavicon = image.clone().resize({ w: 512, h: 512 });
    await resizedFavicon.write(defaultFavicon);
    console.log(`[Web] Generated main favicon.png`);

    // Generate PWA icons
    const pwaIcons = [
      { file: 'Icon-192.png', size: 192 },
      { file: 'Icon-512.png', size: 512 },
      { file: 'Icon-maskable-192.png', size: 192 },
      { file: 'Icon-maskable-512.png', size: 512 }
    ];
    for (const pwa of pwaIcons) {
      const resized = image.clone().resize({ w: pwa.size, h: pwa.size });
      const destFile = path.join(iconsDir, pwa.file);
      await resized.write(destFile);
      console.log(`[Web PWA] Generated PWA icon: ${pwa.file}`);
    }

    console.log('App branding icons generated successfully for all platforms!');
    return true;
  } catch (error) {
    console.error('Error generating branding icons:', error);
    return false;
  }
}

module.exports = {
  generateAllBrandingIcons
};
