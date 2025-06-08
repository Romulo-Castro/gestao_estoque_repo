// Create test user for testing profile functionality
const bcrypt = require('bcrypt');
const Database = require('./src/data/database');
const db = Database;

async function createTestUser() {
    try {
        console.log('Creating test user...');
        
        // Hash the password
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash('password123', salt);
        
        // Check if user already exists
        const existingUser = await db.findUserByEmail('test@example.com');
        if (existingUser) {
            console.log('Test user already exists:', existingUser);
            return existingUser;
        }
        
        // Create new user
        const userId = await db.createUser({
            name: 'Test User',
            email: 'test@example.com',
            passwordHash: passwordHash
        });
        
        console.log('Test user created with ID:', userId);
        
        // Get the created user
        const user = await db.findUserById(userId);
        console.log('Created user:', user);
        
        return user;
    } catch (error) {
        console.error('Error creating test user:', error);
    }
}

createTestUser();