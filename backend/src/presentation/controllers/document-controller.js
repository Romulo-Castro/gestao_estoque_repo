// Clean Architecture Document Controller
const { DateRange } = require('../../core/domain/value-objects/date-range');
const { ValidationError } = require('../../shared/errors/validation-error');

class DocumentController {
    constructor(container) {
        this.getDocumentsUseCase = container.get('getDocuments');
        this.calculateBalanceSheetUseCase = container.get('calculateBalanceSheet');
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
            
            if (req.query.status) {
                filters.status = req.query.status;
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
    }

    // POST /api/stores/:storeId/documents (placeholder for future implementation)
    async createDocument(req, res, next) {
        res.status(501).json({
            status: 'error',
            message: 'Funcionalidade ainda não implementada na Clean Architecture'
        });
    }

    // PUT /api/stores/:storeId/documents/:documentId (placeholder for future implementation)
    async updateDocumentHeader(req, res, next) {
        res.status(501).json({
            status: 'error',
            message: 'Funcionalidade ainda não implementada na Clean Architecture'
        });
    }

    // DELETE /api/stores/:storeId/documents/:documentId (placeholder for future implementation)
    async cancelDocument(req, res, next) {
        res.status(501).json({
            status: 'error',
            message: 'Funcionalidade ainda não implementada na Clean Architecture'
        });
    }
}

module.exports = { DocumentController };
