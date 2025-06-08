const jwt = require('jsonwebtoken');
const { sendErrorResponse } = require('../../shared/utils/response-utils');

/**
 * Middleware de autenticação JWT para Clean Architecture
 * @param {string} jwtSecret - Secret para verificar JWT
 * @returns {Function} Middleware function
 */
function createAuthMiddleware(jwtSecret) {
    return (req, res, next) => {
        try {
            // Extrair token do header Authorization
            const authHeader = req.headers.authorization;
            
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return sendErrorResponse(res, 'Token de acesso requerido', 401);
            }

            const token = authHeader.substring(7); // Remove 'Bearer ' prefix

            // Verificar e decodificar token
            const decoded = jwt.verify(token, jwtSecret, {
                issuer: 'gestao-estoque-api',
                audience: 'gestao-estoque-frontend'
            });

            // Adicionar dados do usuário ao request
            req.user = {
                userId: decoded.userId,
                email: decoded.email,
                role: decoded.role
            };

            next();
        } catch (error) {
            if (error.name === 'TokenExpiredError') {
                return sendErrorResponse(res, 'Token expirado', 401);
            } else if (error.name === 'JsonWebTokenError') {
                return sendErrorResponse(res, 'Token inválido', 401);
            } else {
                return sendErrorResponse(res, 'Erro de autenticação', 401);
            }
        }
    };
}

/**
 * Middleware para verificar roles específicas
 * @param {Array<string>} allowedRoles - Roles permitidas
 * @returns {Function} Middleware function
 */
function createRoleMiddleware(allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            return sendErrorResponse(res, 'Usuário não autenticado', 401);
        }

        if (!allowedRoles.includes(req.user.role)) {
            return sendErrorResponse(res, 'Acesso negado: role insuficiente', 403);
        }

        next();
    };
}

/**
 * Middleware para validar store ownership
 * Verifica se o usuário tem acesso à loja especificada
 */
function createStoreAccessMiddleware() {
    return (req, res, next) => {
        // Por enquanto, todos os usuários autenticados têm acesso a todas as lojas
        // Em um cenário real, você implementaria lógica para verificar
        // se o usuário tem permissão para acessar a loja específica
        
        const storeId = req.params.storeId;
        
        if (storeId && (isNaN(storeId) || parseInt(storeId) <= 0)) {
            return sendErrorResponse(res, 'ID da loja inválido', 400);
        }

        // Adicionar storeId validado ao request
        if (storeId) {
            req.validatedStoreId = parseInt(storeId);
        }

        next();
    };
}

module.exports = {
    createAuthMiddleware,
    createRoleMiddleware,
    createStoreAccessMiddleware
};
