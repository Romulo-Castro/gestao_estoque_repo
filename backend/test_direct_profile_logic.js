// Test the updateProfile controller function directly without catchAsync wrapper
const db = require('./src/data/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { 
    AppError, 
    sendSuccessResponse, 
    validateRequiredFields,
    unauthorized 
} = require('./src/utils/errorHandler');

// Direct copy of the updateProfile logic without catchAsync
async function testUpdateProfileDirect() {
    try {
        console.log('Testing updateProfile logic directly...');
        
        // Initialize database
        await db.connectDb();
        await db.createTables();
        console.log('Database initialized successfully');
        
        // Get a test user
        const user = await db.findUserById(1);
        if (!user) {
            console.log('No user found with ID 1');
            return;
        }
        
        console.log('Testing with user:', user);
        
        // Create mock request and response objects
        const mockReq = {
            user: { userId: 1 },
            body: {
                name: 'Updated Name Test Direct',
                email: 'romulo@teste.com'
            }
        };
        
        const mockRes = {
            statusCode: 200,
            status: function(statusCode) {
                this.statusCode = statusCode;
                console.log(`Response status: ${statusCode}`);
                return this;
            },
            json: function(data) {
                console.log('Response data:', JSON.stringify(data, null, 2));
                console.log('Final status code:', this.statusCode);
                return this;
            }
        };
        
        // Copy the exact logic from updateProfile
        console.log('\n1. Testing updateProfile logic...');
        
        const req = mockReq;
        const res = mockRes;
        
        if (!req.user || !req.user.userId) {
            throw unauthorized('Não autorizado ou token inválido');
        }
        console.log('✓ User authorization check passed');

        const { name, email, currentPassword, newPassword } = req.body;
        console.log('✓ Request body extracted:', { name, email, hasCurrentPassword: !!currentPassword, hasNewPassword: !!newPassword });

        // Validate required fields
        validateRequiredFields({ name, email }, ['name', 'email']);
        console.log('✓ Required fields validation passed');

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            throw new AppError('Formato de email inválido', 400);
        }
        console.log('✓ Email format validation passed');

        // Get current user
        const currentUser = await db.findUserById(req.user.userId);
        if (!currentUser) {
            throw new AppError('Usuário não encontrado', 404);
        }
        console.log('✓ Current user found:', currentUser);

        // Check if email is being changed and if it's already in use
        if (email !== currentUser.email) {
            const existingUser = await db.findUserByEmail(email);
            if (existingUser && existingUser.id !== req.user.userId) {
                throw new AppError('Email já está em uso por outro usuário', 409);
            }
        }
        console.log('✓ Email availability check passed');

        // Prepare update data
        const updateData = {
            name: name.trim(),
            email: email.trim(),
        };
        console.log('✓ Update data prepared:', updateData);

        // Handle password change if provided
        if (currentPassword && newPassword) {
            console.log('• Processing password change...');
            
            // Validate current password
            const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentUser.password_hash);
            if (!isCurrentPasswordValid) {
                throw new AppError('Senha atual incorreta', 400);
            }
            console.log('✓ Current password validation passed');

            // Validate new password strength
            if (newPassword.length < 6) {
                throw new AppError('Nova senha deve ter pelo menos 6 caracteres', 400);
            }
            console.log('✓ New password strength validation passed');

            // Hash new password
            const salt = await bcrypt.genSalt(10);
            updateData.passwordHash = await bcrypt.hash(newPassword, salt);
            console.log('✓ New password hashed');
        }

        // Update user in database
        console.log('• Updating user in database...');
        const updateResult = await db.updateUserProfile(req.user.userId, updateData);
        console.log('✓ Database update result:', updateResult);

        // Get updated user data
        const updatedUser = await db.findUserById(req.user.userId);
        console.log('✓ Updated user retrieved:', updatedUser);

        sendSuccessResponse(res, {
            message: 'Perfil atualizado com sucesso!',
            user: {
                id: updatedUser.id,
                name: updatedUser.name,
                email: updatedUser.email
            }
        });
        console.log('✓ Success response sent');
        
    } catch (error) {
        console.error('Error during direct updateProfile test:');
        console.error('Message:', error.message);
        console.error('Stack:', error.stack);
        console.error('Status code:', error.statusCode);
        console.error('Is operational:', error.isOperational);
    } finally {
        process.exit(0);
    }
}

testUpdateProfileDirect();
