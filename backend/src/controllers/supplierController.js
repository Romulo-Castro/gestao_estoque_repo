// src/controllers/supplierController.js
const db = require("../data/database");

// Import centralized error handling utilities
const { 
    catchAsync, 
    validateId, 
    notFound, 
    AppError,
    sendSuccessResponse 
} = require('../utils/errorHandler');

// GET /api/stores/:storeId/suppliers - Listar fornecedores da loja
exports.getAllSuppliers = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    const suppliers = await db.findSuppliersByStore(storeId);
    sendSuccessResponse(res, suppliers, 'Fornecedores carregados com sucesso');
});

// GET /api/stores/:storeId/suppliers/:supplierId - Obter fornecedor por ID
exports.getSupplierById = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const supplierId = validateId(req.params.supplierId, 'ID do fornecedor');

    const supplier = await db.findSupplierByIdAndStore(supplierId, storeId);
    if (!supplier) {
        return notFound('Fornecedor nesta loja');
    }
    
    sendSuccessResponse(res, supplier, 'Fornecedor encontrado com sucesso');
});

// POST /api/stores/:storeId/suppliers - Criar novo fornecedor
exports.createSupplier = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const { name, email, phone, address, notes } = req.body;

    if (!name || name.trim() === "") {
        throw new AppError('Nome do fornecedor é obrigatório.', 400);
    }

    const result = await db.createSupplierInStore({
        storeId,
        name: name.trim(),
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        address: address?.trim() || null,
        notes: notes?.trim() || null,
    });
    
    const newSupplier = await db.findSupplierByIdAndStore(result.lastID, storeId);
    if (!newSupplier) {
        throw new AppError('Erro ao buscar fornecedor após criação.', 500);
    }
    
    sendSuccessResponse(res, newSupplier, 'Fornecedor criado com sucesso', 201);
});

// PUT /api/stores/:storeId/suppliers/:supplierId - Atualizar fornecedor
exports.updateSupplier = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const supplierId = validateId(req.params.supplierId, 'ID do fornecedor');
    const { name, email, phone, address, notes } = req.body;

    if (!name || name.trim() === "") {
        throw new AppError('Nome do fornecedor é obrigatório.', 400);
    }

    const existingSupplier = await db.findSupplierByIdAndStore(supplierId, storeId);
    if (!existingSupplier) {
        return notFound('Fornecedor nesta loja');
    }

    const result = await db.updateSupplierDetails(supplierId, storeId, {
        name: name.trim(),
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        address: address?.trim() || null,
        notes: notes?.trim() || null,
    });

    const updatedSupplier = await db.findSupplierByIdAndStore(supplierId, storeId);
    if (!updatedSupplier) {
        throw new AppError('Erro ao buscar fornecedor após atualização.', 500);
    }
    
    sendSuccessResponse(res, updatedSupplier, 'Fornecedor atualizado com sucesso');
});

// DELETE /api/stores/:storeId/suppliers/:supplierId - Deletar fornecedor
exports.deleteSupplier = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const supplierId = validateId(req.params.supplierId, 'ID do fornecedor');

    const existingSupplier = await db.findSupplierByIdAndStore(supplierId, storeId);
    if (!existingSupplier) {
        return notFound('Fornecedor nesta loja');
    }

    // A constraint ON DELETE SET NULL cuidará dos documentos
    const result = await db.deleteSupplierFromStore(supplierId, storeId);

    if (result.changes > 0) {
        sendSuccessResponse(res, null, 'Fornecedor excluído com sucesso');
    } else {
        return notFound('Fornecedor');
    }
});

