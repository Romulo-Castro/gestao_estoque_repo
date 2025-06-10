// src/controllers/stockController.js
const db = require('../data/database'); // Importa funções do DB SQLite
const path = require('path');
const fs = require('fs');
// Garante que dotenv seja carregado para ler process.env
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Import centralized error handling utilities
const { 
    catchAsync, 
    validateId, 
    notFound, 
    AppError,
    sendSuccessResponse 
} = require('../utils/errorHandler');

const UPLOAD_DIR = process.env.UPLOAD_FOLDER || 'uploads';

// Helper function to build image URLs
function buildImageUrl(filename) {
    if (!filename) return null;
    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
    return `${baseUrl}/${UPLOAD_DIR}/${filename}`;
}

// GET /api/stores/:storeId/stock
exports.getAllStockItems = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    
    const items = await db.findStockItemsByStore(storeId);    const itemsWithFullUrls = items.map(item => ({
        ...item,
        image_filename: undefined,
        imageUrl: buildImageUrl(item.image_filename)
    }));
    
    sendSuccessResponse(res, itemsWithFullUrls, 'Itens carregados com sucesso');
});

// GET /api/stores/:storeId/stock/:itemId
exports.getStockItemById = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const itemId = validateId(req.params.itemId, 'ID do item');
    
    const item = await db.findStockItemByIdAndStore(itemId, storeId);
    if (!item) {
        return notFound('Item');
    }      const itemWithUrl = {
        ...item,
        image_filename: undefined,
        imageUrl: buildImageUrl(item.image_filename)
    };
    
    sendSuccessResponse(res, itemWithUrl, 'Item encontrado com sucesso');
});

// POST /api/stores/:storeId/stock
exports.createStockItem = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const { name, quantity, properties, groupId } = req.body;
    
    if (!name || name.trim() === '') {
        throw new AppError('Nome do item é obrigatório.', 400);
    }
    
    // Validação básica de 'properties'
    if (properties && typeof properties !== 'object') {
        throw new AppError("'properties' deve ser um objeto JSON.", 400);
    }

    // Validação de groupId se fornecido
    if (groupId !== null && groupId !== undefined && isNaN(parseInt(groupId))) {
        throw new AppError('ID do grupo deve ser um número válido.', 400);
    }

    // Cria o item passando o objeto properties (ou um objeto vazio) e groupId
    const result = await db.createStockItemInStore({
        storeId,
        name: name.trim(),
        quantity: parseFloat(quantity) || 0.0,
        groupId: groupId || null,
        properties: properties || {}
    });

    const newItem = await db.findStockItemByIdAndStore(result.lastID, storeId);
    if (!newItem) {
        throw new AppError('Erro ao buscar item após criação.', 500);
    }      const itemWithUrl = {
        ...newItem,
        image_filename: undefined,
        imageUrl: buildImageUrl(newItem.image_filename)
    };
    
    sendSuccessResponse(res, itemWithUrl, 'Item criado com sucesso', 201);
});

// PUT /api/stores/:storeId/stock/:itemId
exports.updateStockItem = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const itemId = validateId(req.params.itemId, 'ID do item');
    
    const { name, quantity, properties, groupId } = req.body;
    
    if (!name || name.trim() === '') {
        throw new AppError('Nome do item é obrigatório.', 400);
    }
    
    // Validação básica de 'properties'
    if (properties && typeof properties !== 'object') {
        throw new AppError("'properties' deve ser um objeto JSON.", 400);
    }

    // Validação de groupId se fornecido
    if (groupId !== null && groupId !== undefined && isNaN(parseInt(groupId))) {
        throw new AppError('ID do grupo deve ser um número válido.', 400);
    }

    const existingItem = await db.findStockItemByIdAndStore(itemId, storeId);
    if (!existingItem) {
        return notFound('Item nesta loja');
    }

    // Atualiza o item no banco de dados
    const result = await db.updateStockItemDetails(itemId, storeId, {
        name: name.trim(),
        quantity: parseFloat(quantity) ?? existingItem.quantity,
        properties: properties ?? existingItem.properties,
        groupId: groupId !== undefined ? groupId : existingItem.group_id
    });

    const updatedItem = await db.findStockItemByIdAndStore(itemId, storeId);
    if (!updatedItem) {
        throw new AppError('Erro ao buscar item após atualização.', 500);    }
      const itemWithUrl = {
        ...updatedItem,
        image_filename: undefined,
        imageUrl: buildImageUrl(updatedItem.image_filename)
    };
    
    sendSuccessResponse(res, itemWithUrl, 'Item atualizado com sucesso');
});

