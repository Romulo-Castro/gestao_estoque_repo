// Use Case: Create Stock Item
const { StockItem } = require('../../../domain/entities/stock-item');
const { Quantity } = require('../../../domain/value-objects/quantity');
const { ValidationError } = require('../../../../shared/errors/validation-error');

class CreateStockItem {
    constructor(stockRepository) {
        this.stockRepository = stockRepository;
    }

    async execute(data) {
        // Validate input data
        this.validateInput(data);

        // Create quantity value object
        const quantity = new Quantity(data.quantity || 0, data.unit || 'un');

        // Create stock item entity
        const stockItem = new StockItem({
            storeId: data.storeId,
            name: data.name.trim(),
            quantity,
            groupId: data.groupId || null,
            properties: data.properties || {},
            imageFilename: data.imageFilename || null
        });

        // Save to repository
        const savedItem = await this.stockRepository.save(stockItem);

        return this.mapToDTO(savedItem);
    }

    validateInput(data) {
        const errors = [];

        if (!data.storeId) {
            errors.push({ field: 'storeId', message: 'ID da loja é obrigatório' });
        }

        if (!data.name || !data.name.trim()) {
            errors.push({ field: 'name', message: 'Nome do item é obrigatório' });
        }

        if (data.quantity !== undefined && (isNaN(data.quantity) || data.quantity < 0)) {
            errors.push({ field: 'quantity', message: 'Quantidade deve ser um número não negativo' });
        }

        if (data.groupId !== undefined && data.groupId !== null && isNaN(data.groupId)) {
            errors.push({ field: 'groupId', message: 'ID do grupo deve ser um número válido' });
        }

        if (data.properties && typeof data.properties !== 'object') {
            errors.push({ field: 'properties', message: 'Propriedades devem ser um objeto válido' });
        }

        if (errors.length > 0) {
            throw new ValidationError('Dados de entrada inválidos', errors);
        }
    }    mapToDTO(stockItem) {
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
            groupName: stockItem.groupName
        };
    }buildImageUrl(filename) {
        if (!filename) return null;
        // Import PlatformUrlService for URL building
        const PlatformUrlService = require('../../../../shared/services/platform-url-service');
        return PlatformUrlService.buildImageUrl(filename);
    }
}

module.exports = { CreateStockItem };
