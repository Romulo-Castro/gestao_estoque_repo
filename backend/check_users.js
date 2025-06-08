// Check users in database
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'inventory_data.db');
const db = new sqlite3.Database(dbPath);

console.log('Checking users in database...\n');

db.all('SELECT id, name, email FROM users', (err, rows) => {
    if (err) {
        console.error('Error:', err.message);
        return;
    }
    
    console.log('Users found:');
    console.table(rows);
    
    if (rows.length === 0) {
        console.log('\nNo users found. Creating test user...');
        
        const bcrypt = require('bcrypt');
        const saltRounds = 10;
        const password = 'admin123';
        
        bcrypt.hash(password, saltRounds, (err, hash) => {
            if (err) {
                console.error('Error hashing password:', err);
                return;
            }
            
            db.run('INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)', 
                ['Admin', 'admin@igreja.com', hash], 
                function(err) {
                    if (err) {
                        console.error('Error creating user:', err.message);
                    } else {
                        console.log('✅ Test user created with ID:', this.lastID);
                        console.log('Email: admin@igreja.com');
                        console.log('Password: admin123');
                    }
                    db.close();
                }
            );
        });
    } else {
        db.close();
    }
});
