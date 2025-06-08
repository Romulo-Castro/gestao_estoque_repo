// core/domain/value-objects/quantity.js

/**
 * Value Object - Quantidade
 * Representa quantidades com validações
 */
class Quantity {
  constructor(value, unit = 'UN') {
    if (typeof value !== 'number' || isNaN(value)) {
      throw new Error('Valor deve ser um número válido');
    }
    if (value < 0) {
      throw new Error('Quantidade não pode ser negativa');
    }
    
    this.value = value;
    this.unit = unit.toUpperCase();
  }

  /**
   * Adiciona outra quantidade
   */
  add(other) {
    if (!(other instanceof Quantity)) {
      throw new Error('Só é possível adicionar outro objeto Quantity');
    }
    if (this.unit !== other.unit) {
      throw new Error('Unidades devem ser iguais para operação');
    }
    return new Quantity(this.value + other.value, this.unit);
  }

  /**
   * Subtrai outra quantidade
   */
  subtract(other) {
    if (!(other instanceof Quantity)) {
      throw new Error('Só é possível subtrair outro objeto Quantity');
    }
    if (this.unit !== other.unit) {
      throw new Error('Unidades devem ser iguais para operação');
    }
    const result = this.value - other.value;
    if (result < 0) {
      throw new Error('Resultado não pode ser negativo');
    }
    return new Quantity(result, this.unit);
  }

  /**
   * Multiplica por um fator
   */
  multiply(factor) {
    if (typeof factor !== 'number' || isNaN(factor)) {
      throw new Error('Fator deve ser um número válido');
    }
    if (factor < 0) {
      throw new Error('Fator não pode ser negativo');
    }
    return new Quantity(this.value * factor, this.unit);
  }

  /**
   * Verifica se é igual a outra quantidade
   */
  equals(other) {
    return other instanceof Quantity && 
           this.value === other.value && 
           this.unit === other.unit;
  }

  /**
   * Verifica se é maior que outra quantidade
   */
  isGreaterThan(other) {
    if (!(other instanceof Quantity)) {
      throw new Error('Só é possível comparar com outro objeto Quantity');
    }
    if (this.unit !== other.unit) {
      throw new Error('Unidades devem ser iguais para comparação');
    }
    return this.value > other.value;
  }

  /**
   * Verifica se é zero
   */
  isZero() {
    return this.value === 0;
  }

  /**
   * Formata como string
   */
  toString() {
    return `${this.value} ${this.unit}`;
  }

  /**
   * Retorna o valor numérico
   */
  getValue() {
    return this.value;
  }

  /**
   * Retorna a unidade
   */
  getUnit() {
    return this.unit;
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      value: this.value,
      unit: this.unit
    };
  }

  /**
   * Cria um Quantity a partir de um objeto
   */
  static fromJSON(json) {
    return new Quantity(json.value, json.unit);
  }

  /**
   * Cria um Quantity com valor zero
   */
  static zero(unit = 'UN') {
    return new Quantity(0, unit);
  }
}

module.exports = Quantity;
