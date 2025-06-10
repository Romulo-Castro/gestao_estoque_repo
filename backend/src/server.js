// src/server.js

// Carrega configuração centralizada O MAIS CEDO POSSÍVEL
const config = require('./config/config');

const express = require('express');
const cors = require('cors');
const path = require('path');
const dbSetup = require('./data/database');

// Importar middlewares melhorados
const {
    generalLimiter,
    authLimiter,
    uploadLimiter,
    helmetConfig,
    securityLogger,
    detectSuspiciousActivity,
    validateFileUpload
} = require('./middleware/securityMiddleware');

const { getRequestLogger } = require('./middleware/requestLogger');
const {
    collectMetrics,
    healthCheckEndpoint,
    metricsEndpoint,
    readinessCheck,
    livenessCheck,
    resetMetrics
} = require('./middleware/healthCheck');

// Importar rotas
const authRoutes = require('./routes/authRoutes');
const storeRoutes = require('./routes/storeRoutes');
const apiDocsRoutes = require('./routes/apiDocsRoutes');

const app = express();
const PORT = config.server.port;
const UPLOAD_DIR = config.upload.directory;

// Inicializar métricas globais
global.metrics = { requests: 0, totalResponseTime: 0 };

/**
 * Função para graceful shutdown
 */
const gracefulShutdown = (signal) => {
    console.log(`\n📡 Recebido sinal ${signal}. Iniciando graceful shutdown...`);
    
    process.exit(0);
};

// Configurar handlers para shutdown
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handler para erros não capturados
process.on('uncaughtException', (error) => {
    console.error('💥 [UNCAUGHT_EXCEPTION]', error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('💥 [UNHANDLED_REJECTION]', reason);
    process.exit(1);
});

/**
 * Função principal para iniciar o servidor
 */
async function startServer() {
    try {
        console.log('🚀 Iniciando servidor backend...');
        console.log(`📊 Ambiente: ${config.server.environment}`);
        console.log(`🌐 Porta: ${PORT}`);
        
        // 1. Conectar ao banco de dados
        console.log("📀 Iniciando conexão com o banco de dados...");
        await dbSetup.connectDb();
        console.log("📋 Criando/verificando tabelas...");
        await dbSetup.createTables();
        console.log("✅ Configuração do banco de dados concluída.");

        // === Middlewares de Segurança (ordem importa!) ===
        app.use(helmetConfig);
        app.use(detectSuspiciousActivity);
        app.use(collectMetrics);
        
        // === Middlewares de Logging ===
        const requestLoggers = getRequestLogger();
        requestLoggers.forEach(logger => app.use(logger));
        
        // === Rate Limiting ===
        app.use(generalLimiter);
        
        // === Middlewares Essenciais ===
        app.use(cors(config.cors));
        app.use(express.json({ 
            limit: '10mb',
            verify: (req, res, buf) => {
                // Log de payloads grandes
                if (buf.length > 1024 * 1024) { // > 1MB
                    console.warn(`📦 [LARGE_PAYLOAD] ${buf.length} bytes from ${req.ip}`);
                }
            }
        }));
        app.use(express.urlencoded({ 
            extended: true, 
            limit: '10mb' 
        }));

        // === Arquivos Estáticos ===
        const uploadsAbsolutePath = path.join(__dirname, '../', UPLOAD_DIR);
        console.log(`📁 Configurando arquivos estáticos: /${UPLOAD_DIR} -> ${uploadsAbsolutePath}`);
        app.use(`/${UPLOAD_DIR}`, express.static(uploadsAbsolutePath));

        // === Endpoints de Monitoramento ===
        app.get('/health', healthCheckEndpoint);
        app.get('/health/ready', readinessCheck);
        app.get('/health/live', livenessCheck);
        app.get('/metrics', metricsEndpoint);
        
        // Endpoint para reset de métricas (só em desenvolvimento)
        if (config.server.environment === 'development') {
            app.get('/metrics/reset', resetMetrics);
        }

        // === API Principal ===
        console.log("🛣️  Configurando rotas da API...");
          // Rota raiz com informações da API
        app.get('/api', (req, res) => {
            res.json({
                name: 'Gestão de Estoques API',
                version: '2.0.0',
                environment: config.server.environment,
                timestamp: new Date().toISOString(),
                endpoints: {
                    auth: '/api/auth',
                    stores: '/api/stores',
                    documentation: '/api-docs',
                    health: '/health',
                    metrics: '/metrics'
                }
            });
        });// Montar rotas principais
        app.use('/api/auth', authLimiter, authRoutes);
        app.use('/api/stores', storeRoutes);
        app.use('/api-docs', apiDocsRoutes);

        console.log("✅ Rotas configuradas com sucesso.");

        // === Middleware de Tratamento de Erros ===
        // 404 para rotas não encontradas
        app.use('*', (req, res) => {
            console.warn(`🔍 [404] ${req.method} ${req.originalUrl} - IP: ${req.ip}`);
            res.status(404).json({
                success: false,
                message: 'Endpoint não encontrado',
                timestamp: new Date().toISOString(),
                path: req.originalUrl,
                method: req.method
            });
        });

        // Handler global de erros
        const { globalErrorHandler } = require('./utils/errorHandler');
        app.use(globalErrorHandler);

        // === Iniciar Servidor ===
        const server = app.listen(PORT, () => {
            console.log(`\n🎉 =============================================`);
            console.log(`🚀 Servidor iniciado com sucesso!`);
            console.log(`🌐 URL: ${config.server.baseUrl}`);
            console.log(`📊 Ambiente: ${config.server.environment}`);
            console.log(`📁 Uploads: ${uploadsAbsolutePath}`);
            console.log(`🔒 Segurança: Ativada`);
            console.log(`📈 Monitoramento: /health, /metrics`);
            console.log(`📚 API Docs: ${config.server.baseUrl}/api`);
            console.log(`===============================================\n`);
        });

        // Configurar timeout do servidor
        server.timeout = 30000; // 30 segundos

        return server;

    } catch (error) {
        console.error("💥 FALHA CRÍTICA AO INICIAR O SERVIDOR:");
        console.error(error);
        process.exit(1);
    }
}

// Executar inicialização apenas se este arquivo for executado diretamente
if (require.main === module) {
    startServer();
}

module.exports = { startServer, app };