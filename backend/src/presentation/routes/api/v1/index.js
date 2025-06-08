// API V1 Routes Index
const express = require('express');
const { createStockRoutes } = require('./stock-routes');
const { createDocumentRoutes } = require('./document-routes');
const createCustomerRoutes = require('./customer-routes');
const createAuthRoutes = require('./auth-routes');

const createV1Routes = (container) => {
    const router = express.Router();    // Mount Clean Architecture routes
    router.use('/stores/:storeId/stock', createStockRoutes(container));
    router.use('/stores/:storeId/documents', createDocumentRoutes(container));
    router.use('/stores/:storeId/customers', createCustomerRoutes(container));
    router.use('/auth', createAuthRoutes(container));

    // Health check endpoint
    router.get('/health', (req, res) => {
        res.status(200).json({
            status: 'success',
            message: 'Clean Architecture API V1 is healthy',
            timestamp: new Date().toISOString(),
            services: container.getRegisteredServices()
        });
    });

    return router;
};

module.exports = { createV1Routes };
