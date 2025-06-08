// Clean Architecture Document Routes
const express = require('express');
const { validateDocument, validateDocumentHeaderUpdate, validateIdParam, handleValidationErrors } = require('../../../middleware/validators');

const createDocumentRoutes = (container) => {
    const router = express.Router({ mergeParams: true });
    const documentController = container.get('documentController');

    // GET /api/stores/:storeId/documents - Get all documents
    router.get('/', (req, res, next) => documentController.getAllDocuments(req, res, next));

    // GET /api/stores/:storeId/documents/balance-sheet - Get balance sheet
    router.get('/balance-sheet', (req, res, next) => documentController.getBalanceSheet(req, res, next));

    // GET /api/stores/:storeId/documents/stats - Get document statistics
    router.get('/stats', (req, res, next) => documentController.getDocumentStats(req, res, next));

    // POST /api/stores/:storeId/documents - Create new document (placeholder)
    router.post('/',
        validateDocument(),
        handleValidationErrors,
        (req, res, next) => documentController.createDocument(req, res, next)
    );

    // GET /api/stores/:storeId/documents/:documentId - Get document by ID
    router.get('/:documentId',
        validateIdParam('documentId'),
        handleValidationErrors,
        (req, res, next) => documentController.getDocumentById(req, res, next)
    );

    // PUT /api/stores/:storeId/documents/:documentId - Update document header (placeholder)
    router.put('/:documentId',
        validateIdParam('documentId'),
        validateDocumentHeaderUpdate(),
        handleValidationErrors,
        (req, res, next) => documentController.updateDocumentHeader(req, res, next)
    );

    // DELETE /api/stores/:storeId/documents/:documentId - Cancel document (placeholder)
    router.delete('/:documentId',
        validateIdParam('documentId'),
        handleValidationErrors,
        (req, res, next) => documentController.cancelDocument(req, res, next)
    );

    return router;
};

module.exports = { createDocumentRoutes };
