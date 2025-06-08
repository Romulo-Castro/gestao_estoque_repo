// Clean Architecture Stock Routes
const express = require('express');
const upload = require('../../../middleware/uploadMiddleware');
const { validateStockItem, validateIdParam, handleValidationErrors } = require('../../../middleware/validators');

const createStockRoutes = (container) => {
    const router = express.Router({ mergeParams: true });
    const stockController = container.get('stockController');

    // GET /api/stores/:storeId/stock - Get all stock items
    router.get('/', (req, res, next) => stockController.getAllStockItems(req, res, next));

    // POST /api/stores/:storeId/stock - Create new stock item
    router.post('/',
        validateStockItem(),
        handleValidationErrors,
        (req, res, next) => stockController.createStockItem(req, res, next)
    );

    // GET /api/stores/:storeId/stock/:itemId - Get stock item by ID
    router.get('/:itemId',
        validateIdParam('itemId'),
        handleValidationErrors,
        (req, res, next) => stockController.getStockItemById(req, res, next)
    );

    // PUT /api/stores/:storeId/stock/:itemId - Update stock item
    router.put('/:itemId',
        validateIdParam('itemId'),
        validateStockItem(),
        handleValidationErrors,
        (req, res, next) => stockController.updateStockItem(req, res, next)
    );

    // DELETE /api/stores/:storeId/stock/:itemId - Delete stock item
    router.delete('/:itemId',
        validateIdParam('itemId'),
        handleValidationErrors,
        (req, res, next) => stockController.deleteStockItem(req, res, next)
    );

    // POST /api/stores/:storeId/stock/:itemId/image - Upload stock item image
    router.post('/:itemId/image',
        validateIdParam('itemId'),
        handleValidationErrors,
        upload.single('productImage'),
        (req, res, next) => stockController.uploadStockItemImage(req, res, next)
    );

    // DELETE /api/stores/:storeId/stock/:itemId/image - Delete stock item image
    router.delete('/:itemId/image',
        validateIdParam('itemId'),
        handleValidationErrors,
        (req, res, next) => stockController.deleteStockItemImage(req, res, next)
    );

    return router;
};

module.exports = { createStockRoutes };
