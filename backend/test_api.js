const axios = require('axios');

async function testDocumentsAPI() {
    try {
        console.log('🧪 Testing Documents API...');
        
        // Test documents endpoint
        const response = await axios.get('http://localhost:3000/api/stores/1/documents');
        
        console.log('📊 Response Status:', response.status);
        console.log('📋 Documents Count:', response.data.data.length);
        
        if (response.data.data.length > 0) {
            console.log('\n📄 Sample Document:');
            const doc = response.data.data[0];
            console.log(JSON.stringify(doc, null, 2));
            
            console.log('\n🔍 Field Analysis:');
            console.log('- ID:', doc.id);
            console.log('- Type:', doc.type);
            console.log('- Date:', doc.document_date);
            console.log('- Total Amount:', doc.total_amount);
            console.log('- Store ID:', doc.store_id);
            console.log('- Notes:', doc.notes);
        }
        
    } catch (error) {
        console.error('❌ Error testing API:', error.response?.data || error.message);
    }
}

testDocumentsAPI();
