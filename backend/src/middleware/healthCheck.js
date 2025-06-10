// src/middleware/healthCheck.js
const config = require('../config/config');
const db = require('../data/database');

/**
 * Sistema de monitoramento de saúde da aplicação
 */

// Armazenar métricas básicas
const metrics = {
    startTime: Date.now(),
    requests: 0,
    errors: 0,
    dbQueries: 0,
    dbErrors: 0,
    lastError: null,
    uptime: () => Date.now() - metrics.startTime
};

/**
 * Middleware para coletar métricas
 */
const collectMetrics = (req, res, next) => {
    metrics.requests++;
    
    // Interceptar respostas de erro
    const originalSend = res.send;
    res.send = function(body) {
        if (res.statusCode >= 400) {
            metrics.errors++;
            if (res.statusCode >= 500) {
                metrics.lastError = {
                    timestamp: new Date().toISOString(),
                    status: res.statusCode,
                    url: req.originalUrl,
                    method: req.method,
                    userAgent: req.get('User-Agent'),
                    ip: req.ip
                };
            }
        }
        return originalSend.call(this, body);
    };
    
    next();
};

/**
 * Verificar saúde do banco de dados
 */
const checkDatabaseHealth = async () => {
    return new Promise((resolve) => {
        const startTime = Date.now();
        
        // Executar uma query simples para testar conectividade
        db.get("SELECT 1 as test", [], (err, row) => {
            const responseTime = Date.now() - startTime;
            
            if (err) {
                metrics.dbErrors++;
                resolve({
                    status: 'unhealthy',
                    error: err.message,
                    responseTime
                });
            } else {
                metrics.dbQueries++;
                resolve({
                    status: 'healthy',
                    responseTime
                });
            }
        });
    });
};

/**
 * Verificar uso de memória
 */
const getMemoryUsage = () => {
    const usage = process.memoryUsage();
    return {
        rss: Math.round(usage.rss / 1024 / 1024), // MB
        heapTotal: Math.round(usage.heapTotal / 1024 / 1024), // MB
        heapUsed: Math.round(usage.heapUsed / 1024 / 1024), // MB
        external: Math.round(usage.external / 1024 / 1024), // MB
        heapUsedPercentage: Math.round((usage.heapUsed / usage.heapTotal) * 100)
    };
};

/**
 * Endpoint principal de health check
 */
const healthCheckEndpoint = async (req, res) => {
    const detailed = req.query.detailed === 'true';
    
    try {
        const dbHealth = await checkDatabaseHealth();
        const memory = getMemoryUsage();
        const uptime = metrics.uptime();
        
        // Determinar status geral
        let status = 'healthy';
        const issues = [];
        
        if (dbHealth.status === 'unhealthy') {
            status = 'unhealthy';
            issues.push('Database connection failed');
        }
        
        if (memory.heapUsedPercentage > 90) {
            status = 'degraded';
            issues.push('High memory usage');
        }
        
        if (dbHealth.responseTime > 1000) {
            status = 'degraded';
            issues.push('Slow database response');
        }
        
        // Resposta básica
        const response = {
            status,
            timestamp: new Date().toISOString(),
            uptime: Math.round(uptime / 1000), // segundos
            version: process.env.npm_package_version || '1.0.0',
            environment: config.server.environment
        };
        
        // Adicionar detalhes se solicitado
        if (detailed) {
            response.details = {
                database: dbHealth,
                memory,
                metrics: {
                    totalRequests: metrics.requests,
                    totalErrors: metrics.errors,
                    errorRate: metrics.requests > 0 ? 
                        Math.round((metrics.errors / metrics.requests) * 100) : 0,
                    dbQueries: metrics.dbQueries,
                    dbErrors: metrics.dbErrors
                },
                lastError: metrics.lastError,
                issues: issues.length > 0 ? issues : null
            };
        }
        
        // Definir status HTTP baseado na saúde
        let httpStatus = 200;
        if (status === 'degraded') httpStatus = 200; // Warning, mas ainda funcional
        if (status === 'unhealthy') httpStatus = 503; // Service unavailable
        
        res.status(httpStatus).json(response);
        
    } catch (error) {
        console.error('Erro no health check:', error);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: 'Health check failed',
            details: error.message
        });
    }
};

/**
 * Endpoint para métricas básicas (útil para monitoramento)
 */
const metricsEndpoint = (req, res) => {
    const uptime = metrics.uptime();
    const memory = getMemoryUsage();
    
    res.json({
        uptime: Math.round(uptime / 1000),
        requests: metrics.requests,
        errors: metrics.errors,
        errorRate: metrics.requests > 0 ? 
            Math.round((metrics.errors / metrics.requests) * 100) : 0,
        dbQueries: metrics.dbQueries,
        dbErrors: metrics.dbErrors,
        memory,
        timestamp: new Date().toISOString()
    });
};

/**
 * Endpoint para readiness check (verifica se a aplicação está pronta)
 */
const readinessCheck = async (req, res) => {
    try {
        const dbHealth = await checkDatabaseHealth();
        
        if (dbHealth.status === 'healthy') {
            res.status(200).json({
                status: 'ready',
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(503).json({
                status: 'not ready',
                reason: 'Database not available',
                timestamp: new Date().toISOString()
            });
        }
    } catch (error) {
        res.status(503).json({
            status: 'not ready',
            reason: 'Health check failed',
            timestamp: new Date().toISOString()
        });
    }
};

/**
 * Endpoint para liveness check (verifica se a aplicação está viva)
 */
const livenessCheck = (req, res) => {
    // Verificação simples - se chegou até aqui, a aplicação está viva
    res.status(200).json({
        status: 'alive',
        uptime: Math.round(metrics.uptime() / 1000),
        timestamp: new Date().toISOString()
    });
};

/**
 * Resetar métricas (útil para testes)
 */
const resetMetrics = (req, res) => {
    if (config.server.environment !== 'development') {
        return res.status(403).json({
            error: 'Metrics reset only available in development'
        });
    }
    
    metrics.requests = 0;
    metrics.errors = 0;
    metrics.dbQueries = 0;
    metrics.dbErrors = 0;
    metrics.lastError = null;
    
    res.json({
        message: 'Metrics reset successfully',
        timestamp: new Date().toISOString()
    });
};

module.exports = {
    collectMetrics,
    healthCheckEndpoint,
    metricsEndpoint,
    readinessCheck,
    livenessCheck,
    resetMetrics,
    checkDatabaseHealth,
    metrics
};
