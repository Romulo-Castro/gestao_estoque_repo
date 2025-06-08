// Use Case: Update Stock Item
const { Quantity } = require('../../../domain/value-objects/quantity');
const { ValidationError } = require('../../../../shared/errors/validation-error');

class UpdateStockItem {
    constructor(stockRepository) {
        this.stockRepository = stockRepository;
    }

    async execute(itemId, storeId, updateData) {
        // Validate input
        this.validateInput(itemId, storeId, updateData);

        // Find existing item
        const existingItem = await this.stockRepository.findById(itemId, storeId);
        if (!existingItem) {
            throw new Error('Item não encontrado');
        }

        // Update only provided fields
        if (updateData.name !== undefined) {
            existingItem.updateName(updateData.name.trim());
        }

        if (updateData.quantity !== undefined || updateData.unit !== undefined) {
            const newQuantity = new Quantity(
                updateData.quantity !== undefined ? updateData.quantity : existingItem.quantity.value,
                updateData.unit !== undefined ? updateData.unit : existingItem.quantity.unit
            );
            existingItem.updateQuantity(newQuantity);
        }

        if (updateData.groupId !== undefined) {
            existingItem.updateGroupId(updateData.groupId);
        }

        if (updateData.properties !== undefined) {
            existingItem.updateProperties(updateData.properties);
        }

        if (updateData.imageFilename !== undefined) {
            existingItem.updateImageFilename(updateData.imageFilename);
        }

        // Save updated item
        const updatedItem = await this.stockRepository.save(existingItem);

        return this.mapToDTO(updatedItem);
    }

    validateInput(itemId, storeId, updateData) {
        const errors = [];

        if (!itemId || isNaN(itemId)) {
            errors.push({ field: 'itemId', message: 'ID do item é obrigatório e deve ser um número' });
        }

        if (!storeId || isNaN(storeId)) {
            errors.push({ field: 'storeId', message: 'ID da loja é obrigatório e deve ser um número' });
        }

        if (updateData.name !== undefined && (!updateData.name || !updateData.name.trim())) {
            errors.push({ field: 'name', message: 'Nome do item não pode estar vazio' });
        }

        if (updateData.quantity !== undefined && (isNaN(updateData.quantity) || updateData.quantity < 0)) {
            errors.push({ field: 'quantity', message: 'Quantidade deve ser um número não negativo' });
        }

        if (updateData.groupId !== undefined && updateData.groupId !== null && isNaN(updateData.groupId)) {
            errors.push({ field: 'groupId', message: 'ID do grupo deve ser um número válido' });
        }

        if (updateData.properties !== undefined && typeof updateData.properties !== 'object') {
            errors.push({ field: 'properties', message: 'Propriedades devem ser um objeto válido' });
        }

        if (errors.length > 0) {
            throw new ValidationError('Dados de entrada inválidos', errors);
        }
    }

    mapToDTO(stockItem) {
        return {
            id: stockItem.id,
            storeId: stockItem.storeId,
            name: stockItem.name,
            quantity: stockItem.quantity.value,
            unit: stockItem.quantity.unit,
            groupId: stockItem.groupId,
            properties: stockItem.properties,
            imageFilename: stockItem.imageFilename,
            imageUrl: stockItem.imageFilename ? this.buildImageUrl(stockItem.imageFilename) : null,
            createdAt: stockItem.createdAt,
            updatedAt: stockItem.updatedAt,
            groupName: stockItem.groupName,
            groupDescription: stockItem.groupDescription
        };
    }

    buildImageUrl(filename) {
        if (!filename) return null;
        const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
        const uploadDir = process.env.UPLOAD_FOLDER || 'uploads';
        return `${baseUrl}/${uploadDir}/${filename}`;
    }
}

module.exports = { UpdateStockItem };
