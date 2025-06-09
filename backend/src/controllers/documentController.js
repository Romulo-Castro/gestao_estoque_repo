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
    
    const { type, startDate, endDate, customerId, supplierId } = req.query;
    const filters = {
        type,
        startDate,
        endDate,
        customerId: customerId ? parseInt(customerId, 10) : undefined,
        supplierId: supplierId ? parseInt(supplierId, 10) : undefined,
    };

    const hasFilters = Object.values(filters).some(v => v !== undefined && v !== '' && v !== null);
    const documents = hasFilters
        ? await db.findDocumentsByStoreFiltered(storeId, filters)
        : await db.findDocumentsByStore(storeId);
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
    const { type, document_date, customerId, supplierId, notes, items, total_amount } = req.body;    // Validações básicas - aceita tipos em inglês conforme o banco de dados
    if (!["sale", "purchase"].includes(type)) {
        throw new AppError('Tipo de documento inválido. Use: sale ou purchase', 400);
    }
    
    if (!document_date) {
        throw new AppError('Data do documento é obrigatória.', 400);
    }
    
    if (!items || !Array.isArray(items) || items.length === 0) {
        throw new AppError('Documento deve ter pelo menos um item.', 400);
    }

    if (customerId) {
        const customer = await db.findCustomerByIdAndStore(customerId, storeId);
        if (!customer) {
            throw new AppError(`Cliente com ID ${customerId} não encontrado na loja.`, 400);
        }
    }
    if (supplierId) {
        const supplier = await db.findSupplierByIdAndStore(supplierId, storeId);
        if (!supplier) {
            throw new AppError(`Fornecedor com ID ${supplierId} não encontrado na loja.`, 400);
        }
    }

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
        const documentId = docResult.lastID;        // 2. Criar os itens do documento e ajustar estoque
        for (const item of items) {
            // Aceita tanto itemId quanto item_id para compatibilidade
            const itemId = item.itemId || item.item_id;
            const itemQuantity = item.quantity;
            
            if (!itemId || !itemQuantity || itemQuantity <= 0) {
                throw new AppError('Item inválido no documento: ID e quantidade positiva são obrigatórios.', 400);
            }

            // Validar se itemId existe na loja
            const stockItem = await db.findStockItemByIdAndStore(itemId, storeId);
            if (!stockItem) {
                throw new AppError(`Item com ID ${itemId} não encontrado na loja.`, 400);
            }            // Validar estoque para vendas
            if (type === "sale" && stockItem.quantity < itemQuantity) {
                throw new AppError(`Estoque insuficiente para o item "${stockItem.name}". Disponível: ${stockItem.quantity}, Solicitado: ${itemQuantity}`, 400);
            }

            await db.createDocumentItem({
                documentId,
                itemId: itemId, // Use the extracted itemId
                quantity: itemQuantity,
                unitPrice: item.unitPrice || item.unit_price || 0, // Support both naming conventions
            });            // Ajustar estoque - fix type checking to use English types
            const quantityChange = (type === "purchase") ? itemQuantity : -itemQuantity;
            await db.updateStockQuantity(itemId, storeId, quantityChange);
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
    const { date, document_date, customerId, supplierId, notes } = req.body;

    const existingDoc = await db.findDocumentByIdAndStore(documentId, storeId);
    if (!existingDoc) {
        return notFound('Documento nesta loja');
    }
    
    if (existingDoc.status && ['FECHADO', 'PROCESSADO', 'CANCELADO'].includes(existingDoc.status)) {
        throw new AppError('Documento não pode ser editado no estado atual.', 400);
    }

    const result = await db.updateDocumentHeaderDetails(documentId, storeId, {
        date: document_date || date || existingDoc.document_date, // Manter data se não fornecida
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
        const items = await db.findDocumentItemsByDocumentId(documentId);        // 2. Reverter os ajustes de estoque
        for (const item of items) {
            // A quantidade a reverter é o OPOSTO do ajuste original
            const quantityToReverse = (document.type === "purchase") ? -item.quantity : item.quantity;
            await db.updateStockQuantity(item.item_id, storeId, quantityToReverse);
        }        // 3. Delete the document completely (since status field no longer exists)
        await db.deleteDocumentAndItems(documentId, storeId); // Delete the document and its items

        await db.commitTransaction();

        sendSuccessResponse(res, null, 'Documento cancelado com sucesso');

    } catch (error) {
        await db.rollbackTransaction();
        throw error;
    }
});

