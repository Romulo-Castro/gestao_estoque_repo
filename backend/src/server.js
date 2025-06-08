// src/server.js

// Carrega variáveis do .env O MAIS CEDO POSSÍVEL, especialmente se DB config depende delas
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') }); // Garante que carrega da pasta backend

const express = require('express');
const cors = require('cors');
const path = require('path');
const dbSetup = require('./data/database'); // Importa o setup do DB SQLite

// Importar middleware de segurança
const {
    generalLimiter,
    authLimiter,
    uploadLimiter,
    helmetConfig,
    securityLogger,
    detectSuspiciousActivity
} = require('./middleware/securityMiddleware');

// Importar arquivos de ROTA PRINCIPAL (outras rotas serão montadas dentro delas)
const authRoutes = require('./routes/authRoutes'); // Assumindo que você criará este
const storeRoutes = require('./routes/storeRoutes'); // Assumindo que você criará este (e ele montará stockRoutes)
// Não importar stockRoutes diretamente aqui se for montado DENTRO de storeRoutes

const app = express();
const PORT = process.env.PORT || 3000;
const UPLOAD_DIR = process.env.UPLOAD_FOLDER || 'uploads';

// --- Função Async para Iniciar o Servidor ---
async function startServer() {
    try {
        // 1. Conectar ao DB e Criar/Verificar Tabelas ANTES de iniciar o servidor web
        console.log("Iniciando conexão com o banco de dados...");
        await dbSetup.connectDb();
        console.log("Iniciando criação/verificação de tabelas...");
        await dbSetup.createTables();
        console.log("Configuração do banco de dados concluída.");        // === Middleware de Segurança ===
        // Helmet para headers de segurança
        app.use(helmetConfig);
        
        // Morgan para logging HTTP
        app.use(securityLogger);
        
        // Rate limiting geral
        app.use(generalLimiter);
        
        // Detecção de atividade suspeita
        app.use(detectSuspiciousActivity);

        // === Middleware Essencial ===
        app.use(cors()); // Habilitar CORS
        app.use(express.json({ limit: '10mb' })); // Parsear JSON com limite
        app.use(express.urlencoded({ extended: true, limit: '10mb' })); // Parsear URL-encoded com limite

        // Servir arquivos estáticos da pasta de uploads
        const uploadsAbsolutePath = path.join(__dirname, '../', UPLOAD_DIR);
        console.log(`Configurando rota estática para /${UPLOAD_DIR} em ${uploadsAbsolutePath}`);
        // IMPORTANTE: A URL base será relativa à raiz do servidor. Ex: http://localhost:3000/uploads/arquivo.jpg
        app.use(`/${UPLOAD_DIR}`, express.static(uploadsAbsolutePath));        // === Rotas da API ===
        console.log("Configurando rotas da API...");
        
        // Health check endpoint (sem rate limiting)
        app.get('/health', (req, res) => {
            res.status(200).json({
                status: 'ok',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                environment: process.env.NODE_ENV || 'production'
            });
        });
        
        // Rota raiz da API para teste
        app.get('/api', (req, res) => {
            res.send('API Gestão de Estoques (SQLite) está funcionando!');
        });// Montar rotas de Autenticação com rate limiting específico
        // Exemplo: /api/auth/login, /api/auth/register
        app.use('/api/auth', authLimiter, authRoutes);

        // Montar rotas de Lojas (que incluirão as rotas de estoque aninhadas)
        // Exemplo: GET /api/stores, POST /api/stores, GET /api/stores/:storeId,
        //          GET /api/stores/:storeId/stock, POST /api/stores/:storeId/stock/:itemId/image etc.
        app.use('/api/stores', storeRoutes);

        // Montar outras rotas de nível superior ou aninhadas aqui (ex: usuários, relatórios gerais)
        // app.use('/api/users', userRoutes); // Se houver rotas diretas de usuário
        // app.use('/api/reports', reportRoutes); // Se houver relatórios gerais

        console.log("Rotas configuradas.");

        // === Tratamento de Erros (DEPOIS das rotas) ===
        // Middleware 404 (Rota não encontrada)
        app.use((req, res, next) => {
            if (!res.headersSent) { // Verifica se a resposta já não foi enviada
                 res.status(404).json({ message: 'Endpoint não encontrado.' });
            }
            // Não chamar next() aqui se for 404 definitivo
        });        // Import the centralized error handler
        const { globalErrorHandler } = require('./utils/errorHandler');

        // Use the centralized global error handler
        app.use(globalErrorHandler);

        // === Iniciar o Servidor ===
        app.listen(PORT, () => {
            console.log(`\nServidor backend (SQLite) rodando na porta ${PORT}`);
            console.log(`Ambiente: ${process.env.NODE_ENV || 'produção (padrão)'}`);
            console.log(`Uploads em: ${uploadsAbsolutePath}`);
            console.log(`URL base para imagens: ${process.env.BASE_URL || `http://localhost:${PORT}`}/${UPLOAD_DIR}/`);
            console.log(`Acesse a API em: http://localhost:${PORT}/api`);
        });

    } catch (error) {
        console.error("!!! FALHA CRÍTICA AO INICIAR O SERVIDOR !!!");
        console.error(error);
        process.exit(1); // Encerra o processo se a inicialização falhar
    }
}

// --- Executar a inicialização ---
startServer();