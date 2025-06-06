// src/middleware/validators.js
const { body, validationResult, param, check } = require('express-validator'); // Adiciona 'check'

// Middleware Handler
const handleValidationErrors = (req, res, next) => { /* ... (código anterior) ... */
    const errors = validationResult(req);
    if (!errors.isEmpty()) { return res.status(400).json({ errors: errors.array() }); }
    next();
};

// Regras de Validação
const validateRegistration = () => [ /* ... (código anterior) ... */
    body('name').trim().notEmpty().withMessage('Nome obrigatório.').isLength({ min: 2 }),
    body('email').trim().notEmpty().isEmail().withMessage('Email inválido.'),
    body('password').notEmpty().isLength({ min: 6 }).withMessage('Senha deve ter >= 6 caracteres.')
];
const validateLogin = () => [ /* ... (código anterior) ... */
    body('email').trim().notEmpty().isEmail().withMessage('Email inválido.'),
    body('password').notEmpty().withMessage('Senha obrigatória.')
];
const validateStore = () => [ /* ... (código anterior) ... */
    body('name').trim().notEmpty().withMessage('Nome da loja obrigatório.').isLength({ min: 3 }),
    body('address').optional({ checkFalsy: true }).trim().isLength({ min: 5 })
];
const validateStockItem = () => [ /* ... (código anterior - ajustado para REAL) ... */
    check('name').trim().notEmpty().withMessage('Nome do item obrigatório.').isLength({ min: 2 }),
    check('quantity').notEmpty().withMessage('Quantidade obrigatória.').isFloat({ min: 0.0 }).withMessage('Quantidade inválida.').toFloat(),
    check('category').optional({ checkFalsy: true }).trim().isString(),
    check('properties').optional().isObject().withMessage('Propriedades devem ser um objeto JSON.'),
    check('properties.barcode').optional({ checkFalsy: true }).isString().trim(),
    check('properties.description').optional({ checkFalsy: true }).isString().trim(),
    // Adicionar validações para outros campos em properties
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

module.exports = {
    handleValidationErrors, validateRegistration, validateLogin,
    validateStore, validateStockItem, validateItemGroup, validateIdParam,
    validateCustomer, validateSupplier, validateDocument, validateDocumentHeaderUpdate
};