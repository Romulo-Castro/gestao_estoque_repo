const User = require('../../../domain/entities/user');
const ValidationError = require('../../../../shared/errors/validation-error');
const bcrypt = require('bcryptjs');

/**
 * Caso de Uso: Registrar Usuário
 */
class RegisterUser {
    constructor(userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Executa o caso de uso
     * @param {Object} params - Parâmetros de entrada
     * @param {string} params.name - Nome do usuário
     * @param {string} params.email - Email do usuário
     * @param {string} params.password - Senha do usuário
     * @param {string} params.role - Role do usuário (opcional, default: 'user')
     * @returns {Promise<Object>} Resultado com usuário criado
     */
    async execute({ name, email, password, role = 'user' }) {
        // Validações
        const errors = [];

        if (!name || name.trim().length === 0) {
            errors.push({ field: 'name', message: 'Nome é obrigatório' });
        }

        if (!email || email.trim().length === 0) {
            errors.push({ field: 'email', message: 'Email é obrigatório' });
        } else {
            // Validar formato do email
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email.trim())) {
                errors.push({ field: 'email', message: 'Formato de email inválido' });
            }
        }

        if (!password || password.length < 6) {
            errors.push({ field: 'password', message: 'Senha deve ter pelo menos 6 caracteres' });
        }

        if (role && !['admin', 'user'].includes(role)) {
            errors.push({ field: 'role', message: 'Role deve ser admin ou user' });
        }

        if (errors.length > 0) {
            throw new ValidationError(errors);
        }

        try {
            // Verificar se email já existe
            const existingUser = await this.userRepository.findByEmail(email.trim().toLowerCase());
            if (existingUser) {
                throw new ValidationError([{
                    field: 'email',
                    message: 'Email já está em uso'
                }]);
            }

            // Hash da senha
            const saltRounds = 12;
            const passwordHash = await bcrypt.hash(password, saltRounds);

            // Criar entidade User
            const user = new User({
                name: name.trim(),
                email: email.trim().toLowerCase(),
                passwordHash: passwordHash,
                role: role,
                isActive: true
            });

            // Persistir no repositório
            const createdUser = await this.userRepository.create(user);

            return {
                success: true,
                data: this._mapToDTO(createdUser),
                message: 'Usuário registrado com sucesso'
            };
        } catch (error) {
            if (error instanceof ValidationError) {
                throw error;
            }
            throw new Error(`Erro ao registrar usuário: ${error.message}`);
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

module.exports = RegisterUser;
