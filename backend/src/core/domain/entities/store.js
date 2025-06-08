// core/domain/entities/store.js

/**
 * Entidade de Domínio - Loja
 * Representa uma loja com suas regras de negócio
 */
class Store {
  constructor({
    id,
    name,
    description,
    address,
    phone,
    email,
    active,
    createdAt,
    updatedAt
  }) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.address = address;
    this.phone = phone;
    this.email = email;
    this.active = active !== undefined ? active : true;
    this.createdAt = createdAt || new Date();
    this.updatedAt = updatedAt || new Date();

    this.validate();
  }

  /**
   * Valida a entidade
   */
  validate() {
    if (!this.name || this.name.trim().length === 0) {
      throw new Error('Nome da loja é obrigatório');
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
   * Ativa a loja
   */
  activate() {
    this.active = true;
    this.updatedAt = new Date();
  }

  /**
   * Desativa a loja
   */
  deactivate() {
    this.active = false;
    this.updatedAt = new Date();
  }

  /**
   * Atualiza informações da loja
   */
  updateInfo({ name, description, address, phone, email }) {
    if (name) this.name = name;
    if (description !== undefined) this.description = description;
    if (address !== undefined) this.address = address;
    if (phone !== undefined) this.phone = phone;
    if (email !== undefined) this.email = email;
    
    this.updatedAt = new Date();
    this.validate();
  }

  /**
   * Converte para objeto simples
   */
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      address: this.address,
      phone: this.phone,
      email: this.email,
      active: this.active,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

module.exports = Store;
