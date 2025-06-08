// core/domain/entities/stock-item.js

/**
 * Entidade de Domínio - Item de Estoque
 * Representa um item do estoque com suas regras de negócio
 */
class StockItem {
  constructor({
    id,
    storeId,
    itemGroupId,
    name,
    description,
    unit,
    quantity,
    unitValue,
    totalValue,
    minStock,
    maxStock,
    barcode,
    location,
    createdAt,
    updatedAt
  }) {
    this.id = id;
    this.storeId = storeId;
    this.itemGroupId = itemGroupId;
    this.name = name;
    this.description = description;
    this.unit = unit;
    this.quantity = quantity || 0;
    this.unitValue = unitValue || 0;
    this.totalValue = totalValue || (this.quantity * this.unitValue);
    this.minStock = minStock || 0;
    this.maxStock = maxStock || null;
    this.barcode = barcode;
    this.location = location;
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
    if (!this.name || this.name.trim().length === 0) {
      throw new Error('Nome do item é obrigatório');
    }
    if (this.quantity < 0) {
      throw new Error('Quantidade não pode ser negativa');
    }
    if (this.unitValue < 0) {
      throw new Error('Valor unitário não pode ser negativo');
    }
  }

  /**
   * Verifica se o item está com estoque baixo
   */
  isLowStock() {
    return this.quantity <= this.minStock;
  }

  /**
   * Verifica se o item está com estoque alto
   */
  isHighStock() {
    return this.maxStock && this.quantity >= this.maxStock;
  }

  /**
   * Atualiza a quantidade do item
   */
  updateQuantity(newQuantity) {
    if (newQuantity < 0) {
      throw new Error('Quantidade não pode ser negativa');
    }
    this.quantity = newQuantity;
    this.totalValue = this.quantity * this.unitValue;
    this.updatedAt = new Date();
  }

  /**
   * Atualiza o valor unitário
   */
  updateUnitValue(newUnitValue) {
    if (newUnitValue < 0) {
      throw new Error('Valor unitário não pode ser negativo');
    }
    this.unitValue = newUnitValue;
    this.totalValue = this.quantity * this.unitValue;
    this.updatedAt = new Date();
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      id: this.id,
      storeId: this.storeId,
      itemGroupId: this.itemGroupId,
      name: this.name,
      description: this.description,
      unit: this.unit,
      quantity: this.quantity,
      unitValue: this.unitValue,
      totalValue: this.totalValue,
      minStock: this.minStock,
      maxStock: this.maxStock,
      barcode: this.barcode,
      location: this.location,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

module.exports = StockItem;
