// src/controllers/authController_temp.js
const db = require('../data/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config/config');

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
 * Registro de usuário - Versão simplificada para debug
 */
exports.register = async (req, res, next) => {
    console.log('=== REGISTER CONTROLLER CALLED ===');
    console.log('Request body:', req.body);
    
    try {
        const { name, email, password } = req.body;
        
        console.log('Destructured values:', { 
            name: name || '[MISSING]', 
            email: email || '[MISSING]', 
            password: password ? '[PRESENT]' : '[MISSING]' 
        });

        // Validar campos obrigatórios
        if (!name || !email || !password) {
            return res.status(400).json({
                status: 'fail',
                message: 'Nome, email e senha são obrigatórios'
            });
        }

        console.log('About to check existing user...');
        // Verificar se o email já existe
        const existingUser = await db.findUserByEmail(email);
        console.log('Existing user check completed. User exists:', !!existingUser);
        
        if (existingUser) {
            return res.status(409).json({
                status: 'fail',
                message: 'Email já cadastrado'
            });
        }

        console.log('About to hash password...');
        console.log('Password value before hashing:', password);
        // Hash da senha com salt configurável
        const saltRounds = config.security.bcryptRounds;
        console.log('Bcrypt rounds:', saltRounds);
        
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        console.log('Password hashed successfully. Hash length:', hashedPassword ? hashedPassword.length : 'undefined');
        console.log('Hashed password value:', hashedPassword);

        console.log('About to create user...');
        // Criar usuário
        const result = await db.createUser({
            name: name.trim(),
            email: email,
            passwordHash: hashedPassword
        });
        console.log('User created with ID:', result.lastID);

        const userId = result.lastID;

        // Buscar usuário criado (sem senha)
        const newUser = await db.findUserById(userId);
        if (!newUser) {
            return res.status(500).json({
                status: 'error',
                message: 'Erro ao criar usuário após registro'
            });
        }

        // Gerar token
        const token = generateToken(userId, email);

        // Resposta de sucesso (sem senha)
        const { password_hash, ...userWithoutPassword } = newUser;
        
        res.status(201).json({
            status: 'success',
            message: 'Usuário registrado com sucesso',
            data: {
                user: userWithoutPassword,
                token,
                expiresIn: config.jwt.expiresIn
            }
        });
        
    } catch (error) {
        console.error('Error in register controller:', error);
        res.status(500).json({
            status: 'error',
            message: 'Erro interno do servidor',
            details: error.message        });
    }
};

/**
 * Login de usuário
 */
exports.login = async (req, res) => {
    res.status(501).json({ message: 'Login não implementado no controller temporário' });
};

/**
 * Obter dados do usuário logado
 */
exports.getMe = async (req, res) => {
    res.status(501).json({ message: 'GetMe não implementado no controller temporário' });
};

/**
 * Atualizar perfil do usuário
 */
exports.updateProfile = async (req, res) => {
    res.status(501).json({ message: 'UpdateProfile não implementado no controller temporário' });
};

/**
 * Alterar senha do usuário
 */
exports.changePassword = async (req, res) => {
    res.status(501).json({ message: 'ChangePassword não implementado no controller temporário' });
};
