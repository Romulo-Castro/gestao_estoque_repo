// core/application/usecases/documents/cancel-document.js

/**
 * Caso de Uso - Cancelar Documento
 * Responsável por cancelar documentos e reverter ajustes de estoque
 */
class CancelDocument {
  constructor(documentRepository, stockRepository) {
    this.documentRepository = documentRepository;
    this.stockRepository = stockRepository;
  }

  /**
   * Executa o caso de uso
   * @param {Object} params - Parâmetros de cancelamento
   * @param {number} params.documentId - ID do documento
   * @param {number} params.storeId - ID da loja
   * @returns {Promise<Object>} Resultado do cancelamento
   */
  async execute(params) {
    try {
      // Validações básicas
      if (!params.documentId) {
        throw new Error('Document ID é obrigatório');
      }

      if (!params.storeId) {
        throw new Error('Store ID é obrigatório');
      }

      // Verificar se documento existe
      const document = await this.documentRepository.findByIdAndStore(params.documentId, params.storeId);
      if (!document) {
        throw new Error('Documento não encontrado nesta loja');
      }

      // Verificar se documento já está cancelado
      if (document.status === 'CANCELADO') {
        throw new Error('Documento já está cancelado');
      }

      // Buscar itens do documento para reverter estoque
      const items = await this.documentRepository.findItems(params.documentId);

      // Executar cancelamento em transação
      await this.documentRepository.cancelWithTransaction(params.documentId, params.storeId, document, items);

      return {
        message: 'Documento cancelado com sucesso'
      };

    } catch (error) {
      throw new Error(`Erro ao cancelar documento: ${error.message}`);
    }
  }
}

module.exports = CancelDocument;