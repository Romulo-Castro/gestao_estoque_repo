// src/config/config.js
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

/**
 * Configuração centralizada da aplicação
 */
const config = {
    // Configurações do servidor
    server: {
        port: parseInt(process.env.PORT) || 3000,
        host: process.env.HOST || 'localhost',
        baseUrl: process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`,
        environment: process.env.NODE_ENV || 'development'
    },

    // Configurações do banco de dados
    database: {
        path: process.env.SQLITE_PATH || path.resolve(__dirname, '../../inventory_data.db'),
        enableForeignKeys: true,
        busyTimeout: 30000,
        pragma: {
            journal_mode: 'WAL',
            cache_size: -16384, // 16MB cache
            temp_store: 'memory',
            synchronous: 'NORMAL'
        }
    },

    // Configurações de JWT
    jwt: {
        secret: process.env.JWT_SECRET,
        expiresIn: process.env.JWT_EXPIRES_IN || '24h',
        issuer: 'gestao-estoque-api',
        audience: 'gestao-estoque-app'
    },

    // Configurações de upload
    upload: {
        directory: process.env.UPLOAD_FOLDER || 'uploads',
        maxFileSize: 10 * 1024 * 1024, // 10MB
        allowedMimeTypes: [
            'image/jpeg',
            'image/jpg', 
            'image/png',
            'image/gif',
            'image/webp'
        ],
        allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp']
    },

    // Configurações de segurança
    security: {
        bcryptRounds: 12,
        maxLoginAttempts: 5,
        lockoutTime: 15 * 60 * 1000, // 15 minutos
        rateLimits: {
            general: {
                windowMs: 15 * 60 * 1000, // 15 minutos
                max: 1000 // máximo 1000 requests por IP por janela
            },
            auth: {
                windowMs: 15 * 60 * 1000, // 15 minutos
                max: 10 // máximo 10 tentativas de login por IP por janela
            },
            upload: {
                windowMs: 15 * 60 * 1000, // 15 minutos
                max: 50 // máximo 50 uploads por IP por janela
            }
        }
    },

    // Configurações de CORS
    cors: {
        origin: process.env.CORS_ORIGIN ? 
            process.env.CORS_ORIGIN.split(',').map(origin => origin.trim()) : 
            ['http://localhost:3000', 'http://localhost:8080'],
        credentials: true,
        optionsSuccessStatus: 200
    },

    // Configurações de logs
    logging: {
        level: process.env.LOG_LEVEL || 'info',
        format: process.env.LOG_FORMAT || 'combined',
        enableRequestId: true
    }
};

/**
 * Validação da configuração
 */
const validateConfig = () => {
    const errors = [];

    if (!config.jwt.secret) {
        errors.push('JWT_SECRET é obrigatório');
    }

    if (config.jwt.secret && config.jwt.secret.length < 32) {
        errors.push('JWT_SECRET deve ter pelo menos 32 caracteres');
    }

    if (config.server.port < 1 || config.server.port > 65535) {
        errors.push('PORT deve estar entre 1 e 65535');
    }

    if (errors.length > 0) {
        console.error('❌ Erros de configuração:');
        errors.forEach(error => console.error(`  - ${error}`));
        process.exit(1);
    }

    console.log('✅ Configuração validada com sucesso');
};

// Validar configuração na inicialização
if (require.main === module) {
    validateConfig();
} else {
    // Validar apenas se não for um import de teste
    if (process.env.NODE_ENV !== 'test') {
        validateConfig();
    }
}

module.exports = config;
