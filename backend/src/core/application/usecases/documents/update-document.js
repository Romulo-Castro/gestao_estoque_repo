// core/application/usecases/documents/update-document.js

/**
 * Caso de Uso - Atualizar Documento
 * Responsável por atualizar o cabeçalho de documentos (não os itens)
 */
class UpdateDocument {
  constructor(documentRepository, customerRepository, supplierRepository) {
    this.documentRepository = documentRepository;
    this.customerRepository = customerRepository;
    this.supplierRepository = supplierRepository;
  }

  /**
   * Executa o caso de uso
   * @param {Object} params - Parâmetros de atualização
   * @param {number} params.documentId - ID do documento
   * @param {number} params.storeId - ID da loja
   * @param {string} [params.date] - Nova data do documento
   * @param {number} [params.customerId] - ID do cliente
   * @param {number} [params.supplierId] - ID do fornecedor
   * @param {string} [params.notes] - Observações
   * @returns {Promise<Object>} Documento atualizado com itens
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
      const existingDoc = await this.documentRepository.findByIdAndStore(params.documentId, params.storeId);
      if (!existingDoc) {
        throw new Error('Documento não encontrado nesta loja');
      }

      // Verificar se documento pode ser editado
      if (existingDoc.status && ['FECHADO', 'PROCESSADO', 'CANCELADO'].includes(existingDoc.status)) {
        throw new Error('Documento não pode ser editado no estado atual');
      }

      // Validar cliente se informado
      if (params.customerId !== undefined && params.customerId !== null) {
        const customer = await this.customerRepository.findByIdAndStore(params.customerId, params.storeId);
        if (!customer) {
          throw new Error(`Cliente com ID ${params.customerId} não encontrado na loja`);
        }
      }

      // Validar fornecedor se informado
      if (params.supplierId !== undefined && params.supplierId !== null) {
        const supplier = await this.supplierRepository.findByIdAndStore(params.supplierId, params.storeId);
        if (!supplier) {
          throw new Error(`Fornecedor com ID ${params.supplierId} não encontrado na loja`);
        }
      }

      // Preparar dados para atualização
      const updateData = {
        date: params.date !== undefined ? params.date : existingDoc.document_date,
        customerId: params.customerId !== undefined ? params.customerId : existingDoc.customer_id,
        supplierId: params.supplierId !== undefined ? params.supplierId : existingDoc.supplier_id,
        notes: params.notes !== undefined ? (params.notes?.trim() || null) : existingDoc.notes,
      };

      // Atualizar documento
      await this.documentRepository.updateHeader(params.documentId, params.storeId, updateData);

      // Buscar documento atualizado com itens
      const updatedDocument = await this.documentRepository.findByIdAndStoreWithItems(params.documentId, params.storeId);

      return {
        document: updatedDocument,
        message: 'Documento atualizado com sucesso'
      };

    } catch (error) {
      throw new Error(`Erro ao atualizar documento: ${error.message}`);
    }
  }
}

module.exports = UpdateDocument;