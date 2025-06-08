// Test script to debug profile update functionality
const http = require('http');

// Function to make HTTP requests
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

async function testProfileUpdate() {
    try {
        console.log('=== Testing Profile Update Functionality ===\n');

        // Step 1: Login to get token
        console.log('1. Logging in...');
        const loginOptions = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/auth/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        };        const loginData = JSON.stringify({
            email: 'freshtest@example.com',
            password: 'password123'
        });

        const loginResponse = await makeRequest(loginOptions, loginData);
        console.log('Login Status:', loginResponse.statusCode);
        
        if (loginResponse.statusCode !== 200) {
            console.log('Login failed:', loginResponse.body);
            return;
        }

        const token = loginResponse.body.data.token;
        const currentUser = loginResponse.body.data.user;
        console.log('Login successful! User:', currentUser.name);
        console.log('Token:', token.substring(0, 20) + '...\n');

        // Step 2: Test profile update without password change
        console.log('2. Testing profile update (name and email only)...');
        const profileUpdateOptions = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/auth/profile',
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            }
        };

        const profileUpdateData = JSON.stringify({
            name: 'Test User Updated',
            email: currentUser.email // Keep same email
        });

        const profileResponse = await makeRequest(profileUpdateOptions, profileUpdateData);
        console.log('Profile Update Status:', profileResponse.statusCode);
        console.log('Profile Update Response:', JSON.stringify(profileResponse.body, null, 2));
        console.log('');

        // Step 3: Test password change through profile update
        console.log('3. Testing profile update with password change...');
        const passwordUpdateData = JSON.stringify({
            name: 'Test User Updated',
            email: currentUser.email,
            currentPassword: 'password123',
            newPassword: 'newpassword123'
        });

        const passwordResponse = await makeRequest(profileUpdateOptions, passwordUpdateData);
        console.log('Password Update Status:', passwordResponse.statusCode);
        console.log('Password Update Response:', JSON.stringify(passwordResponse.body, null, 2));
        console.log('');

        // Step 4: Test separate password change endpoint
        console.log('4. Testing separate password change endpoint...');
        const changePasswordOptions = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/auth/change-password',
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            }
        };

        const changePasswordData = JSON.stringify({
            currentPassword: 'newpassword123', // Use the new password from step 3
            newPassword: 'password123' // Change back to original
        });

        const changePasswordResponse = await makeRequest(changePasswordOptions, changePasswordData);
        console.log('Change Password Status:', changePasswordResponse.statusCode);
        console.log('Change Password Response:', JSON.stringify(changePasswordResponse.body, null, 2));

    } catch (error) {
        console.error('Test failed:', error);
    }
}

// Run the test
testProfileUpdate();
