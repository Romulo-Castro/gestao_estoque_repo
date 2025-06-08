// core/application/dto/document-dto.js

/**
 * Data Transfer Object - Documento
 * Define a estrutura de dados para transferência de documentos
 */
class DocumentDTO {
  constructor(data) {
    this.id = data.id;
    this.storeId = data.storeId;
    this.number = data.number;
    this.type = data.type;
    this.description = data.description;
    this.totalValue = data.totalValue;
    this.date = data.date;
    this.status = data.status;
    this.customerId = data.customerId;
    this.supplierId = data.supplierId;
    this.items = data.items || [];
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  /**
   * Cria DTO a partir de entidade de domínio
   */
  static fromDomain(document) {
    return new DocumentDTO({
      id: document.id,
      storeId: document.storeId,
      number: document.number,
      type: document.type,
      description: document.description,
      totalValue: document.totalValue,
      date: document.date,
      status: document.status,
      customerId: document.customerId,
      supplierId: document.supplierId,
      items: document.items,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt
    });
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      id: this.id,
      storeId: this.storeId,
      number: this.number,
      type: this.type,
      description: this.description,
      totalValue: this.totalValue,
      date: this.date,
      status: this.status,
      customerId: this.customerId,
      supplierId: this.supplierId,
      items: this.items,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

/**
 * DTO para criação de documento
 */
class CreateDocumentDTO {
  constructor(data) {
    this.storeId = data.storeId;
    this.number = data.number;
    this.type = data.type;
    this.description = data.description;
    this.date = data.date;
    this.customerId = data.customerId;
    this.supplierId = data.supplierId;
    this.items = data.items || [];
  }

  /**
   * Valida os dados de entrada
   */
  validate() {
    const errors = [];

    if (!this.storeId) {
      errors.push('Store ID é obrigatório');
    }

    if (!this.number || this.number.trim().length === 0) {
      errors.push('Número do documento é obrigatório');
    }

    if (!['ENTRADA', 'SAÍDA', 'BALANÇA'].includes(this.type)) {
      errors.push('Tipo de documento inválido');
    }

    if (!this.date) {
      errors.push('Data do documento é obrigatória');
    }

    if (this.items.length === 0) {
      errors.push('Documento deve ter pelo menos um item');
    }

    // Validar itens
    this.items.forEach((item, index) => {
      if (!item.itemId) {
        errors.push(`Item ${index + 1}: ID do item é obrigatório`);
      }
      if (!item.quantity || item.quantity <= 0) {
        errors.push(`Item ${index + 1}: Quantidade deve ser positiva`);
      }
      if (!item.unitValue || item.unitValue <= 0) {
        errors.push(`Item ${index + 1}: Valor unitário deve ser positivo`);
      }
    });

    return errors;
  }
}

/**
 * DTO para atualização de documento
 */
class UpdateDocumentDTO {
  constructor(data) {
    this.id = data.id;
    this.description = data.description;
    this.date = data.date;
    this.customerId = data.customerId;
    this.supplierId = data.supplierId;
    this.items = data.items;
  }

  /**
   * Valida os dados de entrada
   */
  validate() {
    const errors = [];

    if (!this.id) {
      errors.push('ID do documento é obrigatório');
    }

    if (this.date && !(this.date instanceof Date)) {
      errors.push('Data deve ser uma instância de Date');
    }

    // Validar itens se fornecidos
    if (this.items) {
      this.items.forEach((item, index) => {
        if (!item.itemId) {
          errors.push(`Item ${index + 1}: ID do item é obrigatório`);
        }
        if (!item.quantity || item.quantity <= 0) {
          errors.push(`Item ${index + 1}: Quantidade deve ser positiva`);
        }
        if (!item.unitValue || item.unitValue <= 0) {
          errors.push(`Item ${index + 1}: Valor unitário deve ser positivo`);
        }
      });
    }

    return errors;
  }
}

module.exports = {
  DocumentDTO,
  CreateDocumentDTO,
  UpdateDocumentDTO
};
