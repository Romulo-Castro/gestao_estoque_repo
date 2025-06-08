// Check users in database
const Database = require('./src/data/database');

async function checkUsers() {
    try {
        console.log('Initializing database connection...');
        
        // Initialize database
        await Database.connectDb();
        await Database.createTables();
        
        console.log('Checking users in database...');
        
        // Find all users (this might not exist, so let's try finding by email)
        try {
            const user = await Database.findUserByEmail('test@example.com');
            if (user) {
                console.log('Found user with email test@example.com:', {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    hasPassword: !!user.password_hash
                });
            } else {
                console.log('No user found with email test@example.com');
            }
        } catch (error) {
            console.log('Error finding user:', error.message);
        }

        // Try different common test emails
        const testEmails = ['admin@example.com', 'user@example.com', 'test@test.com'];
        
        for (const email of testEmails) {
            try {
                const user = await Database.findUserByEmail(email);
                if (user) {
                    console.log(`Found user with email ${email}:`, {
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        hasPassword: !!user.password_hash
                    });
                }
            } catch (error) {
                // Ignore errors for non-existent users
            }
        }
        
    } catch (error) {
        console.error('Error checking users:', error);
    }
}

checkUsers();
