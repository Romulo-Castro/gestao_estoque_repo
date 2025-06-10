// src/routes/apiDocsRoutes.js
/**
 * Rotas para documentação da API
 */
const express = require('express');
const router = express.Router();

// Rota principal da documentação
router.get('/', (req, res) => {
    res.json({
        name: 'Gestão de Estoques API',
        version: '2.0.0',
        description: 'API RESTful para sistema de gestão de estoques',
        endpoints: {
            auth: {
                path: '/api/auth',
                methods: ['POST', 'GET', 'PUT'],
                description: 'Endpoints de autenticação e gerenciamento de usuários'
            },
            stores: {
                path: '/api/stores',
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                description: 'Endpoints para gerenciamento de lojas'
            },
            stock: {
                path: '/api/stores/:storeId/stock',
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                description: 'Endpoints para gerenciamento de estoque'
            },
            itemGroups: {
                path: '/api/stores/:storeId/item-groups',
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                description: 'Endpoints para gerenciamento de grupos de itens'
            },
            customers: {
                path: '/api/stores/:storeId/customers',
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                description: 'Endpoints para gerenciamento de clientes'
            },
            suppliers: {
                path: '/api/stores/:storeId/suppliers',
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                description: 'Endpoints para gerenciamento de fornecedores'
            },
            documents: {
                path: '/api/stores/:storeId/documents',
                methods: ['GET', 'POST', 'PUT', 'DELETE'],
                description: 'Endpoints para gerenciamento de documentos (vendas e compras)'
            }
        },
        monitoring: {
            health: '/health',
            metrics: '/metrics'
        }
    });
});

// Documentação detalhada da API de autenticação
router.get('/auth', (req, res) => {
    res.json({
        name: 'API de Autenticação',
        basePath: '/api/auth',
        endpoints: [
            {
                path: '/register',
                method: 'POST',
                description: 'Registrar um novo usuário',
                body: {
                    name: 'Nome completo do usuário',
                    email: 'Email único do usuário',
                    password: 'Senha do usuário (min 8 caracteres)'
                },
                response: {
                    user: 'Dados do usuário criado (sem senha)',
                    token: 'Token JWT para autenticação'
                }
            },
            {
                path: '/login',
                method: 'POST',
                description: 'Autenticar um usuário existente',
                body: {
                    email: 'Email do usuário',
                    password: 'Senha do usuário'
                },
                response: {
                    user: 'Dados do usuário (sem senha)',
                    token: 'Token JWT para autenticação'
                }
            },
            {
                path: '/me',
                method: 'GET',
                description: 'Obter dados do usuário logado',
                auth: 'JWT Bearer Token necessário',
                response: {
                    user: 'Dados do usuário (sem senha)'
                }
            },
            {
                path: '/profile',
                method: 'PUT',
                description: 'Atualizar perfil do usuário',
                auth: 'JWT Bearer Token necessário',
                body: {
                    name: 'Nome completo do usuário',
                    email: 'Email do usuário'
                },
                response: {
                    user: 'Dados do usuário atualizados (sem senha)'
                }
            },
            {
                path: '/change-password',
                method: 'PUT',
                description: 'Alterar senha do usuário',
                auth: 'JWT Bearer Token necessário',
                body: {
                    currentPassword: 'Senha atual',
                    newPassword: 'Nova senha (min 8 caracteres)'
                },
                response: {
                    message: 'Confirmação de alteração'
                }
            }
        ]
    });
});

// Aqui poderia ter mais endpoints para documentação detalhada de cada seção da API
// Por exemplo: /api-docs/stores, /api-docs/stock, etc.

module.exports = router;
