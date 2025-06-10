// src/controllers/storeController.js
const db = require('../data/database');

// Import centralized error handling utilities
const { 
    catchAsync, 
    validateId, 
    notFound, 
    AppError,
    sendSuccessResponse,
    unauthorized,
    forbidden
} = require('../utils/errorHandler');

// Middleware para verificar acesso (re-exportado ou usado aqui)
// É mais comum colocar no middleware/authMiddleware.js, mas pode ficar aqui se for só para lojas.
exports.checkStoreAccessMiddleware = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const userId = req.user?.userId;
    
    if (!userId) {
        return unauthorized('Usuário não autenticado');
    }

    const roleInfo = await db.findUserStoreRoleDB(userId, storeId);
    if (!roleInfo) {
        return forbidden('Acesso negado a esta loja');
    }

    req.userStoreRole = roleInfo.role; // Adiciona role para uso futuro
    next();
});

// GET /api/stores - Listar lojas do usuário
exports.getUserStores = catchAsync(async (req, res, next) => {
    const userId = req.user?.userId;
    if (!userId) {
        return unauthorized('Usuário não autenticado');
    }
    
    const stores = await db.findStoresByUserIdDB(userId);
    sendSuccessResponse(res, stores, 'Lojas carregadas com sucesso');
});

// POST /api/stores - Criar nova loja
exports.createStore = catchAsync(async (req, res, next) => {
    const userId = req.user?.userId;
    if (!userId) {
        return unauthorized('Usuário não autenticado');
    }
    
    const { name, address } = req.body;
    if (!name || name.trim() === '') {
        throw new AppError('Nome da loja é obrigatório.', 400);
    }

    // Usar transação para garantir consistência
    try {
        // Iniciar transação
        await db.beginTransaction();
        
        const storeResult = await db.createStoreDB({ name: name.trim(), address: address?.trim() });
        const storeId = storeResult.lastID;

        // Adiciona o criador como 'owner' da loja
        await db.addUserToStoreDB({ userId, storeId, role: 'owner' });
        
        // Confirmar transação
        await db.commitTransaction();

        const newStore = await db.findStoreByIdDB(storeId); // Busca para retornar
        if (!newStore) {
            throw new AppError('Erro ao buscar loja após criação.', 500);
        }
        
        sendSuccessResponse(res, newStore, 'Loja criada com sucesso', 201);

    } catch (error) {
        // Desfazer transação em caso de erro
        await db.rollbackTransaction();
        throw error;
    }
});

// GET /api/stores/:storeId - Obter detalhes (acesso já verificado pelo middleware)
exports.getStoreById = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    const store = await db.findStoreByIdDB(storeId);
    if (!store) {
        return notFound('Loja');
    }
    
    sendSuccessResponse(res, store, 'Loja encontrada com sucesso');
});

// PUT /api/stores/:storeId - Atualizar loja (acesso já verificado)
exports.updateStore = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const { name, address } = req.body;
    
    // Adicionar verificação se é owner/manager para permitir update?
    // if (req.userStoreRole !== 'owner' && req.userStoreRole !== 'manager') {
    //    return forbidden('Permissão insuficiente para editar loja');
    // }
    
    if (!name || name.trim() === '') {
        throw new AppError('Nome da loja é obrigatório.', 400);
    }

    const result = await db.updateStoreDB(storeId, { name: name.trim(), address: address?.trim() });
    if (result.changes === 0) {
        return notFound('Loja');
    }

    const updatedStore = await db.findStoreByIdDB(storeId);
    if (!updatedStore) {
        throw new AppError('Erro ao buscar loja após atualização.', 500);
    }
    
    sendSuccessResponse(res, updatedStore, 'Loja atualizada com sucesso');
});

// DELETE /api/stores/:storeId - Deletar loja (acesso já verificado)
exports.deleteStore = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    // Verificação de segurança adicional: apenas owner pode deletar
    if (req.userStoreRole !== 'owner') {
        return forbidden('Apenas o proprietário pode excluir a loja');
    }

    try {
        // Iniciar transação para garantir consistência
        await db.beginTransaction();
        
        // CUIDADO: ON DELETE CASCADE removerá tudo relacionado à loja
        // Isso inclui: itens, grupos, clientes, fornecedores, documentos, etc.
        const result = await db.deleteStoreDB(storeId);
        
        if (result.changes === 0) {
            await db.rollbackTransaction();
            return notFound('Loja');
        }

        // Confirmar transação
        await db.commitTransaction();
        
        sendSuccessResponse(res, null, 'Loja e todos os seus dados foram excluídos com sucesso');
    } catch (error) {
        // Desfazer transação em caso de erro
        await db.rollbackTransaction();
        throw error;
    }
});