// Clean Architecture Document Controller
const { DateRange } = require('../../core/domain/value-objects/date-range');
const ValidationError = require('../../shared/errors/validation-error');

class DocumentController {    constructor(container) {
        this.getDocumentsUseCase = container.get('getDocuments');
        this.calculateBalanceSheetUseCase = container.get('calculateBalanceSheet');
        this.createDocumentUseCase = container.get('createDocument');
        this.cancelDocumentUseCase = container.get('cancelDocument');
    }

    // GET /api/stores/:storeId/documents
    async getAllDocuments(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            
            // Build filters from query parameters
            const filters = {};
            
            if (req.query.type) {
                filters.type = req.query.type;
            }
            
            if (req.query.startDate && req.query.endDate) {
                filters.dateRange = new DateRange(
                    new Date(req.query.startDate),
                    new Date(req.query.endDate)
                );
            }
            
            if (req.query.customerId) {
                filters.customerId = parseInt(req.query.customerId);
            }
            
            if (req.query.supplierId) {
                filters.supplierId = parseInt(req.query.supplierId);
            }
            
            const options = {
                includeStats: req.query.includeStats === 'true',
                includeItems: req.query.includeItems === 'true',
                page: req.query.page ? parseInt(req.query.page) : 1,
                limit: req.query.limit ? parseInt(req.query.limit) : 50
            };

            const result = await this.getDocumentsUseCase.execute(storeId, filters, options);

            res.status(200).json({
                status: 'success',
                message: 'Documentos carregados com sucesso',
                data: result
            });
        } catch (error) {
            next(error);
        }
    }

    // GET /api/stores/:storeId/documents/:documentId
    async getDocumentById(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const documentId = parseInt(req.params.documentId);

            const result = await this.getDocumentsUseCase.execute(storeId, { documentId }, { includeItems: true });
            const document = result.documents.find(d => d.id === documentId);

            if (!document) {
                return res.status(404).json({
                    status: 'error',
                    message: 'Documento não encontrado'
                });
            }

            res.status(200).json({
                status: 'success',
                message: 'Documento encontrado com sucesso',
                data: document
            });
        } catch (error) {
            next(error);
        }
    }

    // GET /api/stores/:storeId/documents/balance-sheet
    async getBalanceSheet(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            
            // Parse period parameter
            let period = req.query.period || 'thisMonth';
            let customDateRange = null;
            
            if (period === 'custom' && req.query.startDate && req.query.endDate) {
                customDateRange = new DateRange(
                    new Date(req.query.startDate),
                    new Date(req.query.endDate)
                );
            }

            const options = {
                includeComparisons: req.query.includeComparisons !== 'false',
                includeTrends: req.query.includeTrends !== 'false',
                includeProjections: req.query.includeProjections === 'true'
            };

            const result = await this.calculateBalanceSheetUseCase.execute(
                storeId,
                period,
                customDateRange,
                options
            );

            res.status(200).json({
                status: 'success',
                message: 'Balanço calculado com sucesso',
                data: result
            });
        } catch (error) {
            next(error);
        }
    }

    // GET /api/stores/:storeId/documents/stats
    async getDocumentStats(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            
            let dateRange = null;
            if (req.query.startDate && req.query.endDate) {
                dateRange = new DateRange(
                    new Date(req.query.startDate),
                    new Date(req.query.endDate)
                );
            } else {
                // Default to current month
                dateRange = DateRange.thisMonth();
            }

            const result = await this.getDocumentsUseCase.execute(storeId, { dateRange }, { 
                includeStats: true,
                statsOnly: true 
            });

            res.status(200).json({
                status: 'success',
                message: 'Estatísticas carregadas com sucesso',
                data: result.stats
            });
        } catch (error) {
            next(error);
        }
    }    // POST /api/stores/:storeId/documents
    async createDocument(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const { type, documentDate, customerId, supplierId, notes, items } = req.body;

            // Validate required fields
            if (!type || !documentDate || !items || !Array.isArray(items) || items.length === 0) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Tipo, data do documento e itens são obrigatórios'
                });
            }

            const result = await this.createDocumentUseCase.execute({
                storeId,
                type,
                documentDate: new Date(documentDate),
                customerId,
                supplierId,
                notes,
                items
            });

            res.status(201).json({
                status: 'success',
                message: 'Documento criado com sucesso',
                data: result.data
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
        }    }    // DELETE /api/stores/:storeId/documents/:documentId
    async cancelDocument(req, res, next) {
        try {
            const storeId = parseInt(req.params.storeId);
            const documentId = parseInt(req.params.documentId);

            const result = await this.cancelDocumentUseCase.execute({
                documentId,
                storeId
            });

            // The use case now returns { message: '...', documentId: ... }
            // or throws an error if cancellation failed.
            res.status(200).json({
                status: 'success',
                message: result.message, // Use message from use case
                data: { id: result.documentId } // Send back the ID of the cancelled document
            });
        } catch (error) {
            if (error instanceof ValidationError) {
                return res.status(400).json({
                    status: 'error',
                    message: error.message,
                    errors: error.errors
                });
            }
            // Specific error from use case for not found
            if (error.message === 'Documento não encontrado nesta loja' || error.message === 'Documento não encontrado ou já removido') {
                return res.status(404).json({
                    status: 'error',
                    message: error.message
                });
            }
            // Generic error for other issues during cancellation
            if (error.message.startsWith('Erro ao cancelar documento:')) {
                 return res.status(500).json({
                    status: 'error',
                    message: error.message
                });
            }
            next(error); // Fallback for other unexpected errors
        }
    }
}

module.exports = { DocumentController };
