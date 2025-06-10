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
    validatePassword,
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
 * Validar força da senha
 */
const validatePasswordStrength = (password) => {
    const errors = [];
    
    if (password.length < 8) {
        errors.push('deve ter pelo menos 8 caracteres');
    }
    
    if (!/(?=.*[a-z])/.test(password)) {
        errors.push('deve conter pelo menos uma letra minúscula');
    }
    
    if (!/(?=.*[A-Z])/.test(password)) {
        errors.push('deve conter pelo menos uma letra maiúscula');
    }
    
    if (!/(?=.*\d)/.test(password)) {
        errors.push('deve conter pelo menos um número');
    }
    
    if (!/(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?])/.test(password)) {
        errors.push('deve conter pelo menos um caractere especial');
    }
    
    if (errors.length > 0) {
        throw new ValidationError(`Senha ${errors.join(', ')}`);
    }
    
    return password;
};

/**
 * Registro de usuário
 */
exports.register = catchAsync(async (req, res, next) => {
    const { name, email, password } = req.body;

    // Validações básicas
    validateRequiredFields({ name, email, password }, ['name', 'email', 'password']);
    
    // Validações específicas
    const cleanEmail = validateEmail(email);
    const validPassword = validatePasswordStrength(password);
    
    // Validar nome
    if (name.trim().length < 2) {
        throw new ValidationError('Nome deve ter pelo menos 2 caracteres');
    }
    
    if (name.trim().length > 100) {
        throw new ValidationError('Nome deve ter no máximo 100 caracteres');
    }

    try {
        // Verificar se o email já existe
        const existingUser = await db.findUserByEmail(cleanEmail);
        if (existingUser) {
            throw new AppError('Email já está em uso', 409);
        }

        // Hash da senha com salt configurável
        const saltRounds = config.security.bcryptRounds;
        const hashedPassword = await bcrypt.hash(validPassword, saltRounds);

        // Criar usuário
        const result = await db.createUser({
            name: name.trim(),
            email: cleanEmail,
            password_hash: hashedPassword
        });

        const userId = result.lastID;

        // Buscar usuário criado (sem senha)
        const newUser = await db.findUserById(userId);
        if (!newUser) {
            throw new AppError('Erro ao criar usuário', 500);
        }

        // Gerar token
        const token = generateToken(userId, cleanEmail);

        // Resposta de sucesso (sem senha)
        const { password_hash, ...userWithoutPassword } = newUser;
        
        sendSuccessResponse(res, {
            user: userWithoutPassword,
            token,
            expiresIn: config.jwt.expiresIn
        }, 'Usuário registrado com sucesso', 201);

    } catch (error) {
        if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
            throw new AppError('Email já está em uso', 409);
        }
        throw error;
    }
});

/**
 * Login de usuário
 */
exports.login = catchAsync(async (req, res, next) => {
    const { email, password } = req.body;

    // Validar campos obrigatórios
    validateRequiredFields({ email, password }, ['email', 'password']);

    // Validar formato do email
    const cleanEmail = validateEmail(email);

    try {
        // Buscar usuário pelo email
        const user = await db.findUserByEmail(cleanEmail);
        if (!user) {
            // Resposta genérica para não revelar se o email existe
            throw new AppError('Credenciais inválidas', 401);
        }

        // Comparar senha com hash do banco
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) {
            throw new AppError('Credenciais inválidas', 401);
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

    } catch (error) {
        throw error;
    }
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

    const { name, email, currentPassword, newPassword } = req.body;

    // Validar campos obrigatórios
    validateRequiredFields({ name, email }, ['name', 'email']);

    // Validações específicas
    const cleanEmail = validateEmail(email);
    
    // Validar nome
    if (name.trim().length < 2) {
        throw new ValidationError('Nome deve ter pelo menos 2 caracteres');
    }
    
    if (name.trim().length > 100) {
        throw new ValidationError('Nome deve ter no máximo 100 caracteres');
    }

    try {
        // Buscar usuário atual
        const currentUser = await db.findUserByEmail(req.user.email);
        if (!currentUser) {
            throw new AppError('Usuário não encontrado', 404);
        }

        // Verificar se o email já está em uso por outro usuário
        if (cleanEmail !== currentUser.email) {
            const existingUser = await db.findUserByEmail(cleanEmail);
            if (existingUser && existingUser.id !== req.user.userId) {
                throw new AppError('Email já está em uso por outro usuário', 409);
            }
        }

        // Preparar dados para atualização
        const updateData = {
            name: name.trim(),
            email: cleanEmail
        };

        // Se senha nova foi fornecida, validar e atualizar
        if (newPassword) {
            if (!currentPassword) {
                throw new ValidationError('Senha atual é obrigatória para alterar a senha');
            }

            // Verificar senha atual
            const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentUser.password_hash);
            if (!isCurrentPasswordValid) {
                throw new AppError('Senha atual incorreta', 400);
            }

            // Validar nova senha
            validatePasswordStrength(newPassword);

            // Hash da nova senha
            const saltRounds = config.security.bcryptRounds;
            updateData.password_hash = await bcrypt.hash(newPassword, saltRounds);
        }

        // Atualizar usuário no banco
        await db.updateUserProfile(req.user.userId, updateData);

        // Buscar usuário atualizado
        const updatedUser = await db.findUserById(req.user.userId);
        const { password_hash, ...userWithoutPassword } = updatedUser;

        sendSuccessResponse(res, userWithoutPassword, 'Perfil atualizado com sucesso');

    } catch (error) {
        if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
            throw new AppError('Email já está em uso', 409);
        }
        throw error;
    }
});

