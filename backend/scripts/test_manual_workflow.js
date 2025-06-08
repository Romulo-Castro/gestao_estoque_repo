// Manual Test Script for Document Creation Workflow
// This script tests the complete document creation workflow including:
// 1. Authentication
// 2. Document creation with correct type
// 3. Stock updates
// 4. Balance sheet calculations

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

// Test user credentials - using a default user that should exist
const testCredentials = {
    email: 'test@admin.com',
    password: 'password123'
};

// Let's create a test user first if it doesn't exist
async function createTestUser() {
    try {
        console.log('🔧 Creating test user...');
        const response = await axios.post(`${BASE_URL}/auth/register`, {
            name: 'Test User',
            email: testCredentials.email,
            password: testCredentials.password
        });
        console.log('✅ Test user created successfully');
        return true;
    } catch (error) {
        if (error.response?.status === 400 && error.response?.data?.message?.includes('já existe')) {
            console.log('✅ Test user already exists');
            return true;
        }
        console.log('❌ Failed to create test user:', error.response?.data?.message || error.message);
        return false;
    }
}

let authToken = '';
let storeId = 1;

async function testLogin() {
    try {
        console.log('🔐 Testing login...');
        const response = await axios.post(`${BASE_URL}/auth/login`, testCredentials);
        authToken = response.data.token;
        console.log('✅ Login successful');
        return true;
    } catch (error) {
        console.log('❌ Login failed:', error.response?.data?.message || error.message);
        return false;
    }
}

async function getStockItems() {
    try {
        console.log('📦 Fetching stock items...');
        const response = await axios.get(`${BASE_URL}/stores/${storeId}/stock`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log(`✅ Found ${response.data.length} stock items`);
        return response.data;
    } catch (error) {
        console.log('❌ Failed to fetch stock:', error.response?.data?.message || error.message);
        return [];
    }
}

async function testDocumentCreation(documentType, items) {
    try {
        console.log(`📝 Testing ${documentType} document creation...`);
        
        const documentData = {
            type: documentType,
            storeId: storeId,
            supplierId: documentType === 'entrada' ? 1 : null,
            customerId: documentType === 'saida' ? 1 : null,
            status: 'active',
            notes: `Test ${documentType} document created by manual test`,
            items: items
        };

        const response = await axios.post(`${BASE_URL}/stores/${storeId}/documents`, documentData, {
            headers: { Authorization: `Bearer ${authToken}` }
        });

        console.log(`✅ ${documentType} document created with ID: ${response.data.id}`);
        console.log(`   Total amount: R$ ${response.data.total_amount}`);
        return response.data;
    } catch (error) {
        console.log(`❌ Failed to create ${documentType} document:`, error.response?.data?.message || error.message);
        return null;
    }
}

async function getUpdatedStock(itemId) {
    try {
        const response = await axios.get(`${BASE_URL}/stores/${storeId}/stock`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        const item = response.data.find(item => item.id === itemId);
        return item ? item.quantity : 0;
    } catch (error) {
        console.log('❌ Failed to get updated stock:', error.message);
        return 0;
    }
}

async function testBalanceSheet() {
    try {
        console.log('📊 Testing balance sheet data...');
        
        // Get documents for balance calculations
        const response = await axios.get(`${BASE_URL}/stores/${storeId}/documents`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        
        const documents = response.data;
        console.log(`✅ Found ${documents.length} documents for balance calculations`);
        
        // Calculate totals by type
        const entradas = documents.filter(doc => doc.type === 'entrada' && doc.status === 'active');
        const saidas = documents.filter(doc => doc.type === 'saida' && doc.status === 'active');
        
        const totalEntradas = entradas.reduce((sum, doc) => sum + (doc.total_amount || 0), 0);
        const totalSaidas = saidas.reduce((sum, doc) => sum + (doc.total_amount || 0), 0);
        
        console.log(`📈 Total Entradas: R$ ${totalEntradas.toFixed(2)}`);
        console.log(`📉 Total Saídas: R$ ${totalSaidas.toFixed(2)}`);
        console.log(`💰 Balance: R$ ${(totalEntradas - totalSaidas).toFixed(2)}`);
        
        return true;
    } catch (error) {
        console.log('❌ Failed to test balance sheet:', error.response?.data?.message || error.message);
        return false;
    }
}

async function runTests() {
    console.log('🚀 Starting Manual Workflow Tests\n');
    
    // Test 1: Authentication
    const loginSuccess = await testLogin();
    if (!loginSuccess) {
        console.log('❌ Cannot proceed without authentication');
        return;
    }
    
    console.log('');
    
    // Test 2: Get stock items
    const stockItems = await getStockItems();
    if (stockItems.length === 0) {
        console.log('❌ No stock items found for testing');
        return;
    }
    
    console.log('');
    
    // Test 3: Test entrada (purchase) document
    const testItem = stockItems[0];
    const initialStock = testItem.quantity;
    console.log(`📦 Testing with item: ${testItem.name} (Current stock: ${initialStock})`);
    
    const entradaItems = [{
        itemId: testItem.id,
        quantity: 5,
        price: 10.50
    }];
    
    const entradaDoc = await testDocumentCreation('entrada', entradaItems);
    
    if (entradaDoc) {
        console.log('');
        console.log('📦 Checking stock update after entrada...');
        const newStock = await getUpdatedStock(testItem.id);
        const expectedStock = initialStock + 5;
        
        if (newStock === expectedStock) {
            console.log(`✅ Stock correctly updated: ${initialStock} → ${newStock}`);
        } else {
            console.log(`❌ Stock update failed: Expected ${expectedStock}, got ${newStock}`);
        }
    }
    
    console.log('');
    
    // Test 4: Test saida (sale) document - only if we have stock
    const currentStock = await getUpdatedStock(testItem.id);
    if (currentStock > 0) {
        const saidaItems = [{
            itemId: testItem.id,
            quantity: Math.min(2, currentStock), // Don't exceed available stock
            price: 15.00
        }];
        
        const saidaDoc = await testDocumentCreation('saida', saidaItems);
        
        if (saidaDoc) {
            console.log('');
            console.log('📦 Checking stock update after saida...');
            const finalStock = await getUpdatedStock(testItem.id);
            const expectedFinalStock = currentStock - saidaItems[0].quantity;
            
            if (finalStock === expectedFinalStock) {
                console.log(`✅ Stock correctly updated: ${currentStock} → ${finalStock}`);
            } else {
                console.log(`❌ Stock update failed: Expected ${expectedFinalStock}, got ${finalStock}`);
            }
        }
    } else {
        console.log('⚠️ Skipping saida test - no stock available');
    }
    
    console.log('');
    
    // Test 5: Balance sheet calculations
    await testBalanceSheet();
    
    console.log('\n🎉 Manual workflow tests completed!');
}

// Run the tests
runTests().catch(console.error);
