// src/routes/authRoutes.js
const express = require('express');
const authController = require('../controllers/authController'); // Back to original
const { validateRegistration, validateLogin, validateProfileUpdate, validatePasswordChange, handleValidationErrors } = require('../middleware/validators');
const { authenticateToken } = require('../middleware/authMiddleware');

const router = express.Router();

// Rota de Registro de Usuário
// POST /api/auth/register
router.post(
    '/register',
    validateRegistration(),
    handleValidationErrors,
    authController.register
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
router.put('/profile', 
    authenticateToken, 
    validateProfileUpdate(),
    handleValidationErrors,
    authController.updateProfile
);

// PUT /api/auth/change-password - Alterar apenas a senha
router.put('/change-password', 
    authenticateToken, 
    validatePasswordChange(),
    handleValidationErrors,
    authController.changePassword
);

module.exports = router;