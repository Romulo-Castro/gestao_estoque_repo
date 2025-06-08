// core/domain/entities/customer.js

/**
 * Entidade de Domínio - Cliente
 * Representa um cliente com suas regras de negócio
 */
class Customer {
  constructor({
    id,
    storeId,
    name,
    email,
    phone,
    address,
    document, // CPF/CNPJ
    active,
    createdAt,
    updatedAt
  }) {
    this.id = id;
    this.storeId = storeId;
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.address = address;
    this.document = document;
    this.active = active !== undefined ? active : true;
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
      throw new Error('Nome do cliente é obrigatório');
    }
    if (this.email && !this.isValidEmail(this.email)) {
      throw new Error('Email inválido');
    }
  }

  /**
   * Valida formato de email
   */
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Ativa o cliente
   */
  activate() {
    this.active = true;
    this.updatedAt = new Date();
  }

  /**
   * Desativa o cliente
   */
  deactivate() {
    this.active = false;
    this.updatedAt = new Date();
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      id: this.id,
      storeId: this.storeId,
      name: this.name,
      email: this.email,
      phone: this.phone,
      address: this.address,
      document: this.document,
      active: this.active,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

module.exports = Customer;
