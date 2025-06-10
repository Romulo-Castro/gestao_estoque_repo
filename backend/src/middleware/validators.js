// src/middleware/validators.js
const { body, validationResult, param, check } = require('express-validator'); // Adiciona 'check'

// Middleware Handler
// Uses `validationResult(req)` from express-validator to check accumulated
// validation errors. If any are present, it returns an HTTP 400 response with
// the error details; otherwise the request proceeds to the next middleware.
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

// Regras de Validação
const validateRegistration = () => [
    body('name')
        .trim()
        .notEmpty().withMessage('Nome obrigatório.')
        .isLength({ min: 2, max: 100 }).withMessage('Nome deve ter entre 2 e 100 caracteres.')
        .matches(/^[a-zA-ZàáâãéêíóôõúçÀÁÂÃÉÊÍÓÔÕÚÇ\s]+$/).withMessage('Nome deve conter apenas letras e espaços.')
        .escape(),
    body('email')
        .trim()
        .notEmpty().withMessage('Email obrigatório.')
        .isEmail().withMessage('Email inválido.')
        .isLength({ max: 255 }).withMessage('Email muito longo.')
        .normalizeEmail()
        .custom(async (value) => {
            // Verificar se é um domínio válido básico
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(value)) {
                throw new Error('Formato de email inválido.');
            }
            return true;
        }),    body('password')
        .notEmpty().withMessage('Senha obrigatória.')
        .isLength({ min: 8, max: 128 }).withMessage('Senha deve ter entre 8 e 128 caracteres.')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]*$/)
        .withMessage('Senha deve conter pelo menos: 1 letra minúscula, 1 maiúscula, 1 número e 1 caractere especial (@$!%*?&).')
];
const validateLogin = () => [
    body('email')
        .trim()
        .notEmpty().withMessage('Email obrigatório.')
        .isEmail().withMessage('Email inválido.')
        .normalizeEmail()
        .isLength({ max: 255 }).withMessage('Email muito longo.'),
    body('password')
        .notEmpty().withMessage('Senha obrigatória.')
        .isLength({ min: 1, max: 128 }).withMessage('Senha inválida.')
];
const validateStore = () => [
    body('name')
        .trim()
        .notEmpty().withMessage('Nome da loja obrigatório.')
        .isLength({ min: 3, max: 100 }).withMessage('Nome deve ter entre 3 e 100 caracteres.')
        .matches(/^[a-zA-ZàáâãéêíóôõúçÀÁÂÃÉÊÍÓÔÕÚÇ0-9\s\-_.]+$/).withMessage('Nome contém caracteres inválidos.')
        .escape(),
    body('address')
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ min: 5, max: 500 }).withMessage('Endereço deve ter entre 5 e 500 caracteres.')
        .escape()
];
const validateStockItem = () => [
    check('name')
        .trim()
        .notEmpty().withMessage('Nome do item obrigatório.')
        .isLength({ min: 2, max: 200 }).withMessage('Nome deve ter entre 2 e 200 caracteres.')
        .matches(/^[a-zA-ZàáâãéêíóôõúçÀÁÂÃÉÊÍÓÔÕÚÇ0-9\s\-_.()]+$/).withMessage('Nome contém caracteres inválidos.')
        .escape(),
    check('quantity')
        .notEmpty().withMessage('Quantidade obrigatória.')
        .isFloat({ min: 0.0, max: 999999.99 }).withMessage('Quantidade deve estar entre 0 e 999999.99.')
        .toFloat(),
    check('category')
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 100 }).withMessage('Categoria muito longa.')
        .escape(),
    check('properties')
        .optional()
        .isObject().withMessage('Propriedades devem ser um objeto JSON.')
        .custom((value) => {
            // Validar que o objeto não é muito grande
            const jsonString = JSON.stringify(value);
            if (jsonString.length > 10000) {
                throw new Error('Propriedades muito extensas.');
            }
            return true;
        }),
    check('properties.barcode')
        .optional({ checkFalsy: true })
        .isString()
        .trim()
        .isLength({ max: 50 }).withMessage('Código de barras muito longo.')
        .matches(/^[a-zA-Z0-9\-]+$/).withMessage('Código de barras deve conter apenas letras, números e hífens.')
        .escape(),
    check('properties.description')
        .optional({ checkFalsy: true })
        .isString()
        .trim()
        .isLength({ max: 1000 }).withMessage('Descrição muito longa.')
        .escape(),
    check('properties.unitPrice')
        .optional({ checkFalsy: true })
        .isFloat({ min: 0 }).withMessage('Preço unitário deve ser positivo.')
        .toFloat(),
    check('properties.minimumStock')
        .optional({ checkFalsy: true })
        .isFloat({ min: 0 }).withMessage('Estoque mínimo deve ser positivo.')
        .toFloat()
];

// Validação para grupos de itens
const validateItemGroup = () => [
    body('name').trim().notEmpty().withMessage('Nome do grupo obrigatório.').isLength({ min: 2 }).withMessage('Nome deve ter pelo menos 2 caracteres.'),
    body('description').optional({ checkFalsy: true }).trim().isString().withMessage('Descrição deve ser texto.'),
    body('parent_group_id').optional({ checkFalsy: true }).isInt({ min: 1 }).withMessage('ID do grupo pai inválido.')
];

// Validação para parâmetros de ID (reutilizável)
const validateIdParam = (paramName = 'id') => [
    param(paramName).isInt({ min: 1 }).withMessage(`ID inválido para '${paramName}'.`)
];

