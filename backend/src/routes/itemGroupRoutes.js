// src/routes/itemGroupRoutes.js
const express = require("express");
const itemGroupController = require("../controllers/itemGroupController");
const { validateItemGroup, validateIdParam, handleValidationErrors } = require("../middleware/validators");

// Usar mergeParams é crucial aqui porque este router será montado sob /stores/:storeId
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Grupos de Itens dentro de uma Loja
router.get("/", itemGroupController.getAllGroups);
router.post("/", 
    validateItemGroup(),
    handleValidationErrors,
    itemGroupController.createGroup
);
router.get("/:groupId", 
    validateIdParam('groupId'),
    handleValidationErrors,
    itemGroupController.getGroupById
);
router.put("/:groupId", 
    validateIdParam('groupId'),
    validateItemGroup(),
    handleValidationErrors,
    itemGroupController.updateGroup
);
router.delete("/:groupId", 
    validateIdParam('groupId'),
    handleValidationErrors,
    itemGroupController.deleteGroup
);

module.exports = router;

