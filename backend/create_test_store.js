const http = require('http');

async function createStore() {
    try {
        const loginData = JSON.stringify({
            email: 'freshtest@example.com',
            password: 'password123'
        });

        // Login
        console.log('Logging in...');
        const loginResponse = await new Promise((resolve, reject) => {
            const req = http.request({
                hostname: 'localhost',
                port: 3000,
                path: '/api/auth/login',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(loginData)
                }
            }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
            });
            req.on('error', reject);
            req.write(loginData);
            req.end();
        });

        if (loginResponse.status !== 200) {
            console.log('Login failed:', loginResponse);
            return;
        }

        const token = loginResponse.data.data.token;
        console.log('Login successful! Token obtained.');

        // Create store
        console.log('Creating test store...');
        const storeData = JSON.stringify({
            name: 'Test Store',
            address: 'Test Address'
        });

        const storeResponse = await new Promise((resolve, reject) => {
            const req = http.request({
                hostname: 'localhost',
                port: 3000,
                path: '/api/stores',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(storeData),
                    'Authorization': `Bearer ${token}`
                }
            }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
            });
            req.on('error', reject);
            req.write(storeData);
            req.end();
        });

        console.log('Store creation status:', storeResponse.status);
        console.log('Store response:', JSON.stringify(storeResponse.data, null, 2));

        if (storeResponse.status === 201) {
            const storeId = storeResponse.data.data.id;
            console.log(`Store created successfully with ID: ${storeId}`);
            
            // Create a test stock item
            console.log('Creating test stock item...');
            const stockData = JSON.stringify({
                name: 'Test Product',
                description: 'Test product for image upload',
                price: 10.99,
                quantity: 100,
                category: 'Test Category'
            });

            const stockResponse = await new Promise((resolve, reject) => {
                const req = http.request({
                    hostname: 'localhost',
                    port: 3000,
                    path: `/api/stores/${storeId}/stock`,
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(stockData),
                        'Authorization': `Bearer ${token}`
                    }
                }, (res) => {
                    let data = '';
                    res.on('data', chunk => data += chunk);
                    res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
                });
                req.on('error', reject);
                req.write(stockData);
                req.end();
            });

            console.log('Stock creation status:', stockResponse.status);
            console.log('Stock response:', JSON.stringify(stockResponse.data, null, 2));
        }

    } catch (error) {
        console.error('Error:', error);
    }
}

createStore();
