const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path
const dbPath = path.join(__dirname, 'inventory_data.db');

console.log('Testing balance sheet date filtering...');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
        return;
    }
    console.log('Connected to the SQLite database.');
});

// Get documents with details
db.all(`
    SELECT 
        d.id,
        d.store_id,
        d.type,
        d.document_date,
        d.total_amount,
        COUNT(di.id) as item_count
    FROM documents d
    LEFT JOIN document_items di ON d.id = di.document_id
    GROUP BY d.id
    ORDER BY d.document_date DESC
`, [], (err, docs) => {
    if (err) {
        console.error('Error querying documents:', err.message);
        return;
    }
    
    console.log('\n=== DOCUMENT DATE ANALYSIS ===');
    console.log(`Total documents: ${docs.length}`);
    
    if (docs.length > 0) {
        const now = new Date();
        const thisMonth = {
            start: new Date(now.getFullYear(), now.getMonth(), 1),
            end: new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59)
        };
        
        const today = {
            start: new Date(now.getFullYear(), now.getMonth(), now.getDate()),
            end: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
        };
        
        console.log(`\nCurrent date: ${now.toISOString()}`);
        console.log(`This month period: ${thisMonth.start.toISOString()} to ${thisMonth.end.toISOString()}`);
        console.log(`Today period: ${today.start.toISOString()} to ${today.end.toISOString()}`);
        
        docs.forEach(doc => {
            const docDate = new Date(doc.document_date);
            const inThisMonth = docDate >= thisMonth.start && docDate <= thisMonth.end;
            const inToday = docDate >= today.start && docDate <= today.end;
            
            console.log(`\nDocument ${doc.id}:`);
            console.log(`  Date: ${doc.document_date} (parsed: ${docDate.toISOString()})`);
            console.log(`  Type: ${doc.type}`);
            console.log(`  Total: R$ ${doc.total_amount || 0}`);
            console.log(`  In This Month: ${inThisMonth}`);
            console.log(`  In Today: ${inToday}`);
        });
        
        // Test period filtering
        console.log('\n=== PERIOD FILTERING TEST ===');
        
        const thisMonthDocs = docs.filter(doc => {
            const docDate = new Date(doc.document_date);
            return docDate >= thisMonth.start && docDate <= thisMonth.end;
        });
        
        const todayDocs = docs.filter(doc => {
            const docDate = new Date(doc.document_date);
            return docDate >= today.start && docDate <= today.end;
        });
        
        const allDocs = docs; // All period
        
        console.log(`Documents in "This Month": ${thisMonthDocs.length}`);
        console.log(`Documents in "Today": ${todayDocs.length}`);
        console.log(`Documents in "All": ${allDocs.length}`);
        
        // Calculate balance for this month
        if (thisMonthDocs.length > 0) {
            const inflows = thisMonthDocs.filter(d => d.type === 'purchase').reduce((sum, d) => sum + (d.total_amount || 0), 0);
            const outflows = thisMonthDocs.filter(d => d.type === 'sale').reduce((sum, d) => sum + (d.total_amount || 0), 0);
            const balance = inflows - outflows;
            
            console.log(`\nThis Month Balance:`);
            console.log(`  Inflows: R$ ${inflows.toFixed(2)}`);
            console.log(`  Outflows: R$ ${outflows.toFixed(2)}`);
            console.log(`  Balance: R$ ${balance.toFixed(2)}`);
        }
    }
    
    db.close();
});
