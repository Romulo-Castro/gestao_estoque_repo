// Test script to directly call the profile update endpoint
const axios = require('axios');

async function testProfileUpdateEndpoint() {
    try {
        console.log('Testing profile update endpoint...');
        
        // First, let's try to login to get a valid token
        console.log('\n1. Attempting login...');
        const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
            email: 'romulo@teste.com',
            password: 'romulo123'  // You might need to adjust this password
        });
        
        console.log('Login successful! Token received.');
        const token = loginResponse.data.data.token;
        
        // Now try to update the profile
        console.log('\n2. Attempting profile update...');
        const updateData = {
            name: 'Romulo Castro Updated',
            email: 'romulo@teste.com'
        };
        
        const profileUpdateResponse = await axios.put(
            'http://localhost:3000/api/auth/profile',
            updateData,
            {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('Profile update successful!');
        console.log('Response:', profileUpdateResponse.data);
        
        // Test with password change
        console.log('\n3. Attempting profile update with password change...');
        const updateDataWithPassword = {
            name: 'Romulo Castro Updated Again',
            email: 'romulo@teste.com',
            currentPassword: 'romulo123',
            newPassword: 'newpassword123'
        };
        
        const profileUpdateWithPasswordResponse = await axios.put(
            'http://localhost:3000/api/auth/profile',
            updateDataWithPassword,
            {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('Profile update with password successful!');
        console.log('Response:', profileUpdateWithPasswordResponse.data);
        
    } catch (error) {
        console.error('\nError occurred:');
        if (error.response) {
            // Server responded with error status
            console.error('Status:', error.response.status);
            console.error('Status Text:', error.response.statusText);
            console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
            console.error('Response Headers:', error.response.headers);
        } else if (error.request) {
            // Request was made but no response received
            console.error('No response received from server');
            console.error('Request details:', error.request);
        } else {
            // Error setting up the request
            console.error('Error setting up request:', error.message);
        }
        console.error('Full error object:', error);
    }
}

testProfileUpdateEndpoint();
