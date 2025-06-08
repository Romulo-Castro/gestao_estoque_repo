/**
 * Clean Architecture Integration Point
 * Este arquivo facilita a integração gradual da Clean Architecture com o código existente
 */

const { DIBootstrap } = require('../config/di-bootstrap');
const { createV1Routes } = require('../presentation/routes/api/v1');
const { createAuthMiddleware, createRoleMiddleware, createStoreAccessMiddleware } = require('../presentation/middleware/auth-middleware');

class CleanArchitectureIntegration {
    constructor() {
        this.container = null;
        this.isInitialized = false;
    }

    /**
     * Inicializa a Clean Architecture
     */
    async initialize() {
        try {
            console.log('Initializing Clean Architecture...');
            this.container = await DIBootstrap.bootstrap();
            this.isInitialized = true;
            console.log('Clean Architecture initialized successfully');
        } catch (error) {
            console.error('Failed to initialize Clean Architecture:', error);
            throw error;
        }
    }

    /**
     * Retorna as rotas da Clean Architecture
     */
    getRoutes() {
        if (!this.isInitialized) {
            throw new Error('Clean Architecture not initialized. Call initialize() first.');
        }
        return createV1Routes(this.container);
    }

    /**
     * Retorna middlewares de autenticação
     */
    getAuthMiddlewares() {
        if (!this.isInitialized) {
            throw new Error('Clean Architecture not initialized. Call initialize() first.');
        }

        const config = this.container.get('config');
        
        return {
            auth: createAuthMiddleware(config.JWT_SECRET),
            role: createRoleMiddleware,
            storeAccess: createStoreAccessMiddleware()
        };
    }

    /**
     * Retorna o container DI
     */
    getContainer() {
        if (!this.isInitialized) {
            throw new Error('Clean Architecture not initialized. Call initialize() first.');
        }
        return this.container;
    }

    /**
     * Finaliza a Clean Architecture
     */
    async shutdown() {
        if (this.isInitialized && this.container) {
            await DIBootstrap.shutdown(this.container);
            this.isInitialized = false;
        }
    }

    /**
     * Verifica se a Clean Architecture está inicializada
     */
    isReady() {
        return this.isInitialized;
    }

    /**
     * Retorna estatísticas da Clean Architecture
     */
    getStats() {
        if (!this.isInitialized) {
            return { initialized: false };
        }

        return {
            initialized: true,
            registeredServices: this.container.getRegisteredServices(),
            serviceCount: this.container.getRegisteredServices().length
        };
    }
}

// Singleton instance
const cleanArchInstance = new CleanArchitectureIntegration();

module.exports = {
    CleanArchitectureIntegration,
    cleanArchInstance
};
