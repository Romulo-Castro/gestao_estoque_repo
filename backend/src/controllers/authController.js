// src/controllers/authController.js
const db = require('../data/database'); // Para interagir com o DB (buscar/criar usuário)
const bcrypt = require('bcryptjs'); // Para comparar/hash de senhas
const jwt = require('jsonwebtoken'); // Para criar tokens JWT
const { 
    AppError, 
    catchAsync, 
    sendSuccessResponse, 
    validateRequiredFields,
    unauthorized 
} = require('../utils/errorHandler');
require('dotenv').config(); // Para acessar JWT_SECRET

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error("ERRO CRÍTICO: JWT_SECRET não definido no .env");
    process.exit(1);
}

// --- Função de Registro ---
exports.register = catchAsync(async (req, res, next) => {
    const { name, email, password } = req.body;

    // Validate required fields
    validateRequiredFields({ name, email, password }, ['name', 'email', 'password']);

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        throw new AppError('Formato de email inválido', 400);
    }

    // Validate password strength
    if (password.length < 6) {
        throw new AppError('A senha deve ter pelo menos 6 caracteres', 400);
    }

    // 1. Verificar se email já existe
    const existingUser = await db.findUserByEmail(email);
    if (existingUser) {
        throw new AppError('Email já cadastrado', 409);
    }

    // 2. Hash da senha
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 3. Criar usuário no DB
    const newUserResult = await db.createUser({
        name,
        email,
        passwordHash
    });

    // 4. Buscar o usuário recém-criado
    const newUser = await db.findUserById(newUserResult.lastID);
    if (!newUser) {
        throw new AppError('Erro ao criar usuário', 500);
    }

    // 5. Gerar Token JWT para login automático
    const payload = { userId: newUser.id, email: newUser.email };
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1d' });

    // 6. Responder com sucesso
    sendSuccessResponse(
        res,
        {
            token: token,
            user: {
                id: newUser.id,
                name: newUser.name,
                email: newUser.email,
            },
        },
        'Usuário registrado com sucesso!',
        201
    );
});

// --- Função de Login ---
exports.login = catchAsync(async (req, res, next) => {
    const { email, password } = req.body;

    // Validate required fields
    validateRequiredFields({ email, password }, ['email', 'password']);

    // 1. Buscar usuário pelo email
    const user = await db.findUserByEmail(email);
    if (!user) {
        // Resposta genérica para não revelar se o email existe ou não
        throw new AppError('Credenciais inválidas', 401);
    }

    // 2. Comparar a senha enviada com o hash no DB
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
        throw new AppError('Credenciais inválidas', 401);
    }

    // 3. Gerar Token JWT
    const payload = { userId: user.id, email: user.email };
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1d' });

    // 4. Responder com sucesso e o token
    sendSuccessResponse(
        res,
        {
            token: token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
            },
        },
        'Login bem-sucedido!'
    );
});


// (Opcional) Função para obter dados do usuário logado
exports.getMe = catchAsync(async (req, res, next) => {    // O middleware authenticateToken (se usado na rota) já colocou req.user
    if (!req.user || !req.user.userId) {
        throw unauthorized('Não autorizado ou token inválido');
    }

    const user = await db.findUserById(req.user.userId);
    if (!user) {
        throw new AppError('Usuário não encontrado', 404);
    }

    sendSuccessResponse(res, {
        id: user.id,
        name: user.name,
        email: user.email
    });
});

// --- Função para atualizar perfil do usuário ---
exports.updateProfile = catchAsync(async (req, res, next) => {
    if (!req.user || !req.user.userId) {
        throw unauthorized('Não autorizado ou token inválido');
    }

    const { name, email, currentPassword, newPassword } = req.body;

    // Validate required fields
    validateRequiredFields({ name, email }, ['name', 'email']);    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        throw new AppError('Formato de email inválido', 400);
    }

    // Get current user
    const currentUser = await db.findUserByIdWithPassword(req.user.userId);
    if (!currentUser) {
        throw new AppError('Usuário não encontrado', 404);
    }

    // Check if email is being changed and if it's already in use
    if (email !== currentUser.email) {
        const existingUser = await db.findUserByEmail(email);
        if (existingUser && existingUser.id !== req.user.userId) {
            throw new AppError('Email já está em uso por outro usuário', 409);
        }
    }

    // Prepare update data
    const updateData = {
        name: name.trim(),
        email: email.trim(),
    };

    // Handle password change if provided
    if (currentPassword && newPassword) {
        // Validate current password
        const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentUser.password_hash);
        if (!isCurrentPasswordValid) {
            throw new AppError('Senha atual incorreta', 400);
        }

        // Validate new password strength
        if (newPassword.length < 6) {
            throw new AppError('Nova senha deve ter pelo menos 6 caracteres', 400);
        }

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        updateData.passwordHash = await bcrypt.hash(newPassword, salt);
    }

    // Update user in database
    await db.updateUserProfile(req.user.userId, updateData);

    // Get updated user data
    const updatedUser = await db.findUserById(req.user.userId);

    sendSuccessResponse(res, {
        message: 'Perfil atualizado com sucesso!',
        user: {
            id: updatedUser.id,
            name: updatedUser.name,
            email: updatedUser.email
        }
    });
});

// --- Função para alterar senha ---
exports.changePassword = catchAsync(async (req, res, next) => {
    if (!req.user || !req.user.userId) {
        throw unauthorized('Não autorizado ou token inválido');
    }

    const { currentPassword, newPassword } = req.body;

    // Validate required fields
    validateRequiredFields({ currentPassword, newPassword }, ['currentPassword', 'newPassword']);

    // Validate new password strength
    if (newPassword.length < 6) {
        throw new AppError('Nova senha deve ter pelo menos 6 caracteres', 400);
    }    // Get current user
    const currentUser = await db.findUserByIdWithPassword(req.user.userId);
    if (!currentUser) {
        throw new AppError('Usuário não encontrado', 404);
    }

    // Validate current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentUser.password_hash);
    if (!isCurrentPasswordValid) {
        throw new AppError('Senha atual incorreta', 400);
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const newPasswordHash = await bcrypt.hash(newPassword, salt);

    // Update password in database
    await db.updateUserPassword(req.user.userId, newPasswordHash);

    sendSuccessResponse(res, {
        message: 'Senha alterada com sucesso!'
    });
});