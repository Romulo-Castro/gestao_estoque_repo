// src/controllers/itemGroupController.js
const db = require('../data/database');

// Import centralized error handling utilities
const { 
    catchAsync, 
    validateId, 
    notFound, 
    AppError,
    sendSuccessResponse 
} = require('../utils/errorHandler');

// GET /api/stores/:storeId/groups - Listar grupos da loja
exports.getAllGroups = catchAsync(async (req, res, next) => {
    // Acesso à loja já verificado pelo middleware em storeRoutes
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    const groups = await db.findGroupsByStore(storeId);
    sendSuccessResponse(res, groups, 'Grupos carregados com sucesso');
});

// GET /api/stores/:storeId/groups/:groupId - Obter grupo por ID
exports.getGroupById = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const groupId = validateId(req.params.groupId, 'ID do grupo');

    const group = await db.findGroupByIdAndStore(groupId, storeId);
    if (!group) {
        return notFound('Grupo nesta loja');
    }
    
    sendSuccessResponse(res, group, 'Grupo encontrado com sucesso');
});

// POST /api/stores/:storeId/groups - Criar novo grupo
exports.createGroup = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const { name, parent_group_id } = req.body;

    if (!name || name.trim() === '') {
        throw new AppError('Nome do grupo é obrigatório.', 400);
    }

    // TODO: Validar se parent_group_id (se fornecido) pertence à mesma storeId?

    const result = await db.createGroupInStore({
        storeId,
        name: name.trim(),
        parentGroupId: parent_group_id ? parseInt(parent_group_id, 10) : null
    });
    
    const newGroup = await db.findGroupByIdAndStore(result.lastID, storeId);
    if (!newGroup) {
        throw new AppError('Erro ao buscar grupo após criação.', 500);
    }
    
    sendSuccessResponse(res, newGroup, 'Grupo criado com sucesso', 201);
});

// PUT /api/stores/:storeId/groups/:groupId - Atualizar grupo
exports.updateGroup = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const groupId = validateId(req.params.groupId, 'ID do grupo');
    const { name, parent_group_id } = req.body;

    if (!name || name.trim() === '') {
        throw new AppError('Nome do grupo é obrigatório.', 400);
    }
    
    // TODO: Validar se parent_group_id (se fornecido) pertence à mesma storeId e não cria ciclo?

    const existingGroup = await db.findGroupByIdAndStore(groupId, storeId);
    if (!existingGroup) {
        return notFound('Grupo nesta loja');
    }

    const result = await db.updateGroupDetails(groupId, storeId, {
        name: name.trim(),
        parentGroupId: parent_group_id !== undefined ? (parent_group_id ? parseInt(parent_group_id, 10) : null) : existingGroup.parent_group_id
    });

    const updatedGroup = await db.findGroupByIdAndStore(groupId, storeId);
    if (!updatedGroup) {
        throw new AppError('Erro ao buscar grupo após atualização.', 500);
    }
    
    sendSuccessResponse(res, updatedGroup, 'Grupo atualizado com sucesso');
});

// DELETE /api/stores/:storeId/groups/:groupId - Deletar grupo
exports.deleteGroup = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const groupId = validateId(req.params.groupId, 'ID do grupo');

    // Verificar se o grupo existe antes de deletar
    const existingGroup = await db.findGroupByIdAndStore(groupId, storeId);
    if (!existingGroup) {
        return notFound('Grupo nesta loja');
    }

    // A constraint ON DELETE SET NULL cuidará dos itens e subgrupos
    const result = await db.deleteGroupFromStore(groupId, storeId);

    if (result.changes > 0) {
        sendSuccessResponse(res, null, 'Grupo excluído com sucesso');
    } else {
        return notFound('Grupo');
    }
});

