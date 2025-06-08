// core/domain/value-objects/date-range.js

/**
 * Value Object - Período de Datas
 * Representa um intervalo de datas com validações
 */
class DateRange {
  constructor(startDate, endDate) {
    if (!(startDate instanceof Date) || !(endDate instanceof Date)) {
      throw new Error('Datas devem ser instâncias de Date');
    }
    if (startDate > endDate) {
      throw new Error('Data inicial não pode ser maior que data final');
    }
    
    this.startDate = new Date(startDate);
    this.endDate = new Date(endDate);
  }

  /**
   * Verifica se uma data está dentro do período
   */
  contains(date) {
    if (!(date instanceof Date)) {
      throw new Error('Data deve ser uma instância de Date');
    }
    return date >= this.startDate && date <= this.endDate;
  }

  /**
   * Verifica se outro período se sobrepõe
   */
  overlaps(other) {
    if (!(other instanceof DateRange)) {
      throw new Error('Só é possível comparar com outro DateRange');
    }
    return this.startDate <= other.endDate && this.endDate >= other.startDate;
  }

  /**
   * Retorna a duração em dias
   */
  getDurationInDays() {
    const diffTime = this.endDate - this.startDate;
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1; // +1 para incluir ambos os dias
  }

  /**
   * Verifica se é igual a outro período
   */
  equals(other) {
    return other instanceof DateRange && 
           this.startDate.getTime() === other.startDate.getTime() && 
           this.endDate.getTime() === other.endDate.getTime();
  }

  /**
   * Formata como string
   */
  toString() {
    return `${this.startDate.toISOString().split('T')[0]} - ${this.endDate.toISOString().split('T')[0]}`;
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      startDate: this.startDate.toISOString(),
      endDate: this.endDate.toISOString()
    };
  }

  /**
   * Cria um DateRange a partir de um objeto
   */
  static fromJSON(json) {
    return new DateRange(new Date(json.startDate), new Date(json.endDate));
  }

  /**
   * Cria um período para o mês atual
   */
  static thisMonth() {
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    return new DateRange(startDate, endDate);
  }

  /**
   * Cria um período para o ano atual
   */
  static thisYear() {
    const now = new Date();
    const startDate = new Date(now.getFullYear(), 0, 1);
    const endDate = new Date(now.getFullYear(), 11, 31);
    return new DateRange(startDate, endDate);
  }

  /**
   * Cria um período para os últimos N dias
   */
  static lastDays(days) {
    if (typeof days !== 'number' || days <= 0) {
      throw new Error('Número de dias deve ser positivo');
    }
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days + 1);
    return new DateRange(startDate, endDate);
  }

  /**
   * Cria um período customizado
   */
  static custom(startDateString, endDateString) {
    return new DateRange(new Date(startDateString), new Date(endDateString));
  }
}

module.exports = DateRange;
