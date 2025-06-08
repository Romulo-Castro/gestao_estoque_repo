// core/domain/entities/user.js

/**
 * Entidade de Domínio - Usuário
 * Representa um usuário do sistema com suas regras de negócio
 */
class User {
  constructor({
    id,
    username,
    email,
    passwordHash,
    role,
    storeId,
    active,
    lastLogin,
    createdAt,
    updatedAt
  }) {
    this.id = id;
    this.username = username;
    this.email = email;
    this.passwordHash = passwordHash;
    this.role = role || 'USER'; // 'ADMIN', 'USER'
    this.storeId = storeId;
    this.active = active !== undefined ? active : true;
    this.lastLogin = lastLogin;
    this.createdAt = createdAt || new Date();
    this.updatedAt = updatedAt || new Date();

    this.validate();
  }

  /**
   * Valida a entidade
   */
  validate() {
    if (!this.username || this.username.trim().length === 0) {
      throw new Error('Username é obrigatório');
    }
    if (!this.email || !this.isValidEmail(this.email)) {
      throw new Error('Email válido é obrigatório');
    }
    if (!['ADMIN', 'USER'].includes(this.role)) {
      throw new Error('Role inválido');
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
   * Verifica se é administrador
   */
  isAdmin() {
    return this.role === 'ADMIN';
  }

  /**
   * Ativa o usuário
   */
  activate() {
    this.active = true;
    this.updatedAt = new Date();
  }

  /**
   * Desativa o usuário
   */
  deactivate() {
    this.active = false;
    this.updatedAt = new Date();
  }

  /**
   * Atualiza último login
   */
  updateLastLogin() {
    this.lastLogin = new Date();
    this.updatedAt = new Date();
  }

  /**
   * Converte para objeto simples (sem senha)
   */
  toJSON() {
    return {
      id: this.id,
      username: this.username,
      email: this.email,
      role: this.role,
      storeId: this.storeId,
      active: this.active,
      lastLogin: this.lastLogin,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  /**
   * Converte para objeto completo (com senha) - apenas para casos especiais
   */
  toJSONWithPassword() {
    return {
      ...this.toJSON(),
      passwordHash: this.passwordHash
    };
  }
}

module.exports = User;
