// Check database schema
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'inventory_data.db');

console.log('📊 Checking database schema...');

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
    if (err) {
        console.error('❌ Error opening database:', err.message);
        return;
    }
    
    console.log('✅ Connected to database');
    
    // Get all tables
    db.all("SELECT name FROM sqlite_master WHERE type='table'", (err, tables) => {
        if (err) {
            console.error('Error querying tables:', err.message);
            return;
        }
        
        console.log('\n📋 Tables:');
        tables.forEach(table => console.log(`  - ${table.name}`));
        
        // Check documents table structure
        db.all("PRAGMA table_info(documents)", (err, columns) => {
            if (err) {
                console.error('Error querying documents schema:', err.message);
            } else {
                console.log('\n📄 Documents table structure:');
                columns.forEach(col => console.log(`  - ${col.name}: ${col.type}`));
            }
            
            // Check document_items table structure
            db.all("PRAGMA table_info(document_items)", (err, columns) => {
                if (err) {
                    console.error('Error querying document_items schema:', err.message);
                } else {
                    console.log('\n📋 Document_items table structure:');
                    columns.forEach(col => console.log(`  - ${col.name}: ${col.type}`));
                }
                
                // Check some sample data
                db.all('SELECT id, type FROM documents LIMIT 3', (err, docs) => {
                    if (err) {
                        console.error('Error querying documents:', err.message);
                    } else {
                        console.log('\n📄 Sample Documents:');
                        if (docs.length === 0) {
                            console.log('  - No documents found');
                        } else {
                            docs.forEach(doc => console.log(`  - Doc ${doc.id}: ${doc.type}`));
                        }
                    }
                    
                    db.close();
                });
            });
        });
    });
});
