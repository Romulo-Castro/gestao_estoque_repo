/**
 * Supplier Repository Interface
 * Define os contratos para operações de persistência de suppliers
 */
class SupplierRepository {
    /**
     * Busca todos os suppliers de uma loja
     * @param {number} storeId - ID da loja
     * @returns {Promise<Supplier[]>} Lista de suppliers
     */
    async findByStore(storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Busca supplier por ID e loja
     * @param {number} supplierId - ID do supplier
     * @param {number} storeId - ID da loja
     * @returns {Promise<Supplier|null>} Supplier encontrado ou null
     */
    async findByIdAndStore(supplierId, storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Busca supplier por email em uma loja
     * @param {string} email - Email do supplier
     * @param {number} storeId - ID da loja
     * @returns {Promise<Supplier|null>} Supplier encontrado ou null
     */
    async findByEmailAndStore(email, storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Cria um novo supplier
     * @param {Supplier} supplier - Entidade supplier
     * @returns {Promise<Supplier>} Supplier criado com ID
     */
    async create(supplier) {
        throw new Error('Method not implemented');
    }

    /**
     * Atualiza um supplier existente
     * @param {Supplier} supplier - Entidade supplier
     * @returns {Promise<Supplier>} Supplier atualizado
     */
    async update(supplier) {
        throw new Error('Method not implemented');
    }

    /**
     * Remove um supplier
     * @param {number} supplierId - ID do supplier
     * @param {number} storeId - ID da loja
     * @returns {Promise<boolean>} True se removido com sucesso
     */
    async delete(supplierId, storeId) {
        throw new Error('Method not implemented');
    }
}

module.exports = SupplierRepository;
