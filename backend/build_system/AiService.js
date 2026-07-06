const fs = require('fs');
const path = require('path');
const { getSequelize } = require('../database/db');

class AiService {
  /**
   * Tests the Gemini API connection.
   */
  async testConnection(apiKey, model = 'gemini-1.5-flash') {
    try {
      if (!apiKey) {
        throw new Error('API Key is required.');
      }

      console.log(`Testing Gemini API connection with model: ${model}...`);
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: 'Hello, respond with ONLY the word "OK".' }] }]
        })
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`Gemini API returned status ${response.status}: ${errText}`);
      }

      const resJson = await response.json();
      const text = resJson.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
      
      if (text && text.toUpperCase().includes('OK')) {
        return { success: true, message: 'Connection successful' };
      }
      
      throw new Error(`Unexpected API response: ${JSON.stringify(resJson)}`);
    } catch (error) {
      console.error('Gemini connection test failed:', error);
      return { success: false, message: error.message };
    }
  }

  /**
   * Analyzes an uploaded floor plan PDF/image using Gemini API.
   */
  async analyzeFloorPlan(filePath, mimeType, aiSettings) {
    try {
      const apiKey = aiSettings.geminiApiKey;
      const model = aiSettings.aiModel || 'gemini-1.5-flash';
      const temperature = aiSettings.temperature || 0.2;
      const maxTokens = aiSettings.maxTokens || 2048;

      if (!apiKey) {
        throw new Error('Gemini API key is not configured.');
      }

      if (!fs.existsSync(filePath)) {
        throw new Error(`Floor plan file not found at ${filePath}`);
      }

      // Convert file to base64
      const fileBuffer = fs.readFileSync(filePath);
      const base64Data = fileBuffer.toString('base64');

      const systemPrompt = `You are an experienced Senior Civil Quantity Surveyor and Construction Estimator.
Analyze the uploaded architectural floor plan drawing.
Perform detailed quantity take-offs and analysis:
- Detect Built-up Area
- Detect External and Internal Wall Lengths
- Detect Wall Thickness (typically in inches, e.g. 9 or 4.5 inches)
- Detect Beam layout presence and Column count
- Detect Doors, Windows, Room types (bedrooms, bathrooms, kitchen, dining, living, pooja, store, utility)
- Detect balconies, sit-outs, stairs, lift shafts, double height areas, courtyard, verandah, parking, terrace
- Assess Structural Complexity (Simple, Medium, Heavy RCC, Complex Cantilever)
- Assess Project Complexity (Simple, Standard, Complex, Luxury) based on: corners count, irregular shapes, curved walls, cantilever, double height, large glass areas, roof design, balconies count, staircase layout, span length.
- Estimate confidence percentages for different detection areas.

Return a structured JSON object only. Do not wrap in markdown quotes. The JSON structure MUST be exactly:
{
  "projectName": "Project name or drawing title (or 'VIAN Project')",
  "clientName": "Client name if found, else null",
  "builtUpArea": 2500, // built-up area in square feet
  "floors": 2, // total number of floors
  "externalWallLength": 150.0, // in feet
  "internalWallLength": 220.0, // in feet
  "wallThickness": 9.0, // typical wall thickness in inches (e.g. 9 or 4.5)
  "beamLayout": true, // true if beams or structural grid is visible
  "columnCount": 16, // number of columns detected
  "doorCount": 14,
  "windowCount": 18,
  "bedrooms": 3,
  "bathrooms": 4,
  "kitchen": 1,
  "balcony": 2,
  "sitout": true, // true if sit-out is detected
  "stairs": true, // true if staircase is detected
  "lift": false, // true if lift shaft is detected
  "doubleHeight": false, // true if double height ceiling is detected
  "parking": true, // true if parking area is detected
  "terrace": true, // true if terrace is detected
  "utility": true, // true if utility/wash area is detected
  "pooja": true, // true if pooja room is detected
  "store": true, // true if store room is detected
  "dining": true, // true if dining room is detected
  "living": true, // true if living room is detected
  "verandah": false, // true if verandah is detected
  "courtyard": false, // true if open courtyard is detected
  "complexityScore": "Standard", // must be 'Simple', 'Standard', 'Complex', or 'Luxury'
  "complexityFactors": ["Irregular Shapes", "Multiple Balconies"], // list of detected complexity factors
  "structuralComplexity": "Medium Structure", // must be 'Simple Structure', 'Medium Structure', 'Heavy RCC Structure', or 'Complex Cantilever Structure'
  "confidence": {
    "builtUpArea": 0.98, // decimal between 0.0 and 1.0 (corresponds to 98%)
    "wallDetection": 0.95, // decimal (corresponds to 95%)
    "roomDetection": 0.93, // decimal (corresponds to 93%)
    "doorDetection": 0.96, // decimal (corresponds to 96%)
    "windowDetection": 0.94, // decimal (corresponds to 94%)
    "materialEstimate": 0.90, // decimal (corresponds to 90%)
    "labourEstimate": 0.88 // decimal (corresponds to 88%)
  }
}
If the drawing is invalid or cannot be parsed, return a JSON with a single key 'error' set to 'invalid_drawing'.`;

      console.log(`Sending floor plan to Gemini (${model}) for analysis...`);
      
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: systemPrompt },
                {
                  inlineData: {
                    mimeType: mimeType,
                    data: base64Data
                  }
                }
              ]
            }
          ],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: parseFloat(temperature),
            maxOutputTokens: parseInt(maxTokens)
          }
        })
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`Gemini API returned status ${response.status}: ${errText}`);
      }

      const resJson = await response.json();
      
      // Parse token usage metadata
      const totalTokens = resJson.usageMetadata?.totalTokenCount || 0;
      
      // Log token usage and update database counter
      await this.updateUsageStats(totalTokens);

      const text = resJson.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) {
        throw new Error('Gemini API returned empty response.');
      }

      console.log(`Gemini response: ${text}`);
      const result = JSON.parse(text);

      if (result.error === 'invalid_drawing') {
        throw new Error('Unable to identify or process drawing features.');
      }

      return {
        success: true,
        data: result,
        tokensUsed: totalTokens
      };

    } catch (error) {
      console.warn('Gemini floor plan analysis failed:', error.message);
      
      // Return user friendly warning fallback format so the frontend doesn't crash but workflow continues
      return {
        success: false,
        warning: 'Unable to accurately determine all dimensions. Please enter the built-up area to continue estimation.',
        data: {
          projectName: 'Uploaded Floor Plan',
          clientName: null,
          builtUpArea: null,
          floors: 1,
          bedrooms: 0,
          bathrooms: 0,
          kitchen: 0,
          livingRoom: 0,
          parking: 0,
          balcony: 0,
          stairs: false,
          doorCount: 0,
          windowCount: 0,
          wallLength: 0,
          plotSize: null,
          roomCount: 0,
          confidence: {}
        }
      };
    }
  }

  /**
   * Updates AI settings API usage and token counters in the database.
   */
  async updateUsageStats(tokens) {
    try {
      const sequelize = getSequelize();
      const AiSetting = sequelize.models.AiSetting;
      if (AiSetting) {
        // Find the active setting
        let setting = await AiSetting.findOne({ order: [['createdAt', 'DESC']] });
        if (setting) {
          await setting.update({
            apiUsageCount: setting.apiUsageCount + 1,
            dailyTokenUsage: setting.dailyTokenUsage + tokens
          });
        }
      }
    } catch (e) {
      console.error('Failed to update API usage stats:', e.message);
    }
  }
}

module.exports = new AiService();
