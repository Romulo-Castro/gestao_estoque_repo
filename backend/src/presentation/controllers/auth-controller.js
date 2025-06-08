const { sendSuccessResponse, sendErrorResponse } = require('../../shared/utils/response-utils');
const ValidationError = require('../../shared/errors/validation-error');

/**
 * Controller Clean Architecture para Autenticação
 */
class AuthController {
    constructor(registerUser, authenticateUser) {
        this.registerUser = registerUser;
        this.authenticateUser = authenticateUser;

        // Bind methods para manter contexto
        this.register = this.register.bind(this);
        this.login = this.login.bind(this);
    }

    /**
     * POST /api/auth/register
     * Registra um novo usuário
     */
    async register(req, res) {
        try {
            const { name, email, password, role } = req.body;

            const result = await this.registerUser.execute({
                name,
                email,
                password,
                role
            });

            return sendSuccessResponse(res, result.data, result.message, 201);
        } catch (error) {
            if (error instanceof ValidationError) {
                return sendErrorResponse(res, error.message, 400, error.errors);
            }
            return sendErrorResponse(res, error.message, 500);
        }
    }

    /**
     * POST /api/auth/login
     * Autentica um usuário
     */
    async login(req, res) {
        try {
            const { email, password } = req.body;

            const result = await this.authenticateUser.execute({
                email,
                password
            });

            return sendSuccessResponse(res, result.data, result.message);
        } catch (error) {
            if (error instanceof ValidationError) {
                return sendErrorResponse(res, error.message, 401, error.errors);
            }
            return sendErrorResponse(res, error.message, 500);
        }
    }
}

module.exports = AuthController;
