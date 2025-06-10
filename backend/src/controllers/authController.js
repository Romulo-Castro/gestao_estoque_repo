// src/controllers/authController.js
const db = require('../data/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { 
    AppError, 
    ValidationError,
    catchAsync, 
    sendSuccessResponse, 
    validateRequiredFields,
    validateEmail,
    unauthorized 
} = require('../utils/errorHandler');

// Validação da configuração JWT na inicialização
if (!config.jwt.secret) {
    console.error("ERRO CRÍTICO: JWT_SECRET não definido na configuração");
    process.exit(1);
}

/**
 * Gerar token JWT com informações padronizadas
 */
const generateToken = (userId, email) => {
    return jwt.sign(
        { 
            userId, 
            email,
            iat: Math.floor(Date.now() / 1000)
        },
        config.jwt.secret,
        {
            expiresIn: config.jwt.expiresIn,
            issuer: config.jwt.issuer,
            audience: config.jwt.audience
        }
    );
};

/**
 * Registro de usuário
 */
exports.register = catchAsync(async (req, res, next) => {
    const { name, email, password } = req.body;

    // Verificar se o email já existe
    const existingUser = await db.findUserByEmail(email);
    if (existingUser) {
        throw new AppError('Email já cadastrado', 409);
    }

    // Hash da senha com salt configurável
    const saltRounds = config.security.bcryptRounds;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Criar usuário
    const result = await db.createUser({
        name: name.trim(),
        email: email,
        password_hash: hashedPassword
    });

    const userId = result.lastID;

    // Buscar usuário criado (sem senha)
    const newUser = await db.findUserById(userId);
    if (!newUser) {
        throw new AppError('Erro ao criar usuário após registro', 500);
    }

    // Gerar token
    const token = generateToken(userId, email);

    // Resposta de sucesso (sem senha)
    const { password_hash, ...userWithoutPassword } = newUser;
    
    sendSuccessResponse(res, {
        user: userWithoutPassword,
        token,
        expiresIn: config.jwt.expiresIn
    }, 'Usuário registrado com sucesso', 201);
});

/**
 * Login de usuário
 */
exports.login = catchAsync(async (req, res, next) => {
    const { email, password } = req.body;

    // Buscar usuário pelo email
    const user = await db.findUserByEmail(email);
    if (!user) {
        throw unauthorized('Email ou senha inválidos');
    }

    // Comparar senha com hash do banco
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
        throw unauthorized('Email ou senha inválidos');
    }

    // Gerar token JWT
    const token = generateToken(user.id, user.email);

    // Resposta de sucesso (sem senha)
    const { password_hash, ...userWithoutPassword } = user;
    
    sendSuccessResponse(res, {
        user: userWithoutPassword,
        token,
        expiresIn: config.jwt.expiresIn
    }, 'Login realizado com sucesso');
});

/**
 * Obter dados do usuário logado
 */
exports.getMe = catchAsync(async (req, res, next) => {
    if (!req.user || !req.user.userId) {
        throw unauthorized('Token inválido ou não fornecido');
    }

    const user = await db.findUserById(req.user.userId);
    if (!user) {
        throw new AppError('Usuário não encontrado', 404);
    }

    // Remover senha da resposta
    const { password_hash, ...userWithoutPassword } = user;
    
    sendSuccessResponse(res, userWithoutPassword, 'Dados do usuário obtidos com sucesso');
});

/**
 * Atualizar perfil do usuário
 */
exports.updateProfile = catchAsync(async (req, res, next) => {
    if (!req.user || !req.user.userId) {
        throw unauthorized('Token inválido ou não fornecido');
    }

    const userId = req.user.userId;
    const { name, email } = req.body;

    // Buscar usuário atual para verificar o email
    const currentUser = await db.findUserById(userId);
    if (!currentUser) {
        throw new AppError('Usuário não encontrado para atualização', 404);
    }

    // Verificar se o email já está em uso por outro usuário, se o email foi alterado
    if (email !== currentUser.email) {
        const existingUserWithNewEmail = await db.findUserByEmail(email);
        if (existingUserWithNewEmail) {
            throw new AppError('Este email já está em uso por outra conta.', 409);
        }
    }
    
    const updateData = {
        name: name.trim(),
        email: email,
    };

    await db.updateUserProfile(userId, updateData);

    const updatedUser = await db.findUserById(userId);
    // Remover senha da resposta
    const { password_hash, ...userWithoutPassword } = updatedUser;

    sendSuccessResponse(res, {
        message: 'Perfil atualizado com sucesso!',
        user: userWithoutPassword
    });
});

/**
 * Alterar senha do usuário
 */
exports.changePassword = catchAsync(async (req, res, next) => {
    if (!req.user || !req.user.userId) {
        throw unauthorized('Token inválido ou não fornecido');
    }
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;

    // Buscar usuário atual (com hash da senha)
    const currentUser = await db.findUserByIdWithPassword ? 
        await db.findUserByIdWithPassword(userId) : 
        await db.findUserById(userId);
    
    if (!currentUser) {
        throw new AppError('Usuário não encontrado', 404);
    }

    // Validar senha atual
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentUser.password_hash);
    if (!isCurrentPasswordValid) {
        throw unauthorized('Senha atual incorreta');
    }

    // Verificar se a nova senha é igual à antiga
    if (currentPassword === newPassword) {
        throw new ValidationError('A nova senha não pode ser igual à senha atual.');
    }

    // Hash da nova senha
    const saltRounds = config.security.bcryptRounds;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Atualizar senha no banco
    await db.updateUserPassword(userId, newPasswordHash);

    sendSuccessResponse(res, {
        message: 'Senha alterada com sucesso!'
    });
});
