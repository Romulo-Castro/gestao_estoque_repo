// Test script for image upload functionality
const FormData = require('form-data');
const fs = require('fs');
const http = require('http');
const path = require('path');

const BASE_URL = 'http://localhost:3000/api';

async function testImageUpload() {
    console.log('=== Testing Image Upload Functionality ===');
    
    try {
        // Step 1: Login to get a token
        console.log('1. Logging in...');        const loginData = JSON.stringify({
            email: 'freshtest@example.com',
            password: 'password123'
        });

        const loginOptions = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/auth/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(loginData)
            }
        };

        const loginResponse = await new Promise((resolve, reject) => {
            const req = http.request(loginOptions, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
            });
            req.on('error', reject);
            req.write(loginData);
            req.end();
        });

        if (loginResponse.status !== 200) {
            console.log('Login failed:', loginResponse.data);
            return;
        }

        const token = loginResponse.data.data.token;
        console.log('Login successful! Token obtained.');

        // Step 2: Get stores to find a store ID
        console.log('2. Getting stores...');
        const storesResponse = await new Promise((resolve, reject) => {
            const req = http.request({
                hostname: 'localhost',
                port: 3000,
                path: '/api/stores',
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
            });
            req.on('error', reject);
            req.end();
        });

        if (storesResponse.status !== 200 || !storesResponse.data.data.length) {
            console.log('No stores found:', storesResponse.data);
            return;
        }

        const storeId = storesResponse.data.data[0].id;
        console.log(`Using store ID: ${storeId}`);

        // Step 3: Get stock items to find an item ID
        console.log('3. Getting stock items...');
        const stockResponse = await new Promise((resolve, reject) => {
            const req = http.request({
                hostname: 'localhost',
                port: 3000,
                path: `/api/stores/${storeId}/stock`,
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
            });
            req.on('error', reject);
            req.end();
        });

        if (stockResponse.status !== 200 || !stockResponse.data.data.length) {
            console.log('No stock items found. Creating a test item...');
            
            // Create a test item
            const itemData = JSON.stringify({
                name: 'Test Item for Image Upload',
                quantity: 1.0,
                properties: {}
            });

            const createItemResponse = await new Promise((resolve, reject) => {
                const req = http.request({
                    hostname: 'localhost',
                    port: 3000,
                    path: `/api/stores/${storeId}/stock`,
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(itemData)
                    }
                }, (res) => {
                    let data = '';
                    res.on('data', chunk => data += chunk);
                    res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(data) }));
                });
                req.on('error', reject);
                req.write(itemData);
                req.end();
            });

            if (createItemResponse.status !== 201) {
                console.log('Failed to create test item:', createItemResponse.data);
                return;
            }

            var itemId = createItemResponse.data.data.id;
            console.log(`Created test item with ID: ${itemId}`);
        } else {
            var itemId = stockResponse.data.data[0].id;
            console.log(`Using existing item ID: ${itemId}`);
        }

        // Step 4: Create a dummy image file for testing
        console.log('4. Creating test image...');
        const testImagePath = path.join(__dirname, 'test_image.txt');
        const imageContent = 'This is a fake image file for testing upload functionality.';
        fs.writeFileSync(testImagePath, imageContent);

        // Step 5: Test image upload (this should fail due to file type)
        console.log('5. Testing image upload (should fail - wrong file type)...');
        
        const form = new FormData();
        form.append('productImage', fs.createReadStream(testImagePath), {
            filename: 'test_image.txt',
            contentType: 'text/plain'
        });

        const uploadOptions = {
            hostname: 'localhost',
            port: 3000,
            path: `/api/stores/${storeId}/stock/${itemId}/image`,
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                ...form.getHeaders()
            }
        };

        const uploadResponse = await new Promise((resolve, reject) => {
            const req = http.request(uploadOptions, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try {
                        resolve({ status: res.statusCode, data: JSON.parse(data) });
                    } catch (e) {
                        resolve({ status: res.statusCode, data: data });
                    }
                });
            });
            req.on('error', reject);
            form.pipe(req);
        });

        console.log('Upload Status:', uploadResponse.status);
        console.log('Upload Response:', uploadResponse.data);

        if (uploadResponse.status === 400) {
            console.log('✅ File type validation working correctly - rejected non-image file');
        } else {
            console.log('❌ File type validation may not be working as expected');
        }

        // Cleanup
        fs.unlinkSync(testImagePath);
        console.log('Test completed and cleanup done.');

    } catch (error) {
        console.error('Test failed:', error);
    }
}

testImageUpload();
