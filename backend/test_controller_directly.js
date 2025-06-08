// Test the actual updateProfile controller function
const db = require('./src/data/database');
const authController = require('./src/controllers/authController');
const bcrypt = require('bcryptjs');

async function testControllerDirectly() {
    try {
        console.log('Testing updateProfile controller directly...');
        
        // Initialize database
        await db.connectDb();
        await db.createTables();
        console.log('Database initialized successfully');
        
        // Get a test user
        const user = await db.findUserById(1);
        if (!user) {
            console.log('No user found with ID 1');
            return;
        }
        
        console.log('Testing with user:', user);
        
        // Create mock request and response objects
        const mockReq = {
            user: { userId: 1 },
            body: {
                name: 'Updated Name Test',
                email: 'romulo@teste.com'
                // No password change for this test
            }
        };
          const mockRes = {
            statusCode: 200,
            status: function(statusCode) {
                this.statusCode = statusCode;
                console.log(`Response status: ${statusCode}`);
                return this;
            },
            json: function(data) {
                console.log('Response data:', JSON.stringify(data, null, 2));
                console.log('Final status code:', this.statusCode);
                return this;
            }
        };
          const mockNext = function(error) {
            if (error) {
                console.error('Error passed to next middleware:', error);
                console.error('Error message:', error.message);
                console.error('Error stack:', error.stack);
                console.error('Is operational error:', error.isOperational);
                console.error('Status code:', error.statusCode);
            } else {
                console.log('No error passed to next middleware');
            }
        };
        
        console.log('\n1. Testing updateProfile without password change...');
        try {
            await authController.updateProfile(mockReq, mockRes, mockNext);
            console.log('updateProfile completed without throwing error');
        } catch (error) {
            console.error('updateProfile threw an error:', error.message);
            console.error('Error details:', error);
        }
          // Test with password change
        console.log('\n2. Testing updateProfile with password change...');
        const mockReqWithPassword = {
            user: { userId: 1 },
            body: {
                name: 'Updated Name Test 2',
                email: 'romulo@teste.com',
                currentPassword: 'romulo123', // You might need to adjust this
                newPassword: 'newpassword123'
            }
        };
        
        try {
            await authController.updateProfile(mockReqWithPassword, mockRes, mockNext);
            console.log('updateProfile with password completed without throwing error');
        } catch (error) {
            console.error('updateProfile with password threw an error:', error.message);
            console.error('Error details:', error);
        }
        
        console.log('\nController test completed!');
        
    } catch (error) {
        console.error('Error during controller test:');
        console.error('Message:', error.message);
        console.error('Stack:', error.stack);
        console.error('Full error:', error);
    } finally {
        process.exit(0);
    }
}

testControllerDirectly();
