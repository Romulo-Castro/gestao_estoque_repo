// Debug script to test profile update functionality
const db = require('./src/data/database');
const bcrypt = require('bcryptjs');

async function testProfileUpdate() {
    try {
        console.log('Starting profile update debug test...');
          // Initialize database
        await db.connectDb();
        await db.createTables();
        console.log('Database initialized successfully');
        
        // Test finding a user first
        console.log('\n1. Testing findUserById...');
        const testUserId = 1; // Assuming there's a user with ID 1
        const user = await db.findUserById(testUserId);
        
        if (!user) {
            console.log('No user found with ID 1. Let\'s check what users exist:');
            const allUsers = await db.allQuery('SELECT id, name, email FROM users LIMIT 5');
            console.log('Available users:', allUsers);
            
            if (allUsers.length === 0) {
                console.log('No users in database. Creating a test user...');
                const hashedPassword = await bcrypt.hash('test123', 10);
                const result = await db.createUser({
                    name: 'Test User',
                    email: 'test@example.com',
                    passwordHash: hashedPassword
                });
                console.log('Test user created with ID:', result.lastID);
                const newUser = await db.findUserById(result.lastID);
                console.log('New user:', newUser);
                return;
            } else {
                console.log('Using first available user for testing');
                const firstUser = allUsers[0];
                console.log('Selected user:', firstUser);
                
                // Test profile update without password change
                console.log('\n2. Testing profile update without password...');
                const updateData = {
                    name: 'Updated Name',
                    email: firstUser.email // Keep same email
                };
                
                const updateResult = await db.updateUserProfile(firstUser.id, updateData);
                console.log('Update result:', updateResult);
                
                // Verify the update
                const updatedUser = await db.findUserById(firstUser.id);
                console.log('Updated user:', updatedUser);
                
                // Test profile update with password change
                console.log('\n3. Testing profile update with password...');
                const newPassword = 'newpassword123';
                const salt = await bcrypt.genSalt(10);
                const passwordHash = await bcrypt.hash(newPassword, salt);
                
                const updateDataWithPassword = {
                    name: 'Updated Name 2',
                    email: firstUser.email,
                    passwordHash: passwordHash
                };
                
                const updateResult2 = await db.updateUserProfile(firstUser.id, updateDataWithPassword);
                console.log('Update with password result:', updateResult2);
                
                // Verify the update
                const updatedUser2 = await db.findUserById(firstUser.id);
                console.log('Updated user with new password:', updatedUser2);
            }
        } else {
            console.log('Found user:', user);
            
            // Test profile update without password change
            console.log('\n2. Testing profile update without password...');
            const updateData = {
                name: 'Updated Name',
                email: user.email // Keep same email
            };
            
            const updateResult = await db.updateUserProfile(user.id, updateData);
            console.log('Update result:', updateResult);
            
            // Verify the update
            const updatedUser = await db.findUserById(user.id);
            console.log('Updated user:', updatedUser);
        }
        
        console.log('\nProfile update test completed successfully!');
        
    } catch (error) {
        console.error('Error during profile update test:');
        console.error('Message:', error.message);
        console.error('Stack:', error.stack);
        console.error('Full error:', error);
    } finally {
        // Close database connection
        process.exit(0);
    }
}

testProfileUpdate();
