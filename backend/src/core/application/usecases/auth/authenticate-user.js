const ValidationError = require('../../../../shared/errors/validation-error');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

/**
 * Caso de Uso: Autenticar Usuário
 */
class AuthenticateUser {
    constructor(userRepository, jwtSecret) {
        this.userRepository = userRepository;
        this.jwtSecret = jwtSecret;
    }

    /**
     * Executa o caso de uso
     * @param {Object} params - Parâmetros de entrada
     * @param {string} params.email - Email do usuário
     * @param {string} params.password - Senha do usuário
     * @returns {Promise<Object>} Resultado com token e dados do usuário
     */
    async execute({ email, password }) {
        // Validações
        const errors = [];

        if (!email || email.trim().length === 0) {
            errors.push({ field: 'email', message: 'Email é obrigatório' });
        }

        if (!password || password.length === 0) {
            errors.push({ field: 'password', message: 'Senha é obrigatória' });
        }

        if (errors.length > 0) {
            throw new ValidationError(errors);
        }

        try {
            // Buscar usuário por email
            const user = await this.userRepository.findByEmail(email.trim().toLowerCase());
            if (!user) {
                throw new ValidationError([{
                    field: 'credentials',
                    message: 'Email ou senha incorretos'
                }]);
            }

            // Verificar se usuário está ativo
            if (!user.isActive) {
                throw new ValidationError([{
                    field: 'user',
                    message: 'Usuário desativado'
                }]);
            }

            // Verificar senha
            const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
            if (!isPasswordValid) {
                throw new ValidationError([{
                    field: 'credentials',
                    message: 'Email ou senha incorretos'
                }]);
            }

            // Gerar token JWT
            const token = jwt.sign(
                { 
                    userId: user.id, 
                    email: user.email, 
                    role: user.role 
                },
                this.jwtSecret,
                { 
                    expiresIn: '24h',
                    issuer: 'gestao-estoque-api',
                    audience: 'gestao-estoque-frontend'
                }
            );

            return {
                success: true,
                data: {
                    token: token,
                    user: this._mapToDTO(user),
                    expiresIn: '24h'
                },
                message: 'Login realizado com sucesso'
            };
        } catch (error) {
            if (error instanceof ValidationError) {
                throw error;
            }
            throw new Error(`Erro ao autenticar usuário: ${error.message}`);
        }
    }

    /**
     * Mapeia entidade User para DTO (sem senha)
     */
    _mapToDTO(user) {
        return {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        };
    }
}

module.exports = AuthenticateUser;
