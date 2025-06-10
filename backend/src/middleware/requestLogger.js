// src/middleware/requestLogger.js
const morgan = require('morgan');
const config = require('../config/config');

/**
 * Middleware de logging de requisições melhorado
 */

// Criar tokens customizados para Morgan
morgan.token('id', (req) => req.id);
morgan.token('user', (req) => req.user ? req.user.userId : 'anonymous');
morgan.token('store', (req) => req.params ? req.params.storeId : '-');
morgan.token('body-size', (req) => {
    if (req.body && typeof req.body === 'object') {
        return JSON.stringify(req.body).length;
    }
    return '0';
});

// Formato customizado para logs
const customFormat = ':remote-addr - :user [:date[clf]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent" :response-time ms - User: :user - Store: :store - BodySize: :body-size';

/**
 * Logger para desenvolvimento
 */
const developmentLogger = morgan('dev', {
    skip: (req, res) => {
        // Pular logs de arquivos estáticos e health checks
        return req.url.startsWith('/uploads/') || 
               req.url === '/health' ||
               req.url === '/favicon.ico';
    }
});

/**
 * Logger para produção
 */
const productionLogger = morgan(customFormat, {
    skip: (req, res) => {
        // Em produção, só logar erros e operações importantes
        return res.statusCode < 400 && 
               (req.url.startsWith('/uploads/') || 
                req.url === '/health' ||
                req.url === '/favicon.ico');
    },
    stream: {
        write: (message) => {
            // Integração com sistema de logs externo seria aqui
            console.log(message.trim());
        }
    }
});

/**
 * Logger de segurança para eventos críticos
 */
const securityLogger = (req, res, next) => {
    // Adicionar ID único à requisição
    req.id = Date.now().toString(36) + Math.random().toString(36).substr(2);
    
    // Logar eventos de segurança
    const originalSend = res.send;
    res.send = function(body) {
        // Logar falhas de autenticação
        if (req.path.includes('/auth/') && res.statusCode === 401) {
            console.warn(`🔐 [AUTH_FAILED] ${req.id} - IP: ${req.ip} - Email: ${req.body?.email} - UA: ${req.get('User-Agent')}`);
        }
        
        // Logar tentativas de acesso não autorizado
        if (res.statusCode === 403) {
            console.warn(`🚫 [ACCESS_DENIED] ${req.id} - IP: ${req.ip} - URL: ${req.originalUrl} - User: ${req.user?.userId || 'anonymous'}`);
        }
        
        // Logar erros do servidor
        if (res.statusCode >= 500) {
            console.error(`💥 [SERVER_ERROR] ${req.id} - IP: ${req.ip} - URL: ${req.originalUrl} - Status: ${res.statusCode}`);
        }
        
        return originalSend.call(this, body);
    };
    
    next();
};

/**
 * Middleware de métricas simples
 */
const metricsCollector = (req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = Date.now() - start;
        
        // Logar requisições lentas (> 1 segundo)
        if (duration > 1000) {
            console.warn(`🐌 [SLOW_REQUEST] ${req.id} - ${req.method} ${req.originalUrl} - ${duration}ms`);
        }
        
        // Coletar métricas básicas (seria enviado para sistema de monitoramento)
        if (global.metrics) {
            global.metrics.requests = (global.metrics.requests || 0) + 1;
            global.metrics.totalResponseTime = (global.metrics.totalResponseTime || 0) + duration;
        }
    });
    
    next();
};

/**
 * Escolher logger baseado no ambiente
 */
const getRequestLogger = () => {
    if (config.server.environment === 'development') {
        return [securityLogger, metricsCollector, developmentLogger];
    } else {
        return [securityLogger, metricsCollector, productionLogger];
    }
};

module.exports = {
    getRequestLogger,
    securityLogger,
    metricsCollector,
    developmentLogger,
    productionLogger
};
