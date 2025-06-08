const ValidationError = require('../../../../shared/errors/validation-error');

/**
 * Caso de Uso: Buscar Customers de uma Loja
 */
class GetCustomers {
    constructor(customerRepository) {
        this.customerRepository = customerRepository;
    }

    /**
     * Executa o caso de uso
     * @param {Object} params - Parâmetros de entrada
     * @param {number} params.storeId - ID da loja
     * @returns {Promise<Object>} Resultado com customers e metadados
     */
    async execute({ storeId }) {
        // Validações
        if (!storeId || isNaN(storeId) || storeId <= 0) {
            throw new ValidationError([{
                field: 'storeId',
                message: 'ID da loja deve ser um número positivo'
            }]);
        }

        try {
            // Buscar customers
            const customers = await this.customerRepository.findByStore(storeId);

            // Mapear para DTOs
            const customerDTOs = customers.map(customer => this._mapToDTO(customer));

            return {
                success: true,
                data: {
                    customers: customerDTOs,
                    total: customerDTOs.length,
                    storeId: storeId
                },
                message: 'Customers recuperados com sucesso'
            };
        } catch (error) {
            throw new Error(`Erro ao buscar customers: ${error.message}`);
        }
    }

    /**
     * Mapeia entidade Customer para DTO
     */
    _mapToDTO(customer) {
        return {
            id: customer.id,
            name: customer.name,
            email: customer.email,
            phone: customer.phone,
            address: customer.address,
            storeId: customer.storeId,
            createdAt: customer.createdAt,
            updatedAt: customer.updatedAt
        };
    }
}

module.exports = GetCustomers;
