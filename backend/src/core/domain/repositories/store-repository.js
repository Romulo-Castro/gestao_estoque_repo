/**
 * Store Repository Interface
 * Define os contratos para operações de persistência de stores
 */
class StoreRepository {
    /**
     * Busca todas as stores
     * @returns {Promise<Store[]>} Lista de stores
     */
    async findAll() {
        throw new Error('Method not implemented');
    }

    /**
     * Busca store por ID
     * @param {number} storeId - ID da store
     * @returns {Promise<Store|null>} Store encontrada ou null
     */
    async findById(storeId) {
        throw new Error('Method not implemented');
    }

    /**
     * Busca store por email
     * @param {string} email - Email da store
     * @returns {Promise<Store|null>} Store encontrada ou null
     */
    async findByEmail(email) {
        throw new Error('Method not implemented');
    }

    /**
     * Cria uma nova store
     * @param {Store} store - Entidade store
     * @returns {Promise<Store>} Store criada com ID
     */
    async create(store) {
        throw new Error('Method not implemented');
    }

    /**
     * Atualiza uma store existente
     * @param {Store} store - Entidade store
     * @returns {Promise<Store>} Store atualizada
     */
    async update(store) {
        throw new Error('Method not implemented');
    }

    /**
     * Remove uma store
     * @param {number} storeId - ID da store
     * @returns {Promise<boolean>} True se removida com sucesso
     */
    async delete(storeId) {
        throw new Error('Method not implemented');
    }
}

module.exports = StoreRepository;