/**
 * Alterar senha do usuário
 */
exports.changePassword = catchAsync(async (req, res, next) => {
    if (!req.user || !req.user.userId) {
        throw unauthorized('Token inválido ou não fornecido');
    }

    const { currentPassword, newPassword } = req.body;

    // Validar campos obrigatórios
    validateRequiredFields({ currentPassword, newPassword }, ['currentPassword', 'newPassword']);

    // Validar nova senha
    validatePasswordStrength(newPassword);

    try {
        // Buscar usuário atual
        const currentUser = await db.findUserByEmail(req.user.email);
        if (!currentUser) {
            throw new AppError('Usuário não encontrado', 404);
        }

        // Verificar senha atual
        const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentUser.password_hash);
        if (!isCurrentPasswordValid) {
            throw new AppError('Senha atual incorreta', 400);
        }

        // Hash da nova senha
        const saltRounds = config.security.bcryptRounds;
        const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

        // Atualizar senha no banco
        await db.updateUserPassword(req.user.userId, newPasswordHash);

        sendSuccessResponse(res, null, 'Senha alterada com sucesso');

    } catch (error) {
        throw error;
    }
});

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
    validatePassword,
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
 * Validar força da senha
 */
const validatePasswordStrength = (password) => {
    const errors = [];
    
    if (password.length < 8) {
        errors.push('deve ter pelo menos 8 caracteres');
    }
    
    if (!/(?=.*[a-z])/.test(password)) {
        errors.push('deve conter pelo menos uma letra minúscula');
    }
    
    if (!/(?=.*[A-Z])/.test(password)) {
        errors.push('deve conter pelo menos uma letra maiúscula');
    }
    
    if (!/(?=.*\d)/.test(password)) {
        errors.push('deve conter pelo menos um número');
    }
    
    if (!/(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?])/.test(password)) {
        errors.push('deve conter pelo menos um caractere especial');
    }
    
    if (errors.length > 0) {
        throw new ValidationError(`Senha ${errors.join(', ')}`);
    }
    
    return password;
};

/**
 * Registro de usuário
 */
exports.register = catchAsync(async (req, res, next) => {
    const { name, email, password } = req.body;

    // Validações básicas
    validateRequiredFields({ name, email, password }, ['name', 'email', 'password']);
    
    // Validações específicas
    const cleanEmail = validateEmail(email);
    const validPassword = validatePasswordStrength(password);
    
    // Validar nome
    if (name.trim().length < 2) {
        throw new ValidationError('Nome deve ter pelo menos 2 caracteres');
    }
    
    if (name.trim().length > 100) {
        throw new ValidationError('Nome deve ter no máximo 100 caracteres');
    }

    try {
        // Verificar se o email já existe
        const existingUser = await db.findUserByEmail(cleanEmail);
        if (existingUser) {
            throw new AppError('Email já está em uso', 409);
        }

        // Hash da senha com salt configurável
        const saltRounds = config.security.bcryptRounds;
        const hashedPassword = await bcrypt.hash(validPassword, saltRounds);

        // Criar usuário
        const result = await db.createUser({
            name: name.trim(),
            email: cleanEmail,
            password_hash: hashedPassword
        });

        const userId = result.lastID;

        // Buscar usuário criado (sem senha)
        const newUser = await db.findUserById(userId);
        if (!newUser) {
            throw new AppError('Erro ao criar usuário', 500);
        }

        // Gerar token
        const token = generateToken(userId, cleanEmail);

        // Resposta de sucesso (sem senha)
        const { password_hash, ...userWithoutPassword } = newUser;
        
        sendSuccessResponse(res, {
            user: userWithoutPassword,
            token,
            expiresIn: config.jwt.expiresIn
        }, 'Usuário registrado com sucesso', 201);

    } catch (error) {
        if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
            throw new AppError('Email já está em uso', 409);
        }
        throw error;
    }
});

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