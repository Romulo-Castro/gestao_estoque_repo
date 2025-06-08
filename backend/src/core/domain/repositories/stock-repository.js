// core/domain/repositories/stock-repository.js

/**
 * Interface do Repositório de Estoque
 * Define os contratos para operações com itens de estoque
 */
class StockRepository {
  /**
   * Busca todos os itens de estoque de uma loja
   * @param {number} storeId - ID da loja
   * @returns {Promise<StockItem[]>}
   */
  async findByStoreId(storeId) {
    throw new Error('Método findByStoreId deve ser implementado');
  }

  /**
   * Busca um item por ID
   * @param {number} id - ID do item
   * @returns {Promise<StockItem|null>}
   */
  async findById(id) {
    throw new Error('Método findById deve ser implementado');
  }

  /**
   * Busca itens por grupo
   * @param {number} itemGroupId - ID do grupo
   * @returns {Promise<StockItem[]>}
   */
  async findByGroupId(itemGroupId) {
    throw new Error('Método findByGroupId deve ser implementado');
  }

  /**
   * Busca itens com estoque baixo
   * @param {number} storeId - ID da loja
   * @returns {Promise<StockItem[]>}
   */
  async findLowStock(storeId) {
    throw new Error('Método findLowStock deve ser implementado');
  }

  /**
   * Busca item por código de barras
   * @param {string} barcode - Código de barras
   * @param {number} storeId - ID da loja
   * @returns {Promise<StockItem|null>}
   */
  async findByBarcode(barcode, storeId) {
    throw new Error('Método findByBarcode deve ser implementado');
  }

  /**
   * Cria um novo item
   * @param {StockItem} stockItem - Item a ser criado
   * @returns {Promise<StockItem>}
   */
  async create(stockItem) {
    throw new Error('Método create deve ser implementado');
  }

  /**
   * Atualiza um item existente
   * @param {StockItem} stockItem - Item a ser atualizado
   * @returns {Promise<StockItem>}
   */
  async update(stockItem) {
    throw new Error('Método update deve ser implementado');
  }

  /**
   * Remove um item
   * @param {number} id - ID do item
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    throw new Error('Método delete deve ser implementado');
  }

  /**
   * Atualiza a quantidade de um item
   * @param {number} id - ID do item
   * @param {number} newQuantity - Nova quantidade
   * @returns {Promise<StockItem>}
   */
  async updateQuantity(id, newQuantity) {
    throw new Error('Método updateQuantity deve ser implementado');
  }

  /**
   * Busca itens com filtros
   * @param {Object} filters - Filtros de busca
   * @returns {Promise<StockItem[]>}
   */
  async findWithFilters(filters) {
    throw new Error('Método findWithFilters deve ser implementado');
  }

  /**
   * Conta total de itens de uma loja
   * @param {number} storeId - ID da loja
   * @returns {Promise<number>}
   */
  async countByStoreId(storeId) {
    throw new Error('Método countByStoreId deve ser implementado');
  }
}

module.exports = StockRepository;
