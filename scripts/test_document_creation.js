// Test script to verify document creation functionality with authentication
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

// Test user data
const testUser = {
    name: 'Test User',
    email: 'test@example.com',
    password: 'test123'
};

let authToken = '';
let storeId = null;

async function registerAndLoginUser() {
    try {
        console.log('👤 Creating test user...');
        
        // Try to register the user (may fail if already exists)
        try {
            await axios.post(`${BASE_URL}/auth/register`, testUser);
            console.log('✅ Test user created successfully');
        } catch (error) {
            if (error.response?.status === 400 && error.response?.data?.message?.includes('já existe')) {
                console.log('ℹ️ Test user already exists, proceeding with login');
            } else {
                throw error;
            }
        }

        // Login to get token
        console.log('🔐 Logging in...');
        const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
            email: testUser.email,
            password: testUser.password
        });

        authToken = loginResponse.data.token;
        console.log('✅ Login successful');
        return true;

    } catch (error) {
        console.error('❌ Authentication failed:', error.response?.data?.message || error.message);
        return false;
    }
}

async function setupTestStore() {
    try {
        console.log('🏪 Setting up test store...');
        
        // Get existing stores
        const storesResponse = await axios.get(`${BASE_URL}/stores`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });

        if (storesResponse.data.length > 0) {
            storeId = storesResponse.data[0].id;
            console.log(`✅ Using existing store: ${storesResponse.data[0].name} (ID: ${storeId})`);
        } else {
            // Create a test store
            const createStoreResponse = await axios.post(`${BASE_URL}/stores`, {
                name: 'Test Store',
                address: 'Test Address'
            }, {
                headers: { Authorization: `Bearer ${authToken}` }
            });
            storeId = createStoreResponse.data.id;
            console.log(`✅ Created test store (ID: ${storeId})`);
        }

        return true;
    } catch (error) {
        console.error('❌ Store setup failed:', error.response?.data?.message || error.message);
        return false;
    }
}

async function setupTestItems() {
    try {
        console.log('📦 Setting up test items...');
        
        // Get existing items
        const itemsResponse = await axios.get(`${BASE_URL}/stores/${storeId}/stock`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });

        if (itemsResponse.data.length > 0) {
            console.log(`✅ Found ${itemsResponse.data.length} existing items`);
            return itemsResponse.data[0]; // Return first item for testing
        } else {
            // Create a test item
            const createItemResponse = await axios.post(`${BASE_URL}/stores/${storeId}/stock`, {
                name: 'Test Item',
                quantity: 10,
                properties: {
                    unit: 'units',
                    price: 15.00
                }
            }, {
                headers: { Authorization: `Bearer ${authToken}` }
            });
            console.log(`✅ Created test item (ID: ${createItemResponse.data.id})`);
            return createItemResponse.data;
        }
    } catch (error) {
        console.error('❌ Item setup failed:', error.response?.data?.message || error.message);
        return null;
    }
}

async function testDocumentCreation() {
    try {
        console.log('🧪 Testing Document Creation with Stock Integration...\n');

        // Step 1: Authenticate
        const authSuccess = await registerAndLoginUser();
        if (!authSuccess) {
            throw new Error('Authentication failed');
        }

        // Step 2: Setup store
        const storeSuccess = await setupTestStore();
        if (!storeSuccess) {
            throw new Error('Store setup failed');
        }

        // Step 3: Setup test items
        const testItem = await setupTestItems();
        if (!testItem) {
            throw new Error('Item setup failed');
        }

        console.log('');

        // Step 4: Test document creation
        const testDocument = {
            type: 'entrada', // Using the correct Portuguese type
            storeId: storeId,
            supplierId: null, // We'll create without supplier for simplicity
            notes: 'Test document creation via API',
            items: [
                {
                    itemId: testItem.id,
                    quantity: 5,
                    price: 10.50
                }
            ]
        };

        console.log('📝 Test Document:', JSON.stringify(testDocument, null, 2));

        // Make request to create document
        const response = await axios.post(
            `${BASE_URL}/stores/${storeId}/documents`,
            testDocument,
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${authToken}`
                }
            }
        );

        console.log('✅ Document created successfully!');
        console.log('📄 Created Document:', JSON.stringify(response.data, null, 2));

        // Step 5: Verify stock update
        console.log('\n📦 Verifying stock update...');
        const updatedItemResponse = await axios.get(`${BASE_URL}/stores/${storeId}/stock`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        
        const updatedItem = updatedItemResponse.data.find(item => item.id === testItem.id);
        if (updatedItem) {
            console.log(`✅ Stock updated: ${testItem.quantity} → ${updatedItem.quantity} (Change: +${updatedItem.quantity - testItem.quantity})`);
        }

        return response.data;    } catch (error) {
        console.error('❌ Error creating document:');
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Error:', error.response.data);
        } else {
            console.error('Error:', error.message);
        }
        throw error;
    }
}

// Run the test if called directly
if (require.main === module) {
    testDocumentCreation()
        .then(() => {
            console.log('\n🎉 Test completed successfully!');
            process.exit(0);
        })
        .catch(() => {
            console.log('\n💥 Test failed!');
            process.exit(1);
        });
}

module.exports = { testDocumentCreation };
