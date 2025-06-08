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
exports.getMe = catchAsync(async (req, res, next) => {
    // O middleware authenticateToken (se usado na rota) já colocou req.user
    if (!req.user || !req.user.userId) {
        return unauthorized(res, 'Não autorizado ou token inválido');
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