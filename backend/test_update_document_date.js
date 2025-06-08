const db = require('./src/data/database');
const documentController = require('./src/controllers/documentController');

async function runTest() {
  try {
    await db.connectDb();
    await db.createTables();

    // Create sample store
    const storeRes = await db.createStoreDB({ name: 'Date Test Store', address: 'Test Ave' });
    const storeId = storeRes.lastID;

    // Create stock item
    const itemRes = await db.createStockItemInStore({ storeId, name: 'Sample Item', quantity: 50 });
    const itemId = itemRes.lastID;

    // Create a document
    const docRes = await db.createDocumentHeader({
      storeId,
      type: 'purchase',
      date: '2024-01-01',
      customerId: null,
      supplierId: null,
      notes: 'initial',
      totalAmount: 0
    });
    const documentId = docRes.lastID;
    await db.createDocumentItem({ documentId, itemId, quantity: 5, unitPrice: 1 });

    // Prepare mock request/response
    const req = {
      params: { storeId: storeId.toString(), documentId: documentId.toString() },
      body: { document_date: '2024-02-01' }
    };
    const res = {
      statusCode: 0,
      status(code) { this.statusCode = code; return this; },
      json(data) { console.log('Response:', JSON.stringify(data)); }
    };
    const next = (err) => { if (err) console.error('Error:', err); };

    // Run update
    documentController.updateDocumentHeader(req, res, next);
    await new Promise(r => setTimeout(r, 100));

    const updated = await db.findDocumentByIdAndStore(documentId, storeId);
    console.log('Updated document_date:', updated.document_date);
    console.log('==end==');
  } catch (e) {
    console.error('Test failed:', e);
  }
}

runTest();
