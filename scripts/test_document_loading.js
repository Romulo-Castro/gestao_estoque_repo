// Test script to verify document loading with items
const path = require('path');
const { connectDb, findDocumentByIdAndStore, findDocumentItemsByDocumentId } = require('../backend/src/data/database.js');

async function testDocumentLoading() {
    try {
        console.log('🔄 Connecting to database...');
        await connectDb();
        
        console.log('📋 Testing document loading with items...');
        
        // First, let's see what documents exist
        const { allQuery } = require('../backend/src/data/database.js');
        const documents = await allQuery('SELECT * FROM documents LIMIT 5');
        
        console.log('\n📄 Available documents:');
        documents.forEach(doc => {
            console.log(`  - Document ID: ${doc.id}, Type: ${doc.type}, Date: ${doc.document_date}, Total: ${doc.total_amount}`);
        });
        
        if (documents.length === 0) {
            console.log('❌ No documents found in database');
            return;
        }
        
        // Test loading the first document with items
        const testDoc = documents[0];
        console.log(`\n🔍 Testing document ID: ${testDoc.id}`);
        
        const documentWithItems = await findDocumentByIdAndStore(testDoc.id, testDoc.store_id);
        console.log('📋 Document details:', documentWithItems);
        
        const items = await findDocumentItemsByDocumentId(testDoc.id);
        console.log('📦 Document items:', items);
        
        console.log('\n📊 Final structure that would be sent to frontend:');
        const finalDocument = {
            ...documentWithItems,
            items: items.map(item => ({
                id: item.id,
                quantity: item.quantity,
                unit_value: item.unit_price,
                total_value: item.quantity * (item.unit_price || 0),
                description: item.item_name || 'Item sem nome',
                stock_item_id: item.item_id
            }))
        };
        
        console.log(JSON.stringify(finalDocument, null, 2));
        
        // Check for any zero values
        const hasZeroValues = items.some(item => 
            item.quantity === 0 || 
            item.unit_price === 0 || 
            (item.quantity * (item.unit_price || 0)) === 0
        );
        
        if (hasZeroValues) {
            console.log('\n⚠️  WARNING: Found items with zero values!');
            items.forEach((item, index) => {
                if (item.quantity === 0 || item.unit_price === 0) {
                    console.log(`  - Item ${index + 1}: quantity=${item.quantity}, unit_price=${item.unit_price}`);
                }
            });
        } else {
            console.log('\n✅ All items have valid non-zero values');
        }
        
    } catch (error) {
        console.error('❌ Error testing document loading:', error);
    }
}

// Run the test
testDocumentLoading();
