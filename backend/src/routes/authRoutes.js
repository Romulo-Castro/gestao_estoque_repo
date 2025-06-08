// src/routes/authRoutes.js
const express = require('express');
const authController = require('../controllers/authController'); // Assumindo que você criará este
const { validateRegistration, validateLogin, handleValidationErrors } = require('../middleware/validators'); // Assumindo validadores
const { authenticateToken } = require('../middleware/authMiddleware'); // Middleware para autenticação

const router = express.Router();

// Rota de Registro de Usuário
// POST /api/auth/register
router.post(
    '/register',
    validateRegistration(), // Aplicar regras de validação para registro
    handleValidationErrors, // Middleware para checar resultados da validação
    authController.register // Chamar a função do controller
);

// Rota de Login de Usuário
// POST /api/auth/login
router.post(
    '/login',
    validateLogin(), // Aplicar regras de validação para login
    handleValidationErrors,
    authController.login // Chamar a função do controller
);

// (Opcional) Rota para obter informações do usuário logado (requer autenticação)
// GET /api/auth/me
router.get('/me', authenticateToken, authController.getMe);

// Rotas de gerenciamento de perfil de usuário
// PUT /api/auth/profile - Atualizar perfil do usuário (nome, email e opcionalmente senha)
router.put('/profile', authenticateToken, authController.updateProfile);

// PUT /api/auth/change-password - Alterar apenas a senha
router.put('/change-password', authenticateToken, authController.changePassword);

module.exports = router;