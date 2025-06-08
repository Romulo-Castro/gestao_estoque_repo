const ValidationError = require('../../../../shared/errors/validation-error');

/**
 * Caso de Uso: Deletar Customer
 */
class DeleteCustomer {
    constructor(customerRepository) {
        this.customerRepository = customerRepository;
    }

    /**
     * Executa o caso de uso
     * @param {Object} params - Parâmetros de entrada
     * @param {number} params.customerId - ID do customer
     * @param {number} params.storeId - ID da loja
     * @returns {Promise<Object>} Resultado da operação
     */
    async execute({ customerId, storeId }) {
        // Validações
        const errors = [];

        if (!customerId || isNaN(customerId) || customerId <= 0) {
            errors.push({ field: 'customerId', message: 'ID do customer deve ser um número positivo' });
        }

        if (!storeId || isNaN(storeId) || storeId <= 0) {
            errors.push({ field: 'storeId', message: 'ID da loja deve ser um número positivo' });
        }

        if (errors.length > 0) {
            throw new ValidationError(errors);
        }

        try {
            // Verificar se customer existe
            const existingCustomer = await this.customerRepository.findByIdAndStore(customerId, storeId);
            if (!existingCustomer) {
                throw new ValidationError([{
                    field: 'customerId',
                    message: 'Customer não encontrado nesta loja'
                }]);
            }

            // Deletar customer
            const deleted = await this.customerRepository.delete(customerId, storeId);

            if (!deleted) {
                throw new Error('Falha ao deletar customer');
            }

            return {
                success: true,
                data: {
                    customerId: customerId,
                    storeId: storeId,
                    deletedAt: new Date()
                },
                message: 'Customer removido com sucesso'
            };
        } catch (error) {
            if (error instanceof ValidationError) {
                throw error;
            }
            throw new Error(`Erro ao deletar customer: ${error.message}`);
        }
    }
}

module.exports = DeleteCustomer;
