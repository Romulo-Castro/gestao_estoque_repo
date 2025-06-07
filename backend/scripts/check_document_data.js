// Check document data with correct column names
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'inventory_data.db');

console.log('📊 Checking document data...');

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
    if (err) {
        console.error('❌ Error opening database:', err.message);
        return;
    }
    
    console.log('✅ Connected to database');
    
    // Check documents with proper column names
    db.all('SELECT id, type, total_amount, store_id FROM documents LIMIT 5', (err, docs) => {
        if (err) {
            console.error('Error querying documents:', err.message);
        } else {
            console.log('\n📄 Documents:');
            if (docs.length === 0) {
                console.log('  - No documents found');
            } else {
                docs.forEach(doc => console.log(`  - Doc ${doc.id}: ${doc.type} - R$ ${doc.total_amount || 0} (store: ${doc.store_id})`));
            }
        }
        
        // Check document items with stock item names
        db.all(`
            SELECT di.document_id, di.quantity, di.unit_price, si.name as item_name, si.unit
            FROM document_items di
            LEFT JOIN stock_items si ON di.item_id = si.id
            LIMIT 10
        `, (err, items) => {
            if (err) {
                console.error('Error querying document items:', err.message);
            } else {
                console.log('\n📋 Document Items (with names):');
                if (items.length === 0) {
                    console.log('  - No document items found');
                } else {
                    items.forEach(item => {
                        const name = item.item_name || `Item ${item.item_id}`;
                        const total = (item.quantity || 0) * (item.unit_price || 0);
                        console.log(`  - Doc ${item.document_id}: ${name} - Qty: ${item.quantity} ${item.unit || 'UN'} - Unit: R$ ${item.unit_price || 0} - Total: R$ ${total.toFixed(2)}`);
                    });
                }
            }
            
            // Check stock items
            db.all('SELECT id, name, unit, current_quantity FROM stock_items LIMIT 5', (err, stockItems) => {
                if (err) {
                    console.error('Error querying stock items:', err.message);
                } else {
                    console.log('\n📦 Stock Items:');
                    if (stockItems.length === 0) {
                        console.log('  - No stock items found');
                    } else {
                        stockItems.forEach(item => console.log(`  - ${item.name}: ${item.current_quantity || 0} ${item.unit || 'UN'}`));
                    }
                }
                
                db.close();
            });
        });
    });
});
