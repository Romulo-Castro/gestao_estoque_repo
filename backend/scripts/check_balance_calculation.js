const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path
const dbPath = path.join(__dirname, 'inventory_data.db');

console.log('Analyzing document data for balance sheet calculation...');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
        return;
    }
    console.log('Connected to the SQLite database.');
});

// Check all documents with details
db.all(`
    SELECT 
        d.id,
        d.store_id,
        d.type,
        d.document_date,
        d.total_amount,
        d.notes,
        d.createdAt,
        COUNT(di.id) as item_count
    FROM documents d
    LEFT JOIN document_items di ON d.id = di.document_id
    GROUP BY d.id
    ORDER BY d.document_date DESC
`, [], (err, docs) => {
    if (err) {
        console.error('Error querying documents:', err.message);
    } else {
        console.log('\n=== ALL DOCUMENTS ===');
        console.log(`Total documents: ${docs.length}`);
        
        if (docs.length > 0) {
            docs.forEach(doc => {
                console.log(`\nDocument ${doc.id}:`);
                console.log(`  Store: ${doc.store_id}`);
                console.log(`  Type: ${doc.type}`);
                console.log(`  Date: ${doc.document_date}`);
                console.log(`  Total: R$ ${doc.total_amount || 0}`);
                console.log(`  Items: ${doc.item_count}`);
                console.log(`  Created: ${doc.createdAt}`);
            });
            
            // Calculate balance by store
            console.log('\n=== BALANCE CALCULATION BY STORE ===');
            const stores = [...new Set(docs.map(d => d.store_id))];
            
            stores.forEach(storeId => {
                const storeDocs = docs.filter(d => d.store_id === storeId);
                const inflows = storeDocs.filter(d => d.type === 'purchase').reduce((sum, d) => sum + (d.total_amount || 0), 0);
                const outflows = storeDocs.filter(d => d.type === 'sale').reduce((sum, d) => sum + (d.total_amount || 0), 0);
                const balance = inflows - outflows;
                
                console.log(`\nStore ${storeId}:`);
                console.log(`  Inflows (purchases): R$ ${inflows.toFixed(2)}`);
                console.log(`  Outflows (sales): R$ ${outflows.toFixed(2)}`);
                console.log(`  Balance: R$ ${balance.toFixed(2)}`);
                console.log(`  Document count: ${storeDocs.length}`);
            });
        } else {
            console.log('No documents found - this explains why balance sheet is empty!');
        }
    }
    
    // Check document items
    db.all(`
        SELECT 
            di.*,
            d.type as doc_type,
            d.store_id
        FROM document_items di
        JOIN documents d ON di.document_id = d.id
        ORDER BY di.document_id
    `, [], (err, items) => {
        if (err) {
            console.error('Error querying document items:', err.message);
        } else {
            console.log('\n=== DOCUMENT ITEMS ===');
            console.log(`Total items: ${items.length}`);
            
            if (items.length > 0) {
                items.forEach(item => {
                    console.log(`Item ${item.id}: Doc ${item.document_id} (${item.doc_type}) - Product ${item.item_id}, Qty: ${item.quantity}, Price: R$ ${item.unit_price}`);
                });
            }
        }
        
        db.close();
    });
});
