// src/utils/errorHandler.js
// Centralized error handling utility for consistent error responses

/**
 * Custom application error class
 */
class AppError extends Error {
    constructor(message, statusCode = 500, isOperational = true) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = isOperational;
        this.status = statusCode >= 400 && statusCode < 500 ? 'fail' : 'error';

        Error.captureStackTrace(this, this.constructor);
    }
}

/**
 * Database error handler - converts common database errors to user-friendly messages
 */
const handleDatabaseError = (error) => {
    if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
        return new AppError('Este registro já existe no sistema.', 409);
    }
    
    if (error.code === 'SQLITE_CONSTRAINT_FOREIGNKEY' || 
        (error.message && error.message.includes('FOREIGN KEY constraint failed'))) {
        return new AppError('Não é possível executar esta operação pois existem registros relacionados.', 400);
    }
    
    if (error.code === 'SQLITE_CONSTRAINT_NOTNULL') {
        return new AppError('Campos obrigatórios não foram preenchidos.', 400);
    }
    
    if (error.message && error.message.includes('no such table')) {
        return new AppError('Erro interno: estrutura do banco de dados não encontrada.', 500);
    }
    
    return new AppError('Erro interno do servidor.', 500);
};

/**
 * Validation error handler for express-validator errors
 */
const handleValidationError = (errors) => {
    const messages = errors.map(err => err.msg).join('; ');
    return new AppError(`Dados inválidos: ${messages}`, 400);
};

/**
 * JWT error handler
 */
const handleJWTError = (error) => {
    if (error.name === 'TokenExpiredError') {
        return new AppError('Token expirado. Faça login novamente.', 401);
    }
    if (error.name === 'JsonWebTokenError') {
        return new AppError('Token inválido. Faça login novamente.', 401);
    }
    return new AppError('Erro de autenticação.', 401);
};

/**
 * Multer error handler for file upload errors
 */
const handleMulterError = (error) => {
    if (error.code === 'LIMIT_FILE_SIZE') {
        return new AppError('Arquivo muito grande. Tamanho máximo permitido: 5MB', 400);
    }
    if (error.code === 'LIMIT_FILE_COUNT') {
        return new AppError('Muitos arquivos enviados.', 400);
    }
    if (error.code === 'LIMIT_UNEXPECTED_FILE') {
        return new AppError('Campo de arquivo inesperado.', 400);
    }
    return new AppError('Erro no upload do arquivo.', 400);
};

/**
 * Async wrapper to catch errors in async route handlers
 */
const catchAsync = (fn) => {
    return (req, res, next) => {
        fn(req, res, next).catch(next);
    };
};

/**
 * Standard error response format
 */
const sendErrorResponse = (res, error, req = null) => {
    const isDevelopment = process.env.NODE_ENV === 'development';
    
    // Log error for debugging
    console.error(`[${new Date().toISOString()}] Error in ${req ? `${req.method} ${req.path}` : 'Unknown endpoint'}:`, {
        message: error.message,
        statusCode: error.statusCode,
        stack: isDevelopment ? error.stack : undefined,
        ...(req && { userId: req.user?.userId, storeId: req.params?.storeId })
    });

    const response = {
        status: error.status || 'error',
        message: error.message || 'Erro interno do servidor'
    };

    // Include stack trace in development
    if (isDevelopment && error.stack) {
        response.stack = error.stack;
    }

    res.status(error.statusCode || 500).json(response);
};

/**
 * Global error handling middleware
 */
const globalErrorHandler = (err, req, res, next) => {
    if (res.headersSent) {
        return next(err);
    }

    let error = { ...err };
    error.message = err.message;

    // Handle different error types
    if (err.code && err.code.startsWith('SQLITE_')) {
        error = handleDatabaseError(err);
    } else if (err.name === 'TokenExpiredError' || err.name === 'JsonWebTokenError') {
        error = handleJWTError(err);
    } else if (err.name === 'MulterError') {
        error = handleMulterError(err);
    } else if (!err.isOperational) {
        // Programming or unknown error - don't leak details in production
        error = new AppError('Algo deu errado!', 500);
    }

    sendErrorResponse(res, error, req);
};

/**
 * Standard success response format
 */
const sendSuccessResponse = (res, data, message = 'Operação realizada com sucesso', statusCode = 200) => {
    res.status(statusCode).json({
        status: 'success',
        message,
        data
    });
};

/**
 * Validation helpers
 */
const validateRequiredFields = (data, requiredFields) => {
    const missing = requiredFields.filter(field => !data[field] || data[field].toString().trim() === '');
    if (missing.length > 0) {
        throw new AppError(`Campos obrigatórios não preenchidos: ${missing.join(', ')}`, 400);
    }
};

const validateId = (id, fieldName = 'ID') => {
    const parsedId = parseInt(id, 10);
    if (isNaN(parsedId) || parsedId <= 0) {
        throw new AppError(`${fieldName} inválido.`, 400);
    }
    return parsedId;
};

/**
 * Resource not found helper
 */
const notFound = (resource = 'Recurso') => {
    throw new AppError(`${resource} não encontrado.`, 404);
};

/**
 * Unauthorized access helper
 */
const unauthorized = (message = 'Acesso não autorizado.') => {
    throw new AppError(message, 401);
};

/**
 * Forbidden access helper
 */
const forbidden = (message = 'Acesso negado.') => {
    throw new AppError(message, 403);
};

module.exports = {
    AppError,
    catchAsync,
    globalErrorHandler,
    sendErrorResponse,
    sendSuccessResponse,
    handleDatabaseError,
    handleValidationError,
    handleJWTError,
    handleMulterError,
    validateRequiredFields,
    validateId,
    notFound,
    unauthorized,
    forbidden
};
