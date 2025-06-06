// src/controllers/customerController.js
const db = require("../data/database");

// Import centralized error handling utilities
const { 
    catchAsync, 
    validateId, 
    notFound, 
    AppError,
    sendSuccessResponse 
} = require('../utils/errorHandler');

// GET /api/stores/:storeId/customers - Listar clientes da loja
exports.getAllCustomers = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    const customers = await db.findCustomersByStore(storeId);
    sendSuccessResponse(res, customers, 'Clientes carregados com sucesso');
});

// GET /api/stores/:storeId/customers/:customerId - Obter cliente por ID
exports.getCustomerById = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const customerId = validateId(req.params.customerId, 'ID do cliente');

    const customer = await db.findCustomerByIdAndStore(customerId, storeId);
    if (!customer) {
        return notFound('Cliente nesta loja');
    }
    
    sendSuccessResponse(res, customer, 'Cliente encontrado com sucesso');
});

// POST /api/stores/:storeId/customers - Criar novo cliente
exports.createCustomer = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const { name, email, phone, address, notes } = req.body;

    if (!name || name.trim() === "") {
        throw new AppError('Nome do cliente é obrigatório.', 400);
    }

    const result = await db.createCustomerInStore({
        storeId,
        name: name.trim(),
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        address: address?.trim() || null,
        notes: notes?.trim() || null,
    });
    
    const newCustomer = await db.findCustomerByIdAndStore(result.lastID, storeId);
    if (!newCustomer) {
        throw new AppError('Erro ao buscar cliente após criação.', 500);
    }
    
    sendSuccessResponse(res, newCustomer, 'Cliente criado com sucesso', 201);
});

// PUT /api/stores/:storeId/customers/:customerId - Atualizar cliente
exports.updateCustomer = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const customerId = validateId(req.params.customerId, 'ID do cliente');
    const { name, email, phone, address, notes } = req.body;

    if (!name || name.trim() === "") {
        throw new AppError('Nome do cliente é obrigatório.', 400);
    }

    // Verificar se cliente existe na loja antes de atualizar
    const existingCustomer = await db.findCustomerByIdAndStore(customerId, storeId);
    if (!existingCustomer) {
        return notFound('Cliente nesta loja');
    }

    const result = await db.updateCustomerDetails(customerId, storeId, {
        name: name.trim(),
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        address: address?.trim() || null,
        notes: notes?.trim() || null,
    });

    const updatedCustomer = await db.findCustomerByIdAndStore(customerId, storeId);
    if (!updatedCustomer) {
        throw new AppError('Erro ao buscar cliente após atualização.', 500);
    }
    
    sendSuccessResponse(res, updatedCustomer, 'Cliente atualizado com sucesso');
});

// DELETE /api/stores/:storeId/customers/:customerId - Deletar cliente
exports.deleteCustomer = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const customerId = validateId(req.params.customerId, 'ID do cliente');

    // Verificar se cliente existe
    const existingCustomer = await db.findCustomerByIdAndStore(customerId, storeId);
    if (!existingCustomer) {
        return notFound('Cliente nesta loja');
    }

    // A constraint ON DELETE SET NULL cuidará dos documentos
    const result = await db.deleteCustomerFromStore(customerId, storeId);

    if (result.changes > 0) {
        sendSuccessResponse(res, null, 'Cliente excluído com sucesso');
    } else {
        return notFound('Cliente');
    }
});