// DELETE /api/stores/:storeId/stock/:itemId
exports.deleteStockItem = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const itemId = validateId(req.params.itemId, 'ID do item');
    
    const item = await db.findStockItemByIdAndStore(itemId, storeId);
    if (!item) {
        return notFound('Item');
    }
    
    const imageFilename = item.image_filename;
    const result = await db.deleteStockItemFromStore(itemId, storeId);

    if (result.changes > 0) {
        // Remove arquivo de imagem se existir
        if (imageFilename) {
            const imagePath = path.resolve(__dirname, '../../', UPLOAD_DIR, imageFilename);
            fs.unlink(imagePath, (err) => {
                if (err) {
                    console.error(`Erro ao remover arquivo de imagem ${imagePath}:`, err);
                }
            });
        }
        
        sendSuccessResponse(res, null, 'Item deletado com sucesso');
    } else {
        return notFound('Item');
    }
});

// POST /api/stores/:storeId/stock/:itemId/image
exports.uploadStockItemImage = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const itemId = validateId(req.params.itemId, 'ID do item');
    
    if (!req.file) {
        throw new AppError('Nenhuma imagem foi enviada.', 400);
    }

    // Validação adicional de tamanho e tipo
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (req.file.size > maxSize) {
        // Remove arquivo se muito grande
        fs.unlink(req.file.path, (err) => {
            if (err) console.error(`Erro ao remover arquivo grande ${req.file.path}:`, err);
        });
        throw new AppError('Arquivo muito grande. Limite máximo: 10MB.', 400);
    }

    const imageFilename = req.file.filename;
    let oldImagePath = null;

    console.log(`Iniciando upload de imagem para item ${itemId}, loja ${storeId}`);
    console.log(`Arquivo recebido: ${req.file.originalname} (${req.file.size} bytes)`);

    try {
        const item = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!item) {
            // Remove arquivo uploaded se item não existe
            fs.unlink(req.file.path, (err) => {
                if (err) console.error(`Erro ao remover ${req.file.path}:`, err);
            });
            return notFound('Item');
        }
        
        // Se item já tem imagem, prepara para remover a antiga
        if (item.image_filename) {
            oldImagePath = path.resolve(__dirname, '../../', UPLOAD_DIR, item.image_filename);
            console.log(`Item já possui imagem: ${item.image_filename}, será substituída`);
        }

        await db.updateStockItemImageFilename(itemId, storeId, imageFilename);
        console.log(`Imagem ${imageFilename} associada ao item ${itemId} com sucesso`);

        // Remove imagem antiga se existia
        if (oldImagePath) {
            fs.unlink(oldImagePath, (err) => {
                if (err) {
                    console.error(`Erro ao remover imagem antiga ${oldImagePath}:`, err);
                } else {
                    console.log(`Imagem antiga removida: ${oldImagePath}`);
                }
            });
        }

        const updatedItem = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!updatedItem) {
            throw new AppError('Erro ao buscar item após upload.', 500);
        }        const itemWithUrl = {
            ...updatedItem,
            image_filename: undefined,
            imageUrl: buildImageUrl(updatedItem.image_filename)
        };
        
        console.log(`Upload concluído com sucesso. URL da imagem: ${itemWithUrl.imageUrl}`);
        sendSuccessResponse(res, itemWithUrl, `Imagem '${req.file.originalname}' enviada com sucesso`);

    } catch (dbError) {
        // Remove arquivo uploaded em caso de erro
        console.error(`Erro durante upload, removendo arquivo ${req.file.path}:`, dbError);
        fs.unlink(req.file.path, (err) => {
            if (err) console.error(`Erro ao remover ${req.file.path} após falha:`, err);
        });
        throw dbError;
    }
});

// DELETE /api/stores/:storeId/stock/:itemId/image - Remove image from stock item
exports.deleteStockItemImage = catchAsync(async (req, res, next) => {
    const storeId = validateId(req.params.storeId, 'ID da loja');
    const itemId = validateId(req.params.itemId, 'ID do item');

    const item = await db.findStockItemByIdAndStore(itemId, storeId);
    if (!item) {
        return notFound('Item');
    }

    if (!item.image_filename) {
        throw new AppError('Item não possui imagem para remover.', 404);
    }

    const imageFilename = item.image_filename;
    const imagePath = path.resolve(__dirname, '../../', UPLOAD_DIR, imageFilename);

    // Remove a referência da imagem no banco de dados
    await db.updateStockItemImageFilename(itemId, storeId, null);

    // Remove o arquivo físico
    fs.unlink(imagePath, (err) => {
        if (err) {
            console.error(`Erro ao remover arquivo de imagem ${imagePath}:`, err);
            // Não retorna erro para o cliente, pois a referência no DB já foi removida
        }
    });

    const updatedItem = await db.findStockItemByIdAndStore(itemId, storeId);
    if (!updatedItem) {
        throw new AppError('Erro ao buscar item após remoção da imagem.', 500);
    }    const itemWithUrl = {
        ...updatedItem,
        image_filename: undefined,
        imageUrl: buildImageUrl(updatedItem.image_filename) // Should be null now
    };
    
    sendSuccessResponse(res, itemWithUrl, 'Imagem removida com sucesso');
});