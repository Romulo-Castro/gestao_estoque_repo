const express = require('express');

/**
 * Factory function para criar rotas de customers
 * @param {Object} container - DI Container
 * @returns {Router} Router configurado
 */
function createCustomerRoutes(container) {
    const router = express.Router({ mergeParams: true });
    
    // Injetar dependências do container
    const customerController = container.get('customerController');

    // Rotas de customers
    router.get('/', customerController.getAllCustomers);
    router.post('/', customerController.createNewCustomer);
    router.put('/:customerId', customerController.updateExistingCustomer);
    router.delete('/:customerId', customerController.deleteExistingCustomer);

    return router;
}

module.exports = createCustomerRoutes;
