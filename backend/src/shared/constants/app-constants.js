// Application Constants
module.exports = {
    // Document Types
    DOCUMENT_TYPES: {
        ENTRADA: 'ENTRADA',
        SAIDA: 'SAIDA',
        BALANCA: 'BALANCA'
    },

    // Document Status
    DOCUMENT_STATUS: {
        ACTIVE: 'ATIVO',
        CANCELLED: 'CANCELADO',
        PENDING: 'PENDENTE'
    },

    // User Roles
    USER_ROLES: {
        OWNER: 'owner',
        ADMIN: 'admin',
        MANAGER: 'manager',
        EMPLOYEE: 'employee'
    },

    // Default Values
    DEFAULTS: {
        CURRENCY: 'BRL',
        UNIT: 'un',
        LOW_STOCK_THRESHOLD: 10,
        PAGE_SIZE: 50,
        MAX_PAGE_SIZE: 100
    },

    // Business Rules
    BUSINESS_RULES: {
        MAX_DOCUMENT_ITEMS: 100,
        MIN_PASSWORD_LENGTH: 6,
        MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
        ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    },

    // API Limits
    RATE_LIMITS: {
        WINDOW_MS: 15 * 60 * 1000, // 15 minutes
        MAX_REQUESTS: 100
    },

    // Time Periods
    TIME_PERIODS: {
        TODAY: 'today',
        YESTERDAY: 'yesterday',
        THIS_WEEK: 'thisWeek',
        LAST_WEEK: 'lastWeek',
        THIS_MONTH: 'thisMonth',
        LAST_MONTH: 'lastMonth',
        THIS_QUARTER: 'thisQuarter',
        LAST_QUARTER: 'lastQuarter',
        THIS_YEAR: 'thisYear',
        LAST_YEAR: 'lastYear',
        CUSTOM: 'custom'
    },

    // HTTP Status Codes (for reference)
    HTTP_STATUS: {
        OK: 200,
        CREATED: 201,
        NO_CONTENT: 204,
        BAD_REQUEST: 400,
        UNAUTHORIZED: 401,
        FORBIDDEN: 403,
        NOT_FOUND: 404,
        CONFLICT: 409,
        UNPROCESSABLE_ENTITY: 422,
        TOO_MANY_REQUESTS: 429,
        INTERNAL_SERVER_ERROR: 500,
        NOT_IMPLEMENTED: 501,
        SERVICE_UNAVAILABLE: 503
    }
};
