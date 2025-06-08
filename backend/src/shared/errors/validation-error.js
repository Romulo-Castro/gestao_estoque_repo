// shared/errors/validation-error.js

const BaseError = require('./base-error');

/**
 * Erro de validação
 */
class ValidationError extends BaseError {
  constructor(message, field = null, value = null) {
    super(message, 400, 'VALIDATION_ERROR');
    this.field = field;
    this.value = value;
  }

  /**
   * Cria erro de validação com múltiplos campos
   */
  static multipleFields(errors) {
    const error = new ValidationError('Erro de validação em múltiplos campos');
    error.errors = errors;
    return error;
  }

  /**
   * Cria erro de campo obrigatório
   */
  static required(field) {
    return new ValidationError(`Campo '${field}' é obrigatório`, field);
  }

  /**
   * Cria erro de formato inválido
   */
  static invalidFormat(field, expectedFormat) {
    return new ValidationError(
      `Campo '${field}' deve ter o formato: ${expectedFormat}`,
      field
    );
  }

  /**
   * Cria erro de valor inválido
   */
  static invalidValue(field, value, allowedValues = null) {
    let message = `Valor inválido para o campo '${field}': ${value}`;
    if (allowedValues) {
      message += `. Valores permitidos: ${allowedValues.join(', ')}`;
    }
    return new ValidationError(message, field, value);
  }

  /**
   * Converte para objeto JSON
   */
  toJSON() {
    const base = super.toJSON();
    return {
      ...base,
      field: this.field,
      value: this.value,
      errors: this.errors
    };
  }
}

module.exports = ValidationError;
