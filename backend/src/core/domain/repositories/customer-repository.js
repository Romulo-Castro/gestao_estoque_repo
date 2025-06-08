/**
 * Customer Repository Interface
 * Define os contratos para operações de persistência de customers
 */
class CustomerRepository {
    /**
     * Busca todos os customers de uma loja
     * @param {number} storeId - ID da loja
     * @returns {Promise<Customer[]>} Lista de customers
     */
    async findByStore(storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Busca customer por ID e loja
     * @param {number} customerId - ID do customer
     * @param {number} storeId - ID da loja
     * @returns {Promise<Customer|null>} Customer encontrado ou null
     */
    async findByIdAndStore(customerId, storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Busca customer por email em uma loja
     * @param {string} email - Email do customer
     * @param {number} storeId - ID da loja
     * @returns {Promise<Customer|null>} Customer encontrado ou null
     */
    async findByEmailAndStore(email, storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Cria um novo customer
     * @param {Customer} customer - Entidade customer
     * @returns {Promise<Customer>} Customer criado com ID
     */
    async create(customer) {
        throw new Error('Method not implemented');
    }

    /**
     * Atualiza um customer existente
     * @param {Customer} customer - Entidade customer
     * @returns {Promise<Customer>} Customer atualizado
     */
    async update(customer) {
        throw new Error('Method not implemented');
    }

    /**
     * Remove um customer
     * @param {number} customerId - ID do customer
     * @param {number} storeId - ID da loja
     * @returns {Promise<boolean>} True se removido com sucesso
     */
    async delete(customerId, storeId) {
        throw new Error('Method not implemented');
    }
}

module.exports = CustomerRepository;
