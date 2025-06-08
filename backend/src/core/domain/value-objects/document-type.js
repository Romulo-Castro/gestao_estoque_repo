// core/domain/value-objects/document-type.js

/**
 * Value Object - Tipo de Documento
 * Representa os tipos de documento válidos
 */
class DocumentType {
  static ENTRADA = 'ENTRADA';
  static SAIDA = 'SAÍDA';
  static BALANCA = 'BALANÇA';

  constructor(type) {
    if (!DocumentType.isValid(type)) {
      throw new Error(`Tipo de documento inválido: ${type}`);
    }
    this.type = type;
  }

  /**
   * Verifica se o tipo é válido
   */
  static isValid(type) {
    return [
      DocumentType.ENTRADA,
      DocumentType.SAIDA,
      DocumentType.BALANCA
    ].includes(type);
  }

  /**
   * Verifica se é entrada
   */
  isInflow() {
    return this.type === DocumentType.ENTRADA;
  }

  /**
   * Verifica se é saída
   */
  isOutflow() {
    return this.type === DocumentType.SAIDA;
  }

  /**
   * Verifica se é balança
   */
  isBalance() {
    return this.type === DocumentType.BALANCA;
  }

  /**
   * Verifica se afeta o estoque positivamente
   */
  isPositiveImpact() {
    return this.isInflow();
  }

  /**
   * Verifica se afeta o estoque negativamente
   */
  isNegativeImpact() {
    return this.isOutflow();
  }

  /**
   * Verifica se é igual a outro tipo
   */
  equals(other) {
    return other instanceof DocumentType && this.type === other.type;
  }

  /**
   * Retorna string do tipo
   */
  toString() {
    return this.type;
  }

  /**
   * Retorna descrição amigável
   */
  getDescription() {
    switch (this.type) {
      case DocumentType.ENTRADA:
        return 'Entrada de Mercadorias';
      case DocumentType.SAIDA:
        return 'Saída de Mercadorias';
      case DocumentType.BALANCA:
        return 'Balança/Ajuste de Estoque';
      default:
        return this.type;
    }
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      type: this.type,
      description: this.getDescription()
    };
  }

  /**
   * Cria um DocumentType a partir de string
   */
  static fromString(typeString) {
    return new DocumentType(typeString);
  }

  /**
   * Retorna todos os tipos válidos
   */
  static getAllTypes() {
    return [
      DocumentType.ENTRADA,
      DocumentType.SAIDA,
      DocumentType.BALANCA
    ];
  }

  /**
   * Retorna todos os tipos como objetos
   */
  static getAllTypesWithDescription() {
    return DocumentType.getAllTypes().map(type => ({
      type,
      description: new DocumentType(type).getDescription()
    }));
  }
}

module.exports = DocumentType;
