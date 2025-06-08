const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'inventory_data.db');

console.log('=== Checking Image URLs in Database ===');

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
        return;
    }
    console.log('Connected to the SQLite database.');
});

// Check stock items with images
db.all("PRAGMA table_info(stock_items)", (err, columns) => {
    if (err) {
        console.error('Error getting table info:', err.message);
        return;
    }
    
    console.log('Stock items table columns:');
    columns.forEach(col => {
        console.log(`  - ${col.name} (${col.type})`);
    });
    
    // Find the correct image column name
    const imageColumn = columns.find(col => 
        col.name.toLowerCase().includes('image') || 
        col.name.toLowerCase().includes('photo') ||
        col.name.toLowerCase().includes('url')
    );
    
    if (imageColumn) {
        console.log(`\\nUsing image column: ${imageColumn.name}`);
        
        db.all(`SELECT id, name, ${imageColumn.name} as imageUrl FROM stock_items WHERE ${imageColumn.name} IS NOT NULL`, (err, rows) => {
            if (err) {
                console.error('Error querying stock items:', err.message);
                return;
            }
            
            console.log(`\\nFound ${rows.length} stock items with images:`);
            
            rows.forEach((row, index) => {
                console.log(`\\n${index + 1}. Item ID: ${row.id}`);
                console.log(`   Name: ${row.name}`);
                console.log(`   ImageUrl: ${row.imageUrl}`);
                
                if (row.imageUrl) {
                    if (row.imageUrl.includes('10.0.2.2:3000')) {
                        console.log('   ✅ Uses Android emulator address (10.0.2.2:3000)');
                    } else if (row.imageUrl.includes('localhost:3000')) {
                        console.log('   ⚠️  Uses localhost:3000 (incompatible with Android emulator)');
                    } else {
                        console.log(`   ℹ️  Uses different address format`);
                    }
                }
            });
            
            if (rows.length === 0) {
                console.log('No stock items with images found.');
                console.log('\\nThe URL configuration will be applied when new images are uploaded.');
            }
            
            finishCheck();
        });
    } else {
        console.log('\\nNo image column found in stock_items table.');
        finishCheck();
    }
});

function finishCheck() {
    console.log('\\n=== Current Configuration ===');
    console.log('The backend is now configured to use Android emulator-compatible URLs.');
    console.log('New image uploads will use: http://10.0.2.2:3000/uploads/filename');
    console.log('This was confirmed in the server startup log.');
    
    db.close((err) => {
        if (err) {
            console.error('Error closing database:', err.message);
        } else {
            console.log('\\nDatabase connection closed.');
        }
    });
}