// Validação para clientes
const validateCustomer = () => [
    body('name').trim().notEmpty().withMessage('Nome do cliente obrigatório.').isLength({ min: 2 }).withMessage('Nome deve ter pelo menos 2 caracteres.'),
    body('email').optional({ checkFalsy: true }).trim().isEmail().withMessage('Email inválido.'),
    body('phone').optional({ checkFalsy: true }).trim().isString().withMessage('Telefone deve ser texto.'),
    body('address').optional({ checkFalsy: true }).trim().isString().withMessage('Endereço deve ser texto.'),
    body('notes').optional({ checkFalsy: true }).trim().isString().withMessage('Observações devem ser texto.')
];

// Validação para fornecedores
const validateSupplier = () => [
    body('name').trim().notEmpty().withMessage('Nome do fornecedor obrigatório.').isLength({ min: 2 }).withMessage('Nome deve ter pelo menos 2 caracteres.'),
    body('email').optional({ checkFalsy: true }).trim().isEmail().withMessage('Email inválido.'),
    body('phone').optional({ checkFalsy: true }).trim().isString().withMessage('Telefone deve ser texto.'),
    body('address').optional({ checkFalsy: true }).trim().isString().withMessage('Endereço deve ser texto.'),
    body('notes').optional({ checkFalsy: true }).trim().isString().withMessage('Observações devem ser texto.')
];

// Validação para criação de documentos
const validateDocument = () => [
    body('type').trim().notEmpty().withMessage('Tipo do documento obrigatório.')
        .isIn(['sale', 'purchase', 'adjustment_in', 'adjustment_out'])
        .withMessage('Tipo deve ser: sale, purchase, adjustment_in ou adjustment_out.'),
    body('document_date').notEmpty().withMessage('Data do documento obrigatória.')
        .isISO8601().withMessage('Data deve estar no formato ISO 8601 (YYYY-MM-DD).'),
    body('customerId').optional({ checkFalsy: true }).isInt({ min: 1 }).withMessage('ID do cliente inválido.'),
    body('supplierId').optional({ checkFalsy: true }).isInt({ min: 1 }).withMessage('ID do fornecedor inválido.'),
    body('notes').optional({ checkFalsy: true }).trim().isString().withMessage('Observações devem ser texto.'),
    body('total_amount').optional({ checkFalsy: true }).isFloat({ min: 0 }).withMessage('Valor total deve ser positivo.'),
    body('items').isArray({ min: 1 }).withMessage('Documento deve ter pelo menos um item.'),
    body('items.*.itemId').notEmpty().withMessage('ID do item obrigatório.').isInt({ min: 1 }).withMessage('ID do item inválido.'),
    body('items.*.quantity').notEmpty().withMessage('Quantidade obrigatória.').isFloat({ min: 0.01 }).withMessage('Quantidade deve ser positiva.'),
    body('items.*.unitPrice').optional({ checkFalsy: true }).isFloat({ min: 0 }).withMessage('Preço unitário deve ser positivo.')
];

// Validação para atualização de cabeçalho de documento (campos limitados)
const validateDocumentHeaderUpdate = () => [
    body('document_date').optional({ checkFalsy: true }).isISO8601().withMessage('Data deve estar no formato ISO 8601 (YYYY-MM-DD).'),
    body('customerId').optional({ checkFalsy: true }).isInt({ min: 1 }).withMessage('ID do cliente inválido.'),
    body('supplierId').optional({ checkFalsy: true }).isInt({ min: 1 }).withMessage('ID do fornecedor inválido.'),
    body('notes').optional({ checkFalsy: true }).trim().isString().withMessage('Observações devem ser texto.')
];

// Validação para atualização de perfil
const validateProfileUpdate = () => [
    body('name')
        .trim()
        .notEmpty().withMessage('Nome obrigatório.')
        .isLength({ min: 2, max: 100 }).withMessage('Nome deve ter entre 2 e 100 caracteres.')
        .matches(/^[a-zA-ZàáâãéêíóôõúçÀÁÂÃÉÊÍÓÔÕÚÇ\s]+$/).withMessage('Nome deve conter apenas letras e espaços.')
        .escape(),
    body('email')
        .trim()
        .notEmpty().withMessage('Email obrigatório.')
        .isEmail().withMessage('Email inválido.')
        .isLength({ max: 255 }).withMessage('Email muito longo.')
        .normalizeEmail()
];

// Validação para mudança de senha
const validatePasswordChange = () => [
    body('currentPassword')
        .notEmpty().withMessage('Senha atual obrigatória.')
        .isLength({ min: 1 }).withMessage('Senha atual inválida.'),
    body('newPassword')
        .notEmpty().withMessage('Nova senha obrigatória.')
        .isLength({ min: 8, max: 128 }).withMessage('Nova senha deve ter entre 8 e 128 caracteres.')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]*$/)
        .withMessage('Nova senha deve conter pelo menos: 1 letra minúscula, 1 maiúscula, 1 número e 1 caractere especial (@$!%*?&).')
];

module.exports = {
    handleValidationErrors, validateRegistration, validateLogin,
    validateStore, validateStockItem, validateItemGroup, validateIdParam,
    validateCustomer, validateSupplier, validateDocument, validateDocumentHeaderUpdate,
    validateProfileUpdate, validatePasswordChange
};