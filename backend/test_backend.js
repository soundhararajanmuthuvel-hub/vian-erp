const http = require('http');

function apiRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed, headers: res.headers });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data, headers: res.headers });
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

async function runTests() {
  console.log('=== Running VIAN ERP Backend Functional Tests ===\n');

  // 1. Health check
  process.stdout.write('Test 1: Health check endpoint (GET /api/health)... ');
  const healthRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/health',
    method: 'GET'
  });
  if (healthRes.status === 200 && healthRes.data.status === 'ok') {
    console.log('PASS');
  } else {
    console.error('FAIL:', healthRes);
    process.exit(1);
  }

  // 2. Authentication: Super Admin login
  process.stdout.write('Test 2: Authentication (POST /api/auth/login)... ');
  const loginRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, { username: 'demo_superadmin', password: 'Demo@12345' });

  if (loginRes.status === 200 && loginRes.data.token) {
    console.log('PASS');
  } else {
    console.error('FAIL:', loginRes);
    process.exit(1);
  }
  const token = loginRes.data.token;

  // 3. User Profile
  process.stdout.write('Test 3: User Profile (GET /api/auth/profile)... ');
  const profileRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/auth/profile',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (profileRes.status === 200 && profileRes.data.user) {
    console.log('PASS');
  } else {
    console.error('FAIL:', profileRes);
    process.exit(1);
  }

  // 4. Dashboard statistics
  process.stdout.write('Test 4: Dashboard stats (GET /api/dashboard)... ');
  const dashRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/dashboard',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (dashRes.status === 200) {
    console.log('PASS');
  } else {
    console.error('FAIL:', dashRes);
    process.exit(1);
  }

  // 5. Projects list
  process.stdout.write('Test 5: Projects listing (GET /api/projects)... ');
  const projRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/projects',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (projRes.status === 200) {
    console.log('PASS');
  } else {
    console.error('FAIL:', projRes);
    process.exit(1);
  }

  // 6. Clients list
  process.stdout.write('Test 6: Clients listing (GET /api/clients)... ');
  const clientsRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/clients',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (clientsRes.status === 200) {
    console.log('PASS');
  } else {
    console.error('FAIL:', clientsRes);
    process.exit(1);
  }

  // 7. Leads list
  process.stdout.write('Test 7: CRM Leads listing (GET /api/crm/leads)... ');
  const leadsRes = await apiRequest({
    hostname: 'localhost',
    port: 5050,
    path: '/api/crm/leads',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (leadsRes.status === 200) {
    console.log('PASS');
  } else {
    console.error('FAIL:', leadsRes);
    process.exit(1);
  }

  console.log('\nAll VIAN ERP Backend Functional Tests Passed Successfully!\n');
}

runTests().catch(err => {
  console.error('Backend test failure:', err);
  process.exit(1);
});
