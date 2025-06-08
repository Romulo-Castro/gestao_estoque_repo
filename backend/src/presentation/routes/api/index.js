// API Routes Index
const express = require('express');
const { createV1Routes } = require('./v1');

const createApiRoutes = (container) => {
    const router = express.Router();

    // Mount V1 routes
    router.use('/v1', createV1Routes(container));

    // Default to V1 for backward compatibility
    router.use('/', createV1Routes(container));

    return router;
};

module.exports = { createApiRoutes };
