// Application Configuration
require('dotenv').config();

const config = {
    // Server Configuration
    server: {
        port: process.env.PORT || 3000,
        host: process.env.HOST || 'localhost',
        baseUrl: process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`,
        environment: process.env.NODE_ENV || 'development'
    },

    // Database Configuration
    database: {
        path: process.env.DB_PATH || './inventory_data.db',
        enableForeignKeys: true,
        busyTimeout: 30000
    },

    // JWT Configuration
    jwt: {
        secret: process.env.JWT_SECRET,
        expiresIn: process.env.JWT_EXPIRES_IN || '1d',
        issuer: process.env.JWT_ISSUER || 'gestao-estoque',
        audience: process.env.JWT_AUDIENCE || 'gestao-estoque-users'
    },

    // Upload Configuration
    upload: {
        folder: process.env.UPLOAD_FOLDER || 'uploads',
        maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024, // 5MB
        allowedTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
        maxFiles: 1
    },

    // CORS Configuration
    cors: {
        origin: process.env.CORS_ORIGIN || '*',
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization'],
        credentials: true
    },

    // Rate Limiting
    rateLimit: {
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 15 * 60 * 1000, // 15 minutes
        max: parseInt(process.env.RATE_LIMIT_MAX) || 100, // limit each IP to 100 requests per windowMs
        message: 'Too many requests from this IP, please try again later'
    },

    // Logging Configuration
    logging: {
        level: process.env.LOG_LEVEL || 'info',
        format: process.env.LOG_FORMAT || 'combined',
        file: {
            enabled: process.env.LOG_TO_FILE === 'true',
            filename: process.env.LOG_FILE || 'app.log',
            maxSize: process.env.LOG_MAX_SIZE || '10m',
            maxFiles: parseInt(process.env.LOG_MAX_FILES) || 5
        }
    },

    // Security Configuration
    security: {
        bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS) || 10,
        sessionSecret: process.env.SESSION_SECRET || 'default-session-secret',
        csrfProtection: process.env.CSRF_PROTECTION === 'true'
    },

    // Business Rules
    business: {
        lowStockThreshold: parseInt(process.env.LOW_STOCK_THRESHOLD) || 10,
        defaultCurrency: process.env.DEFAULT_CURRENCY || 'BRL',
        maxDocumentItems: parseInt(process.env.MAX_DOCUMENT_ITEMS) || 100,
        documentNumberPrefix: process.env.DOCUMENT_NUMBER_PREFIX || 'DOC'
    },

    // Feature Flags
    features: {
        bulkImport: process.env.FEATURE_BULK_IMPORT !== 'false',
        advancedReports: process.env.FEATURE_ADVANCED_REPORTS !== 'false',
        notifications: process.env.FEATURE_NOTIFICATIONS !== 'false',
        auditLogs: process.env.FEATURE_AUDIT_LOGS !== 'false'
    }
};

// Validation
const validateConfig = () => {
    const errors = [];

    if (!config.jwt.secret) {
        errors.push('JWT_SECRET is required');
    }

    if (config.jwt.secret && config.jwt.secret.length < 32) {
        errors.push('JWT_SECRET must be at least 32 characters long');
    }

    if (!config.database.path) {
        errors.push('DB_PATH is required');
    }

    if (errors.length > 0) {
        throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
    }
};

// Validate configuration on load
validateConfig();

module.exports = config;
