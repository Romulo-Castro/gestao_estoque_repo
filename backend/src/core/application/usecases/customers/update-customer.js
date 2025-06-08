const Customer = require('../../../domain/entities/customer');
const ValidationError = require('../../../../shared/errors/validation-error');

/**
 * Caso de Uso: Atualizar Customer
 */
class UpdateCustomer {
    constructor(customerRepository) {
        this.customerRepository = customerRepository;
    }

    /**
     * Executa o caso de uso
     * @param {Object} params - Parâmetros de entrada
     * @param {number} params.customerId - ID do customer
     * @param {string} params.name - Nome do customer
     * @param {string} params.email - Email do customer
     * @param {string} params.phone - Telefone do customer
     * @param {string} params.address - Endereço do customer
     * @param {number} params.storeId - ID da loja
     * @returns {Promise<Object>} Resultado com customer atualizado
     */
    async execute({ customerId, name, email, phone, address, storeId }) {
        // Validações
        const errors = [];

        if (!customerId || isNaN(customerId) || customerId <= 0) {
            errors.push({ field: 'customerId', message: 'ID do customer deve ser um número positivo' });
        }

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
            // Verificar se customer existe
            const existingCustomer = await this.customerRepository.findByIdAndStore(customerId, storeId);
            if (!existingCustomer) {
                throw new ValidationError([{
                    field: 'customerId',
                    message: 'Customer não encontrado nesta loja'
                }]);
            }

            // Verificar se email já existe em outro customer da loja
            const customerWithEmail = await this.customerRepository.findByEmailAndStore(email.trim(), storeId);
            if (customerWithEmail && customerWithEmail.id !== customerId) {
                throw new ValidationError([{
                    field: 'email',
                    message: 'Já existe outro cliente com este email nesta loja'
                }]);
            }

            // Criar entidade Customer atualizada
            const customer = new Customer({
                id: customerId,
                name: name.trim(),
                email: email.trim().toLowerCase(),
                phone: phone ? phone.trim() : null,
                address: address ? address.trim() : null,
                storeId: storeId,
                createdAt: existingCustomer.createdAt,
                updatedAt: new Date()
            });

            // Persistir no repositório
            const updatedCustomer = await this.customerRepository.update(customer);

            return {
                success: true,
                data: this._mapToDTO(updatedCustomer),
                message: 'Customer atualizado com sucesso'
            };
        } catch (error) {
            if (error instanceof ValidationError) {
                throw error;
            }
            throw new Error(`Erro ao atualizar customer: ${error.message}`);
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

module.exports = UpdateCustomer;
