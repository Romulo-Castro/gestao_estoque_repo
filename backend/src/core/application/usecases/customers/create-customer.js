const Customer = require('../../../domain/entities/customer');
const ValidationError = require('../../../../shared/errors/validation-error');

/**
 * Caso de Uso: Criar Customer
 */
class CreateCustomer {
    constructor(customerRepository) {
        this.customerRepository = customerRepository;
    }

    /**
     * Executa o caso de uso
     * @param {Object} params - Parâmetros de entrada
     * @param {string} params.name - Nome do customer
     * @param {string} params.email - Email do customer
     * @param {string} params.phone - Telefone do customer
     * @param {string} params.address - Endereço do customer
     * @param {number} params.storeId - ID da loja
     * @returns {Promise<Object>} Resultado com customer criado
     */
    async execute({ name, email, phone, address, storeId }) {
        // Validações
        const errors = [];

        if (!name || name.trim().length === 0) {
            errors.push({ field: 'name', message: 'Nome é obrigatório' });
        }

        if (!email || email.trim().length === 0) {
            errors.push({ field: 'email', message: 'Email é obrigatório' });
        }

        if (!storeId || isNaN(storeId) || storeId <= 0) {
            errors.push({ field: 'storeId', message: 'ID da loja deve ser um número positivo' });
        }

        if (errors.length > 0) {
            throw new ValidationError(errors);
        }

        try {
            // Verificar se email já existe na loja
            const existingCustomer = await this.customerRepository.findByEmailAndStore(email.trim(), storeId);
            if (existingCustomer) {
                throw new ValidationError([{
                    field: 'email',
                    message: 'Já existe um cliente com este email nesta loja'
                }]);
            }

            // Criar entidade Customer
            const customer = new Customer({
                name: name.trim(),
                email: email.trim().toLowerCase(),
                phone: phone ? phone.trim() : null,
                address: address ? address.trim() : null,
                storeId: storeId
            });

            // Persistir no repositório
            const createdCustomer = await this.customerRepository.create(customer);

            return {
                success: true,
                data: this._mapToDTO(createdCustomer),
                message: 'Customer criado com sucesso'
            };
        } catch (error) {
            if (error instanceof ValidationError) {
                throw error;
            }
            throw new Error(`Erro ao criar customer: ${error.message}`);
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

module.exports = CreateCustomer;
