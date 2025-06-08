// src/routes/documentRoutes.js
const express = require("express");
const documentController = require("../controllers/documentController");
const { validateDocument, validateDocumentHeaderUpdate, validateIdParam, handleValidationErrors } = require("../middleware/validators");

// Usar mergeParams para acessar :storeId da rota pai (storeRoutes)
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Documentos dentro de uma Loja
router.get("/", documentController.getAllDocuments);
router.post("/", validateDocument(), handleValidationErrors, documentController.createDocument);
router.get("/:documentId", validateIdParam('documentId'), handleValidationErrors, documentController.getDocumentById);

// PUT - Atualizar cabeçalho (limitado)
router.put("/:documentId", validateIdParam('documentId'), validateDocumentHeaderUpdate(), handleValidationErrors, documentController.updateDocumentHeader);

// DELETE - Cancelar documento (reverte estoque)
router.delete("/:documentId", validateIdParam('documentId'), handleValidationErrors, documentController.cancelDocument);

/**
 * Note: Individual document item routes are intentionally not implemented.
 * Document items are managed as part of the main document operations for data consistency:
 * - Items are created/updated during document creation/update
 * - Individual item modifications could break document integrity
 * - Stock movements are tied to complete document operations
 * 
 * If needed in the future, consider:
 * - POST /:documentId/items - Add item (requires recalculating totals)
 * - DELETE /:documentId/items/:itemId - Remove item (requires stock adjustment)
 */

module.exports = router;

