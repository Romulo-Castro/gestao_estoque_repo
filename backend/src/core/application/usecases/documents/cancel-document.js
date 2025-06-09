// core/application/usecases/documents/cancel-document.js

/**
 * Caso de Uso - Cancelar Documento
 * Responsável por cancelar documentos e reverter ajustes de estoque
 */
class CancelDocument {
  constructor(documentRepository, stockRepository) {
    this.documentRepository = documentRepository;
    this.stockRepository = stockRepository; // Keep for stock reversal logic
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

      // Verificar se documento existe. This also fetches the document details needed for stock reversal.
      const document = await this.documentRepository.findByIdAndStoreWithItems(params.documentId, params.storeId);
      if (!document) {
        // If findByIdAndStoreWithItems returns null, the document doesn't exist.
        throw new Error('Documento não encontrado nesta loja');
      }

      // No need to check for document.status === 'CANCELADO' as status is removed.
      // The repository's delete operation will handle if it's already gone.      // Prepare stock reversals based on document items and type
      const stockReversals = document.items.map(item => {
        let quantityChange;
        // Access the type property of DocumentType object
        if (document.type.type === 'ENTRADA') { // e.g., Purchase, Adjustment In
          quantityChange = -item.quantity; // Reverse by subtracting
        } else if (document.type.type === 'SAÍDA') { // e.g., Sale, Adjustment Out
          quantityChange = item.quantity;    // Reverse by adding back
        } else {
          // Should not happen if document types are well-defined
          console.warn(`Unknown document type for stock reversal: ${document.type.type}`);
          quantityChange = 0;
        }
        return {
          stockItemId: item.stockItemId,
          quantityChange: quantityChange
        };
      });

      // Executar cancelamento (delete) em transação, including stock reversals
      // The repository method now handles both deletion and stock reversal.
      const result = await this.documentRepository.cancelWithTransaction(params.documentId, params.storeId, stockReversals);

      if (!result || !result.cancelled) {
        // This case should ideally be caught by earlier checks or repository errors
        throw new Error('Falha ao cancelar o documento no repositório.');
      }

      return {
        message: 'Documento cancelado com sucesso',
        documentId: params.documentId
      };

    } catch (error) {
      // Preserve specific error messages if they are informative
      if (error.message === 'Documento não encontrado nesta loja' || error.message === 'Documento não encontrado ou já removido') {
        throw error; 
      }
      throw new Error(`Erro ao cancelar documento: ${error.message}`);
    }
  }
}

module.exports = CancelDocument;