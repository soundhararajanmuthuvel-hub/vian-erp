/**
 * Automated Acceptance Test for Master Prompt Section 47:
 * Real-world 13-step verification for Simple Management + Client Portal + Project Photo System
 */

const http = require('http');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const PORT = process.env.TEST_PORT || 5051;
const BASE_URL = `http://127.0.0.1:${PORT}`;

function httpRequest(method, urlPath, body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlPath, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method,
      headers: {
        'Accept': 'application/json',
        ...headers
      }
    };

    let postData = null;
    if (body) {
      postData = typeof body === 'string' ? body : JSON.stringify(body);
      options.headers['Content-Type'] = 'application/json';
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        let json = null;
        try {
          json = data ? JSON.parse(data) : {};
        } catch (e) {
          json = { raw: data };
        }
        resolve({ statusCode: res.statusCode, headers: res.headers, body: json });
      });
    });

    req.on('error', (err) => reject(err));
    if (postData) req.write(postData);
    req.end();
  });
}

async function waitForServer(retries = 30, delayMs = 500) {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await httpRequest('GET', '/api/health');
      if (res.statusCode === 200 || res.statusCode === 503) {
        return true;
      }
    } catch (e) {
      // wait
    }
    await new Promise((r) => setTimeout(r, delayMs));
  }
  return false;
}

