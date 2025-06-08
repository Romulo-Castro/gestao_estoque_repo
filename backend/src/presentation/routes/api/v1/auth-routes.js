const express = require('express');

/**
 * Factory function para criar rotas de autenticação
 * @param {Object} container - DI Container
 * @returns {Router} Router configurado
 */
function createAuthRoutes(container) {
    const router = express.Router();
    
    // Injetar dependências do container
    const authController = container.get('authController');

    // Rotas de autenticação
    router.post('/register', authController.register);
    router.post('/login', authController.login);

    return router;
}

module.exports = createAuthRoutes;
