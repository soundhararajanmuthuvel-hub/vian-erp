const { Jimp } = require('jimp');
const path = require('path');
const fs = require('fs');

const sourcePath = path.join(__dirname, '../frontend/assets/logo.png');
const webDir = path.join(__dirname, '../frontend/web');
const iconsDir = path.join(webDir, 'icons');

// Favicon sizes to generate
const faviconSizes = [16, 32, 48, 64, 128, 256, 512];

async function generateIcons() {
  try {
    if (!fs.existsSync(sourcePath)) {
      console.error(`Error: Source logo file not found at ${sourcePath}`);
      return;
    }
    
    console.log(`Reading source logo from: ${sourcePath}`);
    const image = await Jimp.read(sourcePath);
    
    // Ensure directories exist
    if (!fs.existsSync(webDir)) fs.mkdirSync(webDir, { recursive: true });
    if (!fs.existsSync(iconsDir)) fs.mkdirSync(iconsDir, { recursive: true });
    
    // Generate Favicon sizes
    for (const size of faviconSizes) {
      const resized = image.clone().resize({ w: size, h: size });
      const destFile = path.join(webDir, `favicon-${size}x32`.replace('x32', `x${size}`) + '.png');
      await resized.write(destFile);
      console.log(`Generated favicon size ${size}x${size} at: ${destFile}`);
    }

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
      console.log(`Generated PWA icon ${pwa.file} (${pwa.size}x${pwa.size})`);
    }

    // Copy 512x512 as main favicon.png
    const defaultFavicon = path.join(webDir, 'favicon.png');
    fs.copyFileSync(path.join(webDir, 'favicon-512x512.png'), defaultFavicon);
    console.log(`Copied 512x512 favicon as main favicon.png`);

    console.log('Icon generation completed successfully.');
  } catch (error) {
    console.error('Error generating icons:', error);
  }
}

generateIcons();
