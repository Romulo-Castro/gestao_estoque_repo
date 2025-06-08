const { connectDb } = require('./src/data/database');
const db = require('./src/data/database');

async function testDocumentData() {
    try {
        await connectDb();
        console.log('🧪 Testing Document Data Mapping...');
        
        // Get documents from database
        const documents = await db.findDocumentsByStore(1);
        
        console.log('📊 Found', documents.length, 'documents');
        
        if (documents.length > 0) {
            console.log('\n📄 Raw Database Document:');
            const doc = documents[0];
            console.log(JSON.stringify(doc, null, 2));
            
            console.log('\n🔄 Expected Frontend Mapping:');
            console.log('- id:', doc.id);
            console.log('- number:', doc.id.toString());
            console.log('- type:', doc.type === 'sale' ? 'saida' : doc.type === 'purchase' ? 'entrada' : doc.type);
            console.log('- date:', doc.document_date);
            console.log('- description:', doc.notes || '');
            console.log('- totalValue:', doc.total_amount || 0);
            console.log('- status: ATIVO');
            console.log('- storeId:', doc.store_id);
            
            console.log('\n📅 Date Analysis:');
            if (doc.document_date) {
                const date = new Date(doc.document_date);
                console.log('- Raw date:', doc.document_date);
                console.log('- Parsed date:', date.toISOString());
                console.log('- Valid date:', !isNaN(date.getTime()));
            } else {
                console.log('- ❌ Date is missing!');
            }
        }
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

testDocumentData();
