// src/controllers/documentController.js
const db = require("../data/database");

// Import centralized error handling utilities
const { 
    catchAsync, 
    validateId, 
    notFound, 
    AppError,
    sendSuccessResponse 
} = require('../utils/errorHandler');

// GET /api/stores/:storeId/documents - Listar documentos da loja
exports.getAllDocuments = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    // TODO: Adicionar filtros (tipo, data, cliente/fornecedor) via query params
    const documents = await db.findDocumentsByStore(storeId);
    sendSuccessResponse(res, documents, 'Documentos carregados com sucesso');
});

// GET /api/stores/:storeId/documents/:documentId - Obter documento por ID com itens
exports.getDocumentById = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const documentId = validateId(req.params.documentId, 'ID do documento');

    const document = await db.findDocumentByIdAndStore(documentId, storeId);
    if (!document) {
        return notFound('Documento nesta loja');
    }
    
    const items = await db.findDocumentItemsByDocumentId(documentId);
    const documentWithItems = { ...document, items };
    
    sendSuccessResponse(res, documentWithItems, 'Documento encontrado com sucesso');
});

// POST /api/stores/:storeId/documents - Criar novo documento com itens
exports.createDocument = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const { type, document_date, customerId, supplierId, notes, items, total_amount } = req.body;

    // Validações básicas - aceita tipos em inglês conforme o banco de dados
    if (!["sale", "purchase", "adjustment_in", "adjustment_out"].includes(type)) {
        throw new AppError('Tipo de documento inválido. Use: sale, purchase, adjustment_in ou adjustment_out', 400);
    }
    
    if (!document_date) {
        throw new AppError('Data do documento é obrigatória.', 400);
    }
    
    if (!items || !Array.isArray(items) || items.length === 0) {
        throw new AppError('Documento deve ter pelo menos um item.', 400);
    }

    // TODO: Validar se customerId/supplierId existem na loja, se fornecidos

    try {
        await db.beginTransaction();

        // 1. Criar o cabeçalho do documento
        const docResult = await db.createDocumentHeader({
            storeId,
            type,
            date: document_date,
            customerId: customerId || null,
            supplierId: supplierId || null,
            notes: notes?.trim() || null,
            totalAmount: total_amount || 0
        });
        const documentId = docResult.lastID;

        // 2. Criar os itens do documento e ajustar estoque
        for (const item of items) {
            // Aceita tanto itemId quanto item_id para compatibilidade
            const itemId = item.itemId || item.item_id;
            const itemQuantity = item.quantity;
            
            if (!itemId || !itemQuantity || itemQuantity <= 0) {
                throw new AppError('Item inválido no documento: ID e quantidade positiva são obrigatórios.', 400);
            }
            // TODO: Validar se itemId existe na loja

            await db.createDocumentItem({
                documentId,
                itemId: item.itemId,
                quantity: item.quantity,
                unitPrice: item.unitPrice || 0, // Preço pode ser opcional dependendo do tipo
            });

            // Ajustar estoque
            const quantityChange = (type === "ENTRADA" || type === "AJUSTE_ENTRADA") ? item.quantity : -item.quantity;
            await db.updateStockQuantity(item.itemId, storeId, quantityChange);
            // TODO: Verificar se estoque ficou negativo se a regra de negócio exigir
        }

        await db.commitTransaction();

        // Retornar o documento criado com os itens
        const newDocument = await db.findDocumentByIdAndStore(documentId, storeId);
        const newItems = await db.findDocumentItemsByDocumentId(documentId);
        const documentWithItems = { ...newDocument, items: newItems };
        
        sendSuccessResponse(res, documentWithItems, 'Documento criado com sucesso', 201);

    } catch (error) {
        await db.rollbackTransaction();
        throw error;
    }
});

// PUT /api/stores/:storeId/documents/:documentId - Atualizar documento (cabeçalho apenas?)
// **NOTA:** Atualizar itens de um documento finalizado geralmente não é permitido.
// A edição pode ser limitada a campos como 'notes' ou status (se houver).
// Uma abordagem mais segura seria CANCELAR o documento e criar um novo.
// Por simplicidade, vamos permitir atualizar apenas 'notes', 'date', 'customerId', 'supplierId'.
exports.updateDocumentHeader = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const documentId = validateId(req.params.documentId, 'ID do documento');
    const { date, customerId, supplierId, notes } = req.body;

    const existingDoc = await db.findDocumentByIdAndStore(documentId, storeId);
    if (!existingDoc) {
        return notFound('Documento nesta loja');
    }
    
    // TODO: Adicionar lógica para impedir edição se o documento estiver "fechado" ou "processado"

    const result = await db.updateDocumentHeaderDetails(documentId, storeId, {
        date: date || existingDoc.date, // Manter data se não fornecida
        customerId: customerId === undefined ? existingDoc.customer_id : customerId, // Permite setar para null
        supplierId: supplierId === undefined ? existingDoc.supplier_id : supplierId, // Permite setar para null
        notes: notes === undefined ? existingDoc.notes : notes?.trim() || null,
    });

    const updatedDocument = await db.findDocumentByIdAndStore(documentId, storeId);
    const items = await db.findDocumentItemsByDocumentId(documentId); // Itens não mudam aqui
    const documentWithItems = { ...updatedDocument, items };
    
    sendSuccessResponse(res, documentWithItems, 'Documento atualizado com sucesso');
});

// DELETE /api/stores/:storeId/documents/:documentId - Deletar/Cancelar documento
// **NOTA:** A exclusão física pode ser perigosa. Uma abordagem melhor é "cancelar" o documento.
// Cancelar envolveria REVERTER os ajustes de estoque feitos pelo documento original.
exports.cancelDocument = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const documentId = validateId(req.params.documentId, 'ID do documento');

    try {
        await db.beginTransaction();

        const document = await db.findDocumentByIdAndStore(documentId, storeId);
        if (!document) {
            await db.rollbackTransaction();
            return notFound('Documento nesta loja');
        }
        
        if (document.status === "CANCELADO") { // Assumindo um campo status
            await db.rollbackTransaction();
            throw new AppError('Documento já está cancelado.', 400);
        }

        // 1. Buscar os itens do documento para saber o que reverter
        const items = await db.findDocumentItemsByDocumentId(documentId);

        // 2. Reverter os ajustes de estoque
        for (const item of items) {
            // A quantidade a reverter é o OPOSTO do ajuste original
            const quantityToReverse = (document.type === "ENTRADA" || document.type === "AJUSTE_ENTRADA") ? -item.quantity : item.quantity;
            await db.updateStockQuantity(item.item_id, storeId, quantityToReverse);
            // TODO: Verificar se estoque ficou negativo se a regra de negócio exigir
        }

        // 3. Marcar o documento como cancelado (ou deletar, se preferir - menos seguro)
        // await db.deleteDocumentAndItems(documentId, storeId); // Opção 1: Deletar
        await db.updateDocumentStatus(documentId, storeId, "CANCELADO"); // Opção 2: Marcar como cancelado

        await db.commitTransaction();

        sendSuccessResponse(res, null, 'Documento cancelado com sucesso');

    } catch (error) {
        await db.rollbackTransaction();
        throw error;
    }
});

