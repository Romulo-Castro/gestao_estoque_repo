// core/domain/value-objects/money.js

/**
 * Value Object - Dinheiro
 * Representa valores monetários com validações
 */
class Money {
  constructor(value, currency = 'BRL') {
    if (typeof value !== 'number' || isNaN(value)) {
      throw new Error('Valor deve ser um número válido');
    }
    if (value < 0) {
      throw new Error('Valor não pode ser negativo');
    }
    
    this.value = Math.round(value * 100) / 100; // Arredonda para 2 casas decimais
    this.currency = currency;
  }

  /**
   * Adiciona outro valor monetário
   */
  add(other) {
    if (!(other instanceof Money)) {
      throw new Error('Só é possível adicionar outro objeto Money');
    }
    if (this.currency !== other.currency) {
      throw new Error('Moedas devem ser iguais para operação');
    }
    return new Money(this.value + other.value, this.currency);
  }

  /**
   * Subtrai outro valor monetário
   */
  subtract(other) {
    if (!(other instanceof Money)) {
      throw new Error('Só é possível subtrair outro objeto Money');
    }
    if (this.currency !== other.currency) {
      throw new Error('Moedas devem ser iguais para operação');
    }
    const result = this.value - other.value;
    if (result < 0) {
      throw new Error('Resultado não pode ser negativo');
    }
    return new Money(result, this.currency);
  }

  /**
   * Multiplica por um número
   */
  multiply(factor) {
    if (typeof factor !== 'number' || isNaN(factor)) {
      throw new Error('Fator deve ser um número válido');
    }
    if (factor < 0) {
      throw new Error('Fator não pode ser negativo');
    }
    return new Money(this.value * factor, this.currency);
  }

  /**
   * Verifica se é igual a outro valor
   */
  equals(other) {
    return other instanceof Money && 
           this.value === other.value && 
           this.currency === other.currency;
  }

  /**
   * Verifica se é maior que outro valor
   */
  isGreaterThan(other) {
    if (!(other instanceof Money)) {
      throw new Error('Só é possível comparar com outro objeto Money');
    }
    if (this.currency !== other.currency) {
      throw new Error('Moedas devem ser iguais para comparação');
    }
    return this.value > other.value;
  }

  /**
   * Formata como string
   */
  toString() {
    return `${this.currency} ${this.value.toFixed(2)}`;
  }

  /**
   * Retorna o valor numérico
   */
  getValue() {
    return this.value;
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      value: this.value,
      currency: this.currency
    };
  }

  /**
   * Cria um Money a partir de um objeto
   */
  static fromJSON(json) {
    return new Money(json.value, json.currency);
  }

  /**
   * Cria um Money com valor zero
   */
  static zero(currency = 'BRL') {
    return new Money(0, currency);
  }
}

module.exports = Money;
