const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const path = require('path');

const API_BASE = 'http://localhost:3000/api';

async function testImageUrls() {
    console.log('=== Testing Image URL Construction ===');
    
    try {
        // 1. Login
        console.log('1. Logging in...');        const loginResponse = await axios.post(`${API_BASE}/auth/login`, {
            email: 'test@example.com',
            password: 'password123'
        });
        
        const token = loginResponse.data.token;
        console.log('Login successful! Token obtained.');
        
        // 2. Get stores
        console.log('2. Getting stores...');
        const storesResponse = await axios.get(`${API_BASE}/stores`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        
        if (storesResponse.data.data.length === 0) {
            console.log('No stores found. Please run create_test_store.js first.');
            return;
        }
        
        const storeId = storesResponse.data.data[0].id;
        console.log(`Using store ID: ${storeId}`);
        
        // 3. Get stock items to see current imageUrl format
        console.log('3. Getting stock items to check imageUrl format...');
        const stockResponse = await axios.get(`${API_BASE}/stores/${storeId}/stock`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        
        console.log('Stock items with imageUrl format:');
        stockResponse.data.data.forEach((item, index) => {
            console.log(`  Item ${index + 1}: ${item.name}`);
            console.log(`    ID: ${item.id}`);
            console.log(`    ImageUrl: ${item.imageUrl || 'null'}`);
        });
        
        // 4. Create a test image file (1x1 pixel PNG)
        console.log('4. Creating a test PNG image...');
        const testImagePath = path.join(__dirname, 'test-image.png');
        
        // Create a minimal 1x1 PNG file
        const pngData = Buffer.from([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
            0x49, 0x48, 0x44, 0x52, // IHDR
            0x00, 0x00, 0x00, 0x01, // width: 1
            0x00, 0x00, 0x00, 0x01, // height: 1
            0x08, 0x02, 0x00, 0x00, 0x00, // bit depth, color type, compression, filter, interlace
            0x90, 0x77, 0x53, 0xDE, // CRC
            0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
            0x49, 0x44, 0x41, 0x54, // IDAT
            0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x82, 0x20, 0x81, 0x00, // IDAT data
            0x8E, 0x7F, 0x26, 0x49, // CRC
            0x00, 0x00, 0x00, 0x00, // IEND chunk length
            0x49, 0x45, 0x4E, 0x44, // IEND
            0xAE, 0x42, 0x60, 0x82  // CRC
        ]);
        
        fs.writeFileSync(testImagePath, pngData);
        
        // 5. Upload image to a stock item
        if (stockResponse.data.data.length > 0) {
            const itemId = stockResponse.data.data[0].id;
            console.log(`5. Uploading image to item ID: ${itemId}...`);
            
            const formData = new FormData();
            formData.append('image', fs.createReadStream(testImagePath));
            
            const uploadResponse = await axios.post(
                `${API_BASE}/stores/${storeId}/stock/${itemId}/image`,
                formData,
                {
                    headers: {
                        Authorization: `Bearer ${token}`,
                        ...formData.getHeaders()
                    }
                }
            );
            
            console.log('Upload Status:', uploadResponse.status);
            console.log('Upload Response:', JSON.stringify(uploadResponse.data, null, 2));
            
            // 6. Get the updated item to see the new imageUrl
            console.log('6. Getting updated item to verify imageUrl...');
            const updatedStockResponse = await axios.get(`${API_BASE}/stores/${storeId}/stock`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            const updatedItem = updatedStockResponse.data.data.find(item => item.id === itemId);
            console.log('\\n=== URL VERIFICATION ===');
            console.log(`Item ID: ${updatedItem.id}`);
            console.log(`Item Name: ${updatedItem.name}`);
            console.log(`New ImageUrl: ${updatedItem.imageUrl}`);
            
            if (updatedItem.imageUrl) {
                if (updatedItem.imageUrl.includes('10.0.2.2:3000')) {
                    console.log('✅ SUCCESS: Image URL correctly uses Android emulator address (10.0.2.2:3000)');
                } else if (updatedItem.imageUrl.includes('localhost:3000')) {
                    console.log('⚠️  WARNING: Image URL still uses localhost:3000 (may not work on Android emulator)');
                } else {
                    console.log(`⚠️  INFO: Image URL uses different address: ${updatedItem.imageUrl}`);
                }
            }
        }
        
        // Cleanup
        if (fs.existsSync(testImagePath)) {
            fs.unlinkSync(testImagePath);
            console.log('Test image cleaned up.');
        }
        
        console.log('\\n=== Test completed ===');
        
    } catch (error) {
        console.error('Error during test:', error.response?.data || error.message);
    }
}

testImageUrls();
