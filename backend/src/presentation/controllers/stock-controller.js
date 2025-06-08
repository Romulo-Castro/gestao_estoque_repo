// Clean Architecture Stock Controller
const { ValidationError } = require('../../shared/errors/validation-error');

class StockController {
    constructor(container) {
        this.getStockItemsUseCase = container.get('getStockItems');
        this.createStockItemUseCase = container.get('createStockItem');
        this.updateStockItemUseCase = container.get('updateStockItem');
        this.deleteStockItemUseCase = container.get('deleteStockItem');
    }

    // GET /api/stores/:storeId/stock
    async getAllStockItems(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const filters = {
                groupId: req.query.groupId ? parseInt(req.query.groupId) : undefined,
                searchTerm: req.query.search,
                lowStock: req.query.lowStock === 'true',
                threshold: req.query.threshold ? parseInt(req.query.threshold) : undefined,
                includeStats: req.query.includeStats === 'true'
            };

            const result = await this.getStockItemsUseCase.execute(storeId, filters);

            res.status(200).json({
                status: 'success',
                message: 'Itens carregados com sucesso',
                data: result
            });
        } catch (error) {
            next(error);
        }
    }

    // GET /api/stores/:storeId/stock/:itemId
    async getStockItemById(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const itemId = parseInt(req.params.itemId);

            const result = await this.getStockItemsUseCase.execute(storeId, { itemId });
            const item = result.items.find(i => i.id === itemId);

            if (!item) {
                return res.status(404).json({
                    status: 'error',
                    message: 'Item não encontrado'
                });
            }

            res.status(200).json({
                status: 'success',
                message: 'Item encontrado com sucesso',
                data: item
            });
        } catch (error) {
            next(error);
        }
    }

    // POST /api/stores/:storeId/stock
    async createStockItem(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const itemData = {
                storeId,
                ...req.body
            };

            const result = await this.createStockItemUseCase.execute(itemData);

            res.status(201).json({
                status: 'success',
                message: 'Item criado com sucesso',
                data: result
            });
        } catch (error) {
            if (error instanceof ValidationError) {
                return res.status(400).json({
                    status: 'error',
                    message: error.message,
                    errors: error.errors
                });
            }
            next(error);
        }
    }

    // PUT /api/stores/:storeId/stock/:itemId
    async updateStockItem(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const itemId = parseInt(req.params.itemId);

            const result = await this.updateStockItemUseCase.execute(itemId, storeId, req.body);

            res.status(200).json({
                status: 'success',
                message: 'Item atualizado com sucesso',
                data: result
            });
        } catch (error) {
            if (error instanceof ValidationError) {
                return res.status(400).json({
                    status: 'error',
                    message: error.message,
                    errors: error.errors
                });
            }
            if (error.message === 'Item não encontrado') {
                return res.status(404).json({
                    status: 'error',
                    message: error.message
                });
            }
            next(error);
        }
    }

    // DELETE /api/stores/:storeId/stock/:itemId
    async deleteStockItem(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const itemId = parseInt(req.params.itemId);

            const result = await this.deleteStockItemUseCase.execute(itemId, storeId);

            res.status(200).json({
                status: 'success',
                message: result.message,
                data: result.deletedItem
            });
        } catch (error) {
            if (error.message === 'Item não encontrado') {
                return res.status(404).json({
                    status: 'error',
                    message: error.message
                });
            }
            next(error);
        }
    }

    // POST /api/stores/:storeId/stock/:itemId/image
    async uploadStockItemImage(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const itemId = parseInt(req.params.itemId);

            if (!req.file) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Nenhuma imagem foi enviada'
                });
            }

            const updateData = {
                imageFilename: req.file.filename
            };

            const result = await this.updateStockItemUseCase.execute(itemId, storeId, updateData);

            res.status(200).json({
                status: 'success',
                message: 'Imagem enviada com sucesso',
                data: result
            });
        } catch (error) {
            next(error);
        }
    }

    // DELETE /api/stores/:storeId/stock/:itemId/image
    async deleteStockItemImage(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const itemId = parseInt(req.params.itemId);

            const updateData = {
                imageFilename: null
            };

            const result = await this.updateStockItemUseCase.execute(itemId, storeId, updateData);

            res.status(200).json({
                status: 'success',
                message: 'Imagem removida com sucesso',
                data: result
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = { StockController };
