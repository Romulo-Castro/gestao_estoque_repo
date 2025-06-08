// Create a fresh test user with known password
const Database = require('./src/data/database');
const bcrypt = require('bcryptjs');

async function createFreshTestUser() {
    try {
        console.log('Initializing database...');
        await Database.connectDb();
        await Database.createTables();
        
        console.log('Creating fresh test user...');
        
        // Delete existing test user if any
        try {
            await Database.runQuery('DELETE FROM users WHERE email = ?', ['freshtest@example.com']);
            console.log('Deleted any existing fresh test user');
        } catch (e) {
            // Ignore if user doesn't exist
        }
        
        // Hash password manually
        const saltRounds = 10;
        const plainPassword = 'password123';
        const hashedPassword = await bcrypt.hash(plainPassword, saltRounds);
        
        console.log('Plain password:', plainPassword);
        console.log('Hashed password:', hashedPassword);
        
        // Create user
        const result = await Database.createUser({
            name: 'Fresh Test User',
            email: 'freshtest@example.com',
            passwordHash: hashedPassword
        });
        
        console.log('User created with ID:', result.lastID);
        
        // Verify user exists
        const user = await Database.findUserByEmail('freshtest@example.com');
        console.log('Verified user:', {
            id: user.id,
            name: user.name,
            email: user.email,
            hasPassword: !!user.password_hash,
            passwordHashLength: user.password_hash ? user.password_hash.length : 0
        });
        
        // Test password verification
        const isPasswordCorrect = await bcrypt.compare(plainPassword, user.password_hash);
        console.log('Password verification test:', isPasswordCorrect);
        
    } catch (error) {
        console.error('Error:', error);
    }
}

createFreshTestUser();
