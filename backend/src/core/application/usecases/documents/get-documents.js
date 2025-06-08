// core/application/usecases/documents/get-documents.js

/**
 * Caso de Uso - Buscar Documentos
 * Responsável por buscar documentos com filtros opcionais
 */
class GetDocuments {
  constructor(documentRepository) {
    this.documentRepository = documentRepository;
  }

  /**
   * Executa o caso de uso
   * @param {Object} params - Parâmetros de busca
   * @param {number} params.storeId - ID da loja
   * @param {string} [params.type] - Tipo do documento
   * @param {string} [params.status] - Status do documento
   * @param {Date} [params.startDate] - Data inicial
   * @param {Date} [params.endDate] - Data final
   * @param {number} [params.limit] - Limite de resultados
   * @param {number} [params.offset] - Offset para paginação
   * @returns {Promise<Object>} Resultado com documentos e metadados
   */
  async execute(params) {
    try {
      // Validações básicas
      if (!params.storeId) {
        throw new Error('Store ID é obrigatório');
      }

      // Construir filtros
      const filters = {
        storeId: params.storeId
      };

      if (params.type) {
        filters.type = params.type;
      }

      if (params.status) {
        filters.status = params.status;
      }

      if (params.startDate && params.endDate) {
        filters.startDate = params.startDate;
        filters.endDate = params.endDate;
      }

      if (params.limit) {
        filters.limit = params.limit;
      }

      if (params.offset) {
        filters.offset = params.offset;
      }

      // Buscar documentos
      const documents = await this.documentRepository.findWithFilters(filters);

      // Buscar itens para cada documento se necessário
      const documentsWithItems = await Promise.all(
        documents.map(async (doc) => {
          try {
            const items = await this.documentRepository.findItems(doc.id);
            return {
              ...doc.toJSON(),
              items: items || []
            };
          } catch (error) {
            // Se não conseguir buscar os itens, retorna o documento sem eles
            return {
              ...doc.toJSON(),
              items: []
            };
          }
        })
      );

      // Calcular estatísticas
      const stats = this._calculateStats(documentsWithItems);

      return {
        documents: documentsWithItems,
        total: documentsWithItems.length,
        stats,
        filters: params
      };

    } catch (error) {
      throw new Error(`Erro ao buscar documentos: ${error.message}`);
    }
  }

  /**
   * Calcula estatísticas dos documentos
   * @private
   */
  _calculateStats(documents) {
    const stats = {
      totalDocuments: documents.length,
      totalValue: 0,
      byType: {},
      byStatus: {}
    };

    documents.forEach(doc => {
      // Somar valor total
      stats.totalValue += doc.totalValue || 0;

      // Contar por tipo
      if (!stats.byType[doc.type]) {
        stats.byType[doc.type] = { count: 0, totalValue: 0 };
      }
      stats.byType[doc.type].count++;
      stats.byType[doc.type].totalValue += doc.totalValue || 0;

      // Contar por status
      if (!stats.byStatus[doc.status]) {
        stats.byStatus[doc.status] = { count: 0, totalValue: 0 };
      }
      stats.byStatus[doc.status].count++;
      stats.byStatus[doc.status].totalValue += doc.totalValue || 0;
    });

    return stats;
  }
}

module.exports = GetDocuments;
