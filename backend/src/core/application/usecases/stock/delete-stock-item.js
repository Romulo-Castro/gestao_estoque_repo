// Use Case: Delete Stock Item
class DeleteStockItem {
    constructor(stockRepository) {
        this.stockRepository = stockRepository;
    }

    async execute(itemId, storeId) {
        // Validate input
        if (!itemId || isNaN(itemId)) {
            throw new Error('ID do item é obrigatório e deve ser um número');
        }

        if (!storeId || isNaN(storeId)) {
            throw new Error('ID da loja é obrigatório e deve ser um número');
        }

        // Check if item exists
        const existingItem = await this.stockRepository.findById(itemId, storeId);
        if (!existingItem) {
            throw new Error('Item não encontrado');
        }

        // Delete the item
        const deleted = await this.stockRepository.delete(itemId, storeId);
        
        if (!deleted) {
            throw new Error('Falha ao deletar o item');
        }

        return {
            success: true,
            message: 'Item deletado com sucesso',
            deletedItem: {
                id: existingItem.id,
                name: existingItem.name
            }
        };
    }
}

module.exports = { DeleteStockItem };
