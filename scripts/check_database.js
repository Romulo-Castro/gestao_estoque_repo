// Simple database query script to check existing data
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'inventory_data.db');

console.log('📊 Checking database content...');
console.log('Database path:', dbPath);

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
    if (err) {
        console.error('❌ Error opening database:', err.message);
        return;
    }
    
    console.log('✅ Connected to database');
    
    // Check users
    db.all('SELECT id, name, email FROM users LIMIT 5', (err, users) => {
        if (err) {
            console.error('Error querying users:', err.message);
        } else {
            console.log('\n👥 Users:');
            users.forEach(user => console.log(`  - ${user.name} (${user.email})`));
        }
        
        // Check stores
        db.all('SELECT id, name, user_id FROM stores LIMIT 5', (err, stores) => {
            if (err) {
                console.error('Error querying stores:', err.message);
            } else {
                console.log('\n🏪 Stores:');
                stores.forEach(store => console.log(`  - ${store.name} (user: ${store.user_id})`));
            }
            
            // Check documents
            db.all('SELECT id, type, status, total, store_id FROM documents LIMIT 5', (err, docs) => {
                if (err) {
                    console.error('Error querying documents:', err.message);
                } else {
                    console.log('\n📄 Documents:');
                    if (docs.length === 0) {
                        console.log('  - No documents found');
                    } else {
                        docs.forEach(doc => console.log(`  - Doc ${doc.id}: ${doc.type} - ${doc.status} - R$ ${doc.total || 0}`));
                    }
                }
                
                // Check stock items
                db.all('SELECT id, name, price FROM stock_items LIMIT 5', (err, items) => {
                    if (err) {
                        console.error('Error querying stock items:', err.message);
                    } else {
                        console.log('\n📦 Stock Items:');
                        if (items.length === 0) {
                            console.log('  - No stock items found');
                        } else {
                            items.forEach(item => console.log(`  - ${item.name}: R$ ${item.price || 0}`));
                        }
                    }
                    
                    // Close database
                    db.close((err) => {
                        if (err) {
                            console.error('Error closing database:', err.message);
                        } else {
                            console.log('\n✅ Database connection closed');
                        }
                    });
                });
            });
        });
    });
});
