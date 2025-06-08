// Use Case: Get Stock Items
class GetStockItems {
    constructor(stockRepository) {
        this.stockRepository = stockRepository;
    }

    async execute(storeId, filters = {}) {
        // Validate store ID
        if (!storeId || isNaN(storeId)) {
            throw new Error('ID da loja é obrigatório e deve ser um número válido');
        }

        let stockItems;

        if (filters.groupId) {
            stockItems = await this.stockRepository.findByGroupId(filters.groupId, storeId);
        } else if (filters.searchTerm) {
            stockItems = await this.stockRepository.searchByName(storeId, filters.searchTerm);
        } else if (filters.lowStock) {
            const threshold = filters.threshold || 10;
            stockItems = await this.stockRepository.getLowStockItems(storeId, threshold);
        } else {
            stockItems = await this.stockRepository.findByStoreId(storeId);
        }

        // Get additional statistics if requested
        const result = {
            items: stockItems.map(item => this.mapToDTO(item)),
            count: stockItems.length
        };

        if (filters.includeStats) {
            result.stats = {
                totalItems: await this.stockRepository.getTotalItemsCount(storeId),
                lowStockCount: (await this.stockRepository.getLowStockItems(storeId, 10)).length,
                totalValue: this.calculateTotalValue(stockItems)
            };
        }

        return result;
    }

    calculateTotalValue(stockItems) {
        return stockItems.reduce((total, item) => {
            // If item has price in properties, calculate value
            const unitPrice = item.properties?.price || 0;
            return total + (item.quantity.value * unitPrice);
        }, 0);
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

module.exports = { GetStockItems };
