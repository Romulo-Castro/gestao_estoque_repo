// core/application/usecases/documents/create-document.js

/**
 * Caso de Uso - Criar Documento
 * Responsável por criar novos documentos com validações e ajustes de estoque
 */
class CreateDocument {
  constructor(documentRepository, stockRepository, customerRepository, supplierRepository) {
    this.documentRepository = documentRepository;
    this.stockRepository = stockRepository;
    this.customerRepository = customerRepository;
    this.supplierRepository = supplierRepository;
  }
  /**
   * Mapeia tipos de documento para formato do domínio
   */
  mapDocumentType(inputType) {
    const typeMapping = {
      // English types
      'purchase': 'ENTRADA',
      'sale': 'SAÍDA',
      'adjustment_in': 'ENTRADA',
      'adjustment_out': 'SAÍDA',
      
      // Portuguese types
      'entrada': 'ENTRADA',
      'ENTRADA': 'ENTRADA',
      'saida': 'SAÍDA',
      'SAÍDA': 'SAÍDA',
      'saída': 'SAÍDA',
      
      // Business types
      'compra': 'ENTRADA',
      'COMPRA': 'ENTRADA',
      'venda': 'SAÍDA',
      'VENDA': 'SAÍDA'
    };
    
    return typeMapping[inputType] || inputType;
  }

  /**
   * Executa o caso de uso
   * @param {Object} params - Parâmetros do documento
   * @param {number} params.storeId - ID da loja
   * @param {string} params.type - Tipo do documento (sale/purchase)
   * @param {string} params.documentDate - Data do documento
   * @param {number} [params.customerId] - ID do cliente
   * @param {number} [params.supplierId] - ID do fornecedor
   * @param {string} [params.notes] - Observações
   * @param {Array} params.items - Itens do documento
   * @param {number} [params.totalAmount] - Valor total
   * @returns {Promise<Object>} Documento criado com itens
   */
  async execute(params) {
    try {
      // Validações básicas
      if (!params.storeId) {
        throw new Error('Store ID é obrigatório');
      }      if (!['sale', 'purchase', 'ENTRADA', 'SAÍDA', 'entrada', 'saida', 'COMPRA', 'VENDA', 'compra', 'venda'].includes(params.type)) {
        throw new Error('Tipo de documento inválido. Use: sale, purchase, entrada, saida, compra, venda');
      }

      if (!params.documentDate) {
        throw new Error('Data do documento é obrigatória');
      }

      if (!params.items || !Array.isArray(params.items) || params.items.length === 0) {
        throw new Error('Documento deve ter pelo menos um item');
      }

      // Validar cliente se informado
      if (params.customerId) {
        const customer = await this.customerRepository.findByIdAndStore(params.customerId, params.storeId);
        if (!customer) {
          throw new Error(`Cliente com ID ${params.customerId} não encontrado na loja`);
        }
      }

      // Validar fornecedor se informado
      if (params.supplierId) {
        const supplier = await this.supplierRepository.findByIdAndStore(params.supplierId, params.storeId);
        if (!supplier) {
          throw new Error(`Fornecedor com ID ${params.supplierId} não encontrado na loja`);
        }
      }

      // Validar itens e estoque
      const validatedItems = [];
      for (const item of params.items) {
        const itemId = item.itemId || item.item_id;
        const quantity = item.quantity;

        if (!itemId || !quantity || quantity <= 0) {
          throw new Error('Item inválido: ID e quantidade positiva são obrigatórios');
        }

        // Validar se item existe na loja
        const stockItem = await this.stockRepository.findByIdAndStore(itemId, params.storeId);
        if (!stockItem) {
          throw new Error(`Item com ID ${itemId} não encontrado na loja`);
        }        // Validar estoque para vendas/saídas
        const isSaleType = ['sale', 'SAÍDA', 'saida', 'VENDA', 'venda'].includes(params.type);
        if (isSaleType && stockItem.quantity < quantity) {
          throw new Error(`Estoque insuficiente para o item "${stockItem.name}". Disponível: ${stockItem.quantity}, Solicitado: ${quantity}`);
        }

        validatedItems.push({
          itemId: itemId,
          quantity: quantity,
          unitPrice: item.unitPrice || item.unit_price || 0,
          stockItem: stockItem
        });
      }      // Criar documento em transação
      const documentData = {
        storeId: params.storeId,
        type: params.type,
        documentDate: params.documentDate,
        customerId: params.customerId || null,
        supplierId: params.supplierId || null,
        notes: params.notes?.trim() || null,
        totalAmount: params.totalAmount || 0
      };

      const document = await this.documentRepository.createWithTransaction(documentData, validatedItems);

      return {
        document,
        message: 'Documento criado com sucesso'
      };

    } catch (error) {
      throw new Error(`Erro ao criar documento: ${error.message}`);
    }
  }
}

module.exports = CreateDocument;