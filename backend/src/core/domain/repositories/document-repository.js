// core/domain/repositories/document-repository.js

/**
 * Interface do Repositório de Documentos
 * Define os contratos para operações com documentos
 */
class DocumentRepository {
  /**
   * Busca todos os documentos de uma loja
   * @param {number} storeId - ID da loja
   * @returns {Promise<Document[]>}
   */
  async findByStoreId(storeId) {
    throw new Error('Método findByStoreId deve ser implementado');
  }

  /**
   * Busca um documento por ID
   * @param {number} id - ID do documento
   * @returns {Promise<Document|null>}
   */
  async findById(id) {
    throw new Error('Método findById deve ser implementado');
  }

  /**
   * Busca documentos por tipo
   * @param {string} type - Tipo do documento
   * @param {number} storeId - ID da loja
   * @returns {Promise<Document[]>}
   */
  async findByType(type, storeId) {
    throw new Error('Método findByType deve ser implementado');
  }

  /**
   * Busca documentos por período
   * @param {Date} startDate - Data inicial
   * @param {Date} endDate - Data final
   * @param {number} storeId - ID da loja
   * @returns {Promise<Document[]>}
   */
  async findByDateRange(startDate, endDate, storeId) {
    throw new Error('Método findByDateRange deve ser implementado');
  }

  /**
   * Busca documentos por status
   * @param {string} status - Status do documento
   * @param {number} storeId - ID da loja
   * @returns {Promise<Document[]>}
   */
  async findByStatus(status, storeId) {
    throw new Error('Método findByStatus deve ser implementado');
  }

  /**
   * Busca documento por número
   * @param {string} number - Número do documento
   * @param {number} storeId - ID da loja
   * @returns {Promise<Document|null>}
   */
  async findByNumber(number, storeId) {
    throw new Error('Método findByNumber deve ser implementado');
  }

  /**
   * Cria um novo documento
   * @param {Document} document - Documento a ser criado
   * @returns {Promise<Document>}
   */
  async create(document) {
    throw new Error('Método create deve ser implementado');
  }

  /**
   * Atualiza um documento existente
   * @param {Document} document - Documento a ser atualizado
   * @returns {Promise<Document>}
   */
  async update(document) {
    throw new Error('Método update deve ser implementado');
  }

  /**
   * Remove um documento
   * @param {number} id - ID do documento
   * @returns {Promise<boolean>}
   */
  async delete(id) {
    throw new Error('Método delete deve ser implementado');
  }

  /**
   * Cancela um documento
   * @param {number} id - ID do documento
   * @returns {Promise<Document>}
   */
  async cancel(id) {
    throw new Error('Método cancel deve ser implementado');
  }

  /**
   * Busca itens de um documento
   * @param {number} documentId - ID do documento
   * @returns {Promise<DocumentItem[]>}
   */
  async findItems(documentId) {
    throw new Error('Método findItems deve ser implementado');
  }

  /**
   * Adiciona item a um documento
   * @param {number} documentId - ID do documento
   * @param {Object} item - Item a ser adicionado
   * @returns {Promise<Object>}
   */
  async addItem(documentId, item) {
    throw new Error('Método addItem deve ser implementado');
  }

  /**
   * Remove item de um documento
   * @param {number} documentId - ID do documento
   * @param {number} itemId - ID do item
   * @returns {Promise<boolean>}
   */
  async removeItem(documentId, itemId) {
    throw new Error('Método removeItem deve ser implementado');
  }

  /**
   * Busca documentos com filtros
   * @param {Object} filters - Filtros de busca
   * @returns {Promise<Document[]>}
   */
  async findWithFilters(filters) {
    throw new Error('Método findWithFilters deve ser implementado');
  }

  /**
   * Conta documentos por período e tipo
   * @param {Date} startDate - Data inicial
   * @param {Date} endDate - Data final
   * @param {string} type - Tipo do documento
   * @param {number} storeId - ID da loja
   * @returns {Promise<number>}
   */
  async countByPeriodAndType(startDate, endDate, type, storeId) {
    throw new Error('Método countByPeriodAndType deve ser implementado');
  }

  /**
   * Calcula valor total por período e tipo
   * @param {Date} startDate - Data inicial
   * @param {Date} endDate - Data final
   * @param {string} type - Tipo do documento
   * @param {number} storeId - ID da loja
   * @returns {Promise<number>}
   */
  async sumValueByPeriodAndType(startDate, endDate, type, storeId) {
    throw new Error('Método sumValueByPeriodAndType deve ser implementado');
  }
}

module.exports = DocumentRepository;