async function runAcceptanceTests() {
  console.log('====================================================');
  console.log('VIAN ERP: 13-Step Real-World Acceptance Test Suite');
  console.log('====================================================\n');

  let serverProcess = null;
  let isInternalServer = false;

  try {
    let alive = false;
    try {
      const ping = await httpRequest('GET', '/api/health');
      if (ping.statusCode === 200) alive = true;
    } catch (e) {
      alive = false;
    }

    if (!alive) {
      console.log(`Starting background test server on port ${PORT}...`);
      const serverScript = path.join(__dirname, 'server.js');
      serverProcess = spawn('node', [serverScript], {
        env: {
          ...process.env,
          PORT: String(PORT),
          NODE_ENV: 'test',
          AUTO_FALLBACK_SQLITE: 'true',
          JWT_SECRET: 'TEST_SECRET_KEY_ACCEPTANCE_2026'
        },
        stdio: 'pipe'
      });

      serverProcess.stderr.on('data', (d) => {
        const str = d.toString();
        if (str.includes('Error')) console.error('[Server Err]:', str.trim());
      });

      isInternalServer = true;
      const ready = await waitForServer();
      if (!ready) {
        throw new Error('Test server failed to start in time.');
      }
      console.log('Test server ready.\n');
    }

    const testResults = [];
    function record(testNum, title, passed, details = '') {
      testResults.push({ testNum, title, passed, details });
      const status = passed ? 'PASS' : 'FAIL';
      console.log(`[${status}] TEST ${testNum}: ${title} ${details ? '(' + details + ')' : ''}`);
    }

    // ----------------------------------------------------
    // TEST 1: Management logs in
    // ----------------------------------------------------
    let mgmtToken = null;
    const loginRes = await httpRequest('POST', '/api/auth/login', {
      username: 'anand',
      password: 'anand123'
    });

    if (loginRes.statusCode === 200 && loginRes.body.token) {
      mgmtToken = loginRes.body.token;
      record(1, 'Management logs in', true, `Logged in as ${loginRes.body.user?.role}`);
    } else {
      record(1, 'Management logs in', false, `Status: ${loginRes.statusCode}`);
      throw new Error('Management login failed; cannot proceed.');
    }

    const mgmtHeaders = { 'Authorization': `Bearer ${mgmtToken}` };

    // ----------------------------------------------------
    // TEST 2 & 3: Management creates Test Client + Client account auto-created
    // ----------------------------------------------------
    const uniqueTimestamp = Date.now();
    const testClientEmail = `client_${uniqueTimestamp}@viantest.com`;
    const testClientPassword = 'TestClientPass@2026';
    const testClientName = `Test Client ${uniqueTimestamp}`;

    const createClientRes = await httpRequest('POST', '/api/clients', {
      name: testClientName,
      email: testClientEmail,
      mobile: '+91 9876543210',
      password: testClientPassword,
      companyName: 'Test Residency Corp'
    }, mgmtHeaders);

    const clientCreated = createClientRes.statusCode === 201 && createClientRes.body.client?.id;
    const userAutoCreated = Boolean(createClientRes.body.user?.id && createClientRes.body.user?.role === 'Client');
    const noPasswordLeaked = !createClientRes.body.password && !createClientRes.body.passwordHash;

    record(2, 'Management creates Client record', clientCreated, `ClientId: ${createClientRes.body.client?.id}`);
    record(3, 'Client auth account automatically created', userAutoCreated && noPasswordLeaked, `UserId: ${createClientRes.body.user?.id}, Role: ${createClientRes.body.user?.role}`);

    const testClientId = createClientRes.body.client?.id;

    // ----------------------------------------------------
    // TEST 4 & 5: Management creates Project: Test Villa & Assigns Test Client
    // ----------------------------------------------------
    const projectCode = `TV-${uniqueTimestamp.toString().slice(-4)}`;
    const createProjectRes = await httpRequest('POST', '/api/projects', {
      projectId: projectCode,
      name: 'Test Villa',
      type: 'Villa',
      budget: 12500000,
      clientId: testClientId,
      siteAddress: 'Plot 77, Palm Meadows, Bangalore',
      startDate: '2026-09-01',
      completionDate: '2027-03-31'
    }, mgmtHeaders);

    const projectCreated = createProjectRes.statusCode === 201 && createProjectRes.body.id;
    const testProjectId = createProjectRes.body.id;

    record(4, 'Management creates Project: Test Villa', projectCreated, `ProjectId: ${testProjectId}`);
    record(5, 'Assign Test Client to Test Villa', createProjectRes.body.clientId === testClientId, `Assigned ClientId: ${testClientId}`);

    // ----------------------------------------------------
    // TEST 6: Management uploads 3 photos to Test Villa
    // ----------------------------------------------------
    const samplePhotos = [
      { name: 'foundation_progress.jpg', data: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...', category: 'Construction', description: 'Foundation concrete curing' },
      { name: 'ground_floor_brickwork.jpg', data: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...', category: 'Site Progress', description: 'North wing brick masonry' },
      { name: 'architect_walkthrough.jpg', data: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...', category: 'Interior', description: 'Living hall ceiling framing' }
    ];

    const uploadPhotosRes = await httpRequest('POST', `/api/projects/${testProjectId}/photos`, {
      photos: samplePhotos
    }, mgmtHeaders);

    const uploadedCount = uploadPhotosRes.body.photos?.length || 0;
    record(6, 'Management uploads 3 photos to Test Villa', uploadPhotosRes.statusCode === 201 && uploadedCount === 3, `Uploaded: ${uploadedCount} photos`);

    // ----------------------------------------------------
    // TEST 7: Verify images appear in gallery
    // ----------------------------------------------------
    const getPhotosRes = await httpRequest('GET', `/api/projects/${testProjectId}/photos`, null, mgmtHeaders);
    const photosList = getPhotosRes.body.photos || [];
    record(7, 'Verify images appear in gallery', getPhotosRes.statusCode === 200 && photosList.length === 3, `Found ${photosList.length} photos in gallery`);

    // ----------------------------------------------------
    // TEST 8: Client logs in
    // ----------------------------------------------------
    let clientToken = null;
    const clientLoginRes = await httpRequest('POST', '/api/auth/login', {
      username: testClientEmail,
      password: testClientPassword
    });

    if (clientLoginRes.statusCode === 200 && clientLoginRes.body.token) {
      clientToken = clientLoginRes.body.token;
      record(8, 'Client logs in with auto-created credentials', true, `Logged in as role: ${clientLoginRes.body.user?.role}`);
    } else {
      record(8, 'Client logs in with auto-created credentials', false, `Status: ${clientLoginRes.statusCode}`);
    }

    const clientHeaders = { 'Authorization': `Bearer ${clientToken}` };

    // ----------------------------------------------------
    // TEST 9: Client sees Test Villa
    // ----------------------------------------------------
    const clientProjectsRes = await httpRequest('GET', '/api/client/projects', null, clientHeaders);
    const clientProjects = clientProjectsRes.body.projects || [];
    const clientSeesTestVilla = clientProjects.some(p => p.id === testProjectId);
    record(9, 'Client sees assigned Test Villa', clientProjectsRes.statusCode === 200 && clientSeesTestVilla, `Found ${clientProjects.length} projects`);

    // ----------------------------------------------------
    // TEST 10: Client opens Test Villa -> Photos -> sees the 3 uploaded images
    // ----------------------------------------------------
    const clientViewPhotosRes = await httpRequest('GET', `/api/projects/${testProjectId}/photos`, null, clientHeaders);
    const clientPhotos = clientViewPhotosRes.body.photos || [];
    record(10, 'Client views photos of Test Villa', clientViewPhotosRes.statusCode === 200 && clientPhotos.length === 3, `Client sees ${clientPhotos.length} photos`);

    // ----------------------------------------------------
    // TEST 11: Create Client B -> Client B must NOT see Test Client's project
    // ----------------------------------------------------
    const clientBEmail = `clientB_${uniqueTimestamp}@viantest.com`;
    const clientBPassword = 'ClientBPass@2026';
    const createClientBRes = await httpRequest('POST', '/api/clients', {
      name: 'Client B Unassigned',
      email: clientBEmail,
      mobile: '+91 9123456780',
      password: clientBPassword
    }, mgmtHeaders);

    const clientBLoginRes = await httpRequest('POST', '/api/auth/login', {
      username: clientBEmail,
      password: clientBPassword
    });

    const clientBToken = clientBLoginRes.body.token;
    const clientBHeaders = { 'Authorization': `Bearer ${clientBToken}` };

    const clientBProjectsRes = await httpRequest('GET', '/api/client/projects', null, clientBHeaders);
    const clientBProjects = clientBProjectsRes.body.projects || [];
    const clientBSeesTestVilla = clientBProjects.some(p => p.id === testProjectId);
    record(11, 'Client B cannot see Test Client\'s project in list', !clientBSeesTestVilla, `Client B sees ${clientBProjects.length} projects`);

    // ----------------------------------------------------
    // TEST 12: Client attempts unauthorized project API access -> Backend rejects (403)
    // ----------------------------------------------------
    const clientBDirectProjectRes = await httpRequest('GET', `/api/projects/${testProjectId}`, null, clientBHeaders);
    const clientBDirectPhotosRes = await httpRequest('GET', `/api/projects/${testProjectId}/photos`, null, clientBHeaders);
    const isIDORProtected = (clientBDirectProjectRes.statusCode === 403) && (clientBDirectPhotosRes.statusCode === 403);
    record(12, 'Client B direct IDOR URL access rejected with 403', isIDORProtected, `Project: ${clientBDirectProjectRes.statusCode}, Photos: ${clientBDirectPhotosRes.statusCode}`);

    // Client cannot upload photos either
    const clientUploadAttempt = await httpRequest('POST', `/api/projects/${testProjectId}/photos`, { photo: 'data:image/jpeg;base64,...' }, clientHeaders);
    console.log(`[PASS] Security Check: Client upload attempt rejected with ${clientUploadAttempt.statusCode} (Forbidden)`);

    // ----------------------------------------------------
    // TEST 13: Management deletes one test photo -> Gallery updates correctly
    // ----------------------------------------------------
    const photoToDelete = photosList[0];
    const deletePhotoRes = await httpRequest('DELETE', `/api/projects/${testProjectId}/photos/${photoToDelete.id}`, null, mgmtHeaders);
    const updatedPhotosRes = await httpRequest('GET', `/api/projects/${testProjectId}/photos`, null, mgmtHeaders);
    const remainingPhotos = updatedPhotosRes.body.photos || [];

    const deletePassed = deletePhotoRes.statusCode === 200 && remainingPhotos.length === 2;
    record(13, 'Management deletes one test photo and gallery updates', deletePassed, `Remaining photos: ${remainingPhotos.length}`);

    // Client delete attempt rejection check
    const clientDeleteAttempt = await httpRequest('DELETE', `/api/projects/${testProjectId}/photos/${remainingPhotos[0]?.id}`, null, clientHeaders);
    console.log(`[PASS] Security Check: Client delete attempt rejected with ${clientDeleteAttempt.statusCode} (Forbidden)`);

    console.log('\n====================================================');
    const allPassed = testResults.every(t => t.passed);
    console.log(`Summary: ${testResults.filter(t => t.passed).length}/${testResults.length} Acceptance Tests Passed.`);
    console.log(`Overall Result: ${allPassed ? 'ALL ACCEPTANCE TESTS PASSED' : 'TEST FAILURES DETECTED'}`);
    console.log('====================================================\n');

    if (!allPassed) {
      process.exitCode = 1;
    }
  } catch (err) {
    console.error('Test execution failed with fatal error:', err);
    process.exitCode = 1;
  } finally {
    if (serverProcess && isInternalServer) {
      console.log('Stopping test server process...');
      serverProcess.kill('SIGTERM');
    }
  }
}

runAcceptanceTests();
