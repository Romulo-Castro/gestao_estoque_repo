// src/routes/customerRoutes.js
const express = require("express");
const customerController = require("../controllers/customerController");
const { validateCustomer, validateIdParam, handleValidationErrors } = require("../middleware/validators");

// Usar mergeParams para acessar :storeId da rota pai (storeRoutes)
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Clientes dentro de uma Loja
router.get("/", customerController.getAllCustomers);
router.post("/", 
    validateCustomer(), 
    handleValidationErrors, 
    customerController.createCustomer
);
router.get("/:customerId", 
    validateIdParam('customerId'),
    handleValidationErrors,
    customerController.getCustomerById
);
router.put("/:customerId", 
    validateIdParam('customerId'),
    validateCustomer(), 
    handleValidationErrors, 
    customerController.updateCustomer
);
router.delete("/:customerId", 
    validateIdParam('customerId'),
    handleValidationErrors,
    customerController.deleteCustomer
);

module.exports = router;

