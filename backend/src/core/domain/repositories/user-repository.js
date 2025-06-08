/**
 * User Repository Interface
 * Define os contratos para operações de persistência de users
 */
class UserRepository {
    /**
     * Busca user por email
     * @param {string} email - Email do user
     * @returns {Promise<User|null>} User encontrado ou null
     */
    async findByEmail(email) {
        throw new Error('Method not implemented');
    }

    /**
     * Busca user por ID
     * @param {number} userId - ID do user
     * @returns {Promise<User|null>} User encontrado ou null
     */
    async findById(userId) {
        throw new Error('Method not implemented');
    }

    /**
     * Cria um novo user
     * @param {User} user - Entidade user
     * @returns {Promise<User>} User criado com ID
     */
    async create(user) {
        throw new Error('Method not implemented');
    }

    /**
     * Atualiza um user existente
     * @param {User} user - Entidade user
     * @returns {Promise<User>} User atualizado
     */
    async update(user) {
        throw new Error('Method not implemented');
    }

    /**
     * Remove um user
     * @param {number} userId - ID do user
     * @returns {Promise<boolean>} True se removido com sucesso
     */
    async delete(userId) {
        throw new Error('Method not implemented');
    }

    /**
     * Verifica se um email já existe
     * @param {string} email - Email para verificar
     * @returns {Promise<boolean>} True se email existe
     */
    async emailExists(email) {
        throw new Error('Method not implemented');
    }
}

module.exports = UserRepository;
