const { sendSuccessResponse, sendErrorResponse } = require('../../shared/utils/response-utils');
const ValidationError = require('../../shared/errors/validation-error');

/**
 * Controller Clean Architecture para Customers
 */
class CustomerController {
    constructor(getCustomers, createCustomer, updateCustomer, deleteCustomer) {
        this.getCustomers = getCustomers;
        this.createCustomer = createCustomer;
        this.updateCustomer = updateCustomer;
        this.deleteCustomer = deleteCustomer;

        // Bind methods para manter contexto
        this.getAllCustomers = this.getAllCustomers.bind(this);
        this.createNewCustomer = this.createNewCustomer.bind(this);
        this.updateExistingCustomer = this.updateExistingCustomer.bind(this);
        this.deleteExistingCustomer = this.deleteExistingCustomer.bind(this);
    }

    /**
     * GET /api/stores/:storeId/customers
     * Lista todos os customers de uma loja
     */
    async getAllCustomers(req, res) {
        try {
            const storeId = parseInt(req.params.storeId);

            const result = await this.getCustomers.execute({ storeId });

            return sendSuccessResponse(res, result.data, result.message);
        } catch (error) {
            if (error instanceof ValidationError) {
                return sendErrorResponse(res, error.message, 400, error.errors);
            }
            return sendErrorResponse(res, error.message, 500);
        }
    }

    /**
     * POST /api/stores/:storeId/customers
     * Cria um novo customer
     */
    async createNewCustomer(req, res) {
        try {
            const storeId = parseInt(req.params.storeId);
            const { name, email, phone, address } = req.body;

            const result = await this.createCustomer.execute({
                name,
                email,
                phone,
                address,
                storeId
            });

            return sendSuccessResponse(res, result.data, result.message, 201);
        } catch (error) {
            if (error instanceof ValidationError) {
                return sendErrorResponse(res, error.message, 400, error.errors);
            }
            return sendErrorResponse(res, error.message, 500);
        }
    }

    /**
     * PUT /api/stores/:storeId/customers/:customerId
     * Atualiza um customer existente
     */
    async updateExistingCustomer(req, res) {
        try {
            const storeId = parseInt(req.params.storeId);
            const customerId = parseInt(req.params.customerId);
            const { name, email, phone, address } = req.body;

            const result = await this.updateCustomer.execute({
                customerId,
                name,
                email,
                phone,
                address,
                storeId
            });

            return sendSuccessResponse(res, result.data, result.message);
        } catch (error) {
            if (error instanceof ValidationError) {
                return sendErrorResponse(res, error.message, 400, error.errors);
            }
            return sendErrorResponse(res, error.message, 500);
        }
    }

    /**
     * DELETE /api/stores/:storeId/customers/:customerId
     * Remove um customer
     */
    async deleteExistingCustomer(req, res) {
        try {
            const storeId = parseInt(req.params.storeId);
            const customerId = parseInt(req.params.customerId);

            const result = await this.deleteCustomer.execute({
                customerId,
                storeId
            });

            return sendSuccessResponse(res, result.data, result.message);
        } catch (error) {
            if (error instanceof ValidationError) {
                return sendErrorResponse(res, error.message, 400, error.errors);
            }
            return sendErrorResponse(res, error.message, 500);
        }
    }
}

module.exports = CustomerController;
