// shared/errors/base-error.js

/**
 * Classe base para erros customizados
 */
class BaseError extends Error {
  constructor(message, statusCode = 500, errorCode = 'INTERNAL_ERROR') {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.timestamp = new Date();

    // Captura o stack trace
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * Converte para objeto JSON
   */
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      statusCode: this.statusCode,
      errorCode: this.errorCode,
      timestamp: this.timestamp
    };
  }

  /**
   * Verifica se é um erro cliente (4xx)
   */
  isClientError() {
    return this.statusCode >= 400 && this.statusCode < 500;
  }

  /**
   * Verifica se é um erro servidor (5xx)
   */
  isServerError() {
    return this.statusCode >= 500;
  }
}

module.exports = BaseError;
