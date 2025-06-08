// Test user registration through API
const http = require('http');

function makeRequest(options, postData = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    const response = {
                        statusCode: res.statusCode,
                        headers: res.headers,
                        body: JSON.parse(data)
                    };
                    resolve(response);
                } catch (e) {
                    resolve({
                        statusCode: res.statusCode,
                        headers: res.headers,
                        body: data
                    });
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        if (postData) {
            req.write(postData);
        }
        req.end();
    });
}

async function createTestUser() {
    try {
        console.log('Creating test user via API...');
        
        const registerOptions = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/auth/register',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const userData = JSON.stringify({
            name: 'Test User',
            email: 'test@example.com',
            password: 'password123'
        });

        const response = await makeRequest(registerOptions, userData);
        console.log('Registration Status:', response.statusCode);
        console.log('Registration Response:', JSON.stringify(response.body, null, 2));

    } catch (error) {
        console.error('Error creating test user:', error);
    }
}

createTestUser();
