// core/domain/entities/document.js

/**
 * Entidade de Domínio - Documento
 * Representa um documento de entrada/saída com suas regras de negócio
 */
class Document {
  constructor({
    id,
    storeId,
    number,
    type,
    description,
    totalValue,
    date,
    status,
    customerId,
    supplierId,
    items,
    createdAt,
    updatedAt
  }) {
    this.id = id;
    this.storeId = storeId;
    this.number = number;
    this.type = type; // 'ENTRADA', 'SAÍDA', 'BALANÇA'
    this.description = description;
    this.totalValue = totalValue || 0;
    this.date = date;
    this.status = status || 'ATIVO'; // 'ATIVO', 'CANCELADO'
    this.customerId = customerId;
    this.supplierId = supplierId;
    this.items = items || [];
    this.createdAt = createdAt || new Date();
    this.updatedAt = updatedAt || new Date();

    this.validate();
  }

  /**
   * Valida a entidade
   */
  validate() {
    if (!this.storeId) {
      throw new Error('Store ID é obrigatório');
    }
    if (!this.number || this.number.trim().length === 0) {
      throw new Error('Número do documento é obrigatório');
    }
    if (!['ENTRADA', 'SAÍDA', 'BALANÇA'].includes(this.type)) {
      throw new Error('Tipo de documento inválido');
    }
    if (!this.date) {
      throw new Error('Data do documento é obrigatória');
    }
    if (!['ATIVO', 'CANCELADO'].includes(this.status)) {
      throw new Error('Status do documento inválido');
    }
  }

  /**
   * Verifica se o documento é de entrada
   */
  isInflow() {
    return this.type === 'ENTRADA';
  }

  /**
   * Verifica se o documento é de saída
   */
  isOutflow() {
    return this.type === 'SAÍDA';
  }

  /**
   * Verifica se o documento está ativo
   */
  isActive() {
    return this.status === 'ATIVO';
  }

  /**
   * Cancela o documento
   */
  cancel() {
    this.status = 'CANCELADO';
    this.updatedAt = new Date();
  }

  /**
   * Adiciona item ao documento
   */
  addItem(item) {
    if (!item.itemId || !item.quantity || !item.unitValue) {
      throw new Error('Item deve ter itemId, quantity e unitValue');
    }
    this.items.push(item);
    this.recalculateTotal();
  }

  /**
   * Remove item do documento
   */
  removeItem(itemId) {
    this.items = this.items.filter(item => item.itemId !== itemId);
    this.recalculateTotal();
  }

  /**
   * Recalcula o valor total do documento
   */
  recalculateTotal() {
    this.totalValue = this.items.reduce((total, item) => {
      return total + (item.quantity * item.unitValue);
    }, 0);
    this.updatedAt = new Date();
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

module.exports = Document;
