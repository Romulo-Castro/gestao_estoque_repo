// src/routes/supplierRoutes.js
const express = require("express");
const supplierController = require("../controllers/supplierController");
const { validateSupplier, validateIdParam, handleValidationErrors } = require("../middleware/validators");

// Usar mergeParams para acessar :storeId da rota pai (storeRoutes)
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Fornecedores dentro de uma Loja
router.get("/", supplierController.getAllSuppliers);
router.post("/", 
    validateSupplier(), 
    handleValidationErrors, 
    supplierController.createSupplier
);
router.get("/:supplierId", 
    validateIdParam('supplierId'),
    handleValidationErrors,
    supplierController.getSupplierById
);
router.put("/:supplierId", 
    validateIdParam('supplierId'),
    validateSupplier(), 
    handleValidationErrors, 
    supplierController.updateSupplier
);
router.delete("/:supplierId", 
    validateIdParam('supplierId'),
    handleValidationErrors,
    supplierController.deleteSupplier
);

module.exports = router;

