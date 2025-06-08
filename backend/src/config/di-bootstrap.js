// Dependency Injection Bootstrap
const { DIContainer } = require('../shared/dependency-injection/container');

// Core Infrastructure
const SQLiteDatabase = require('../core/infrastructure/database/sqlite-database');
const { SQLiteStockRepository } = require('../core/infrastructure/database/repositories/sqlite-stock-repository');
const { SQLiteDocumentRepository } = require('../core/infrastructure/database/repositories/sqlite-document-repository');
const SQLiteCustomerRepository = require('../core/infrastructure/database/repositories/sqlite-customer-repository');
const SQLiteSupplierRepository = require('../core/infrastructure/database/repositories/sqlite-supplier-repository');
const SQLiteStoreRepository = require('../core/infrastructure/database/repositories/sqlite-store-repository');
const SQLiteUserRepository = require('../core/infrastructure/database/repositories/sqlite-user-repository');

// Domain Services
const BalanceCalculator = require('../core/domain/services/balance-calculator');

// Application Use Cases - Stock
const { GetStockItems } = require('../core/application/usecases/stock/get-stock-items');
const { CreateStockItem } = require('../core/application/usecases/stock/create-stock-item');
const { UpdateStockItem } = require('../core/application/usecases/stock/update-stock-item');
const { DeleteStockItem } = require('../core/application/usecases/stock/delete-stock-item');

// Application Use Cases - Documents
const GetDocuments = require('../core/application/usecases/documents/get-documents');
const CalculateBalanceSheet = require('../core/application/usecases/documents/calculate-balance-sheet');

// Application Use Cases - Customers
const GetCustomers = require('../core/application/usecases/customers/get-customers');
const CreateCustomer = require('../core/application/usecases/customers/create-customer');
const UpdateCustomer = require('../core/application/usecases/customers/update-customer');
const DeleteCustomer = require('../core/application/usecases/customers/delete-customer');

// Application Use Cases - Auth
const RegisterUser = require('../core/application/usecases/auth/register-user');
const AuthenticateUser = require('../core/application/usecases/auth/authenticate-user');

// Presentation Controllers
const { StockController } = require('../presentation/controllers/stock-controller');
const { DocumentController } = require('../presentation/controllers/document-controller');
const CustomerController = require('../presentation/controllers/customer-controller');
const AuthController = require('../presentation/controllers/auth-controller');

// Configuration
const config = require('../config/app-config');

class DIBootstrap {    static setupContainer() {
        const container = new DIContainer();

        // Register the container itself for self-injection
        container.registerSingleton('container', () => container);

        // Register Configuration
        container.registerSingleton('config', () => config);

        // Register Database
        container.registerSingleton('database', () => {
            const db = new SQLiteDatabase();
            return db;
        });        // Register Repositories
        container.registerSingleton('stockRepository', (database) => {
            return new SQLiteStockRepository(database);
        }, ['database']);

        container.registerSingleton('documentRepository', (database) => {
            return new SQLiteDocumentRepository(database);
        }, ['database']);

        container.registerSingleton('customerRepository', (database) => {
            return new SQLiteCustomerRepository(database);
        }, ['database']);

        container.registerSingleton('supplierRepository', (database) => {
            return new SQLiteSupplierRepository(database);
        }, ['database']);

        container.registerSingleton('storeRepository', (database) => {
            return new SQLiteStoreRepository(database);
        }, ['database']);

        container.registerSingleton('userRepository', (database) => {
            return new SQLiteUserRepository(database);
        }, ['database']);

        // Register Domain Services
        container.registerSingleton('balanceCalculator', () => {
            return new BalanceCalculator();
        });

        // Register Stock Use Cases
        container.register('getStockItems', (stockRepository) => {
            return new GetStockItems(stockRepository);
        }, { dependencies: ['stockRepository'] });

        container.register('createStockItem', (stockRepository) => {
            return new CreateStockItem(stockRepository);
        }, { dependencies: ['stockRepository'] });

        container.register('updateStockItem', (stockRepository) => {
            return new UpdateStockItem(stockRepository);
        }, { dependencies: ['stockRepository'] });

        container.register('deleteStockItem', (stockRepository) => {
            return new DeleteStockItem(stockRepository);
        }, { dependencies: ['stockRepository'] });

        // Register Document Use Cases
        container.register('getDocuments', (documentRepository) => {
            return new GetDocuments(documentRepository);
        }, { dependencies: ['documentRepository'] });        container.register('calculateBalanceSheet', (documentRepository, balanceCalculator) => {
            return new CalculateBalanceSheet(documentRepository, balanceCalculator);
        }, { dependencies: ['documentRepository', 'balanceCalculator'] });

        // Register Customer Use Cases
        container.register('getCustomers', (customerRepository) => {
            return new GetCustomers(customerRepository);
        }, { dependencies: ['customerRepository'] });

        container.register('createCustomer', (customerRepository) => {
            return new CreateCustomer(customerRepository);
        }, { dependencies: ['customerRepository'] });

        container.register('updateCustomer', (customerRepository) => {
            return new UpdateCustomer(customerRepository);
        }, { dependencies: ['customerRepository'] });

        container.register('deleteCustomer', (customerRepository) => {
            return new DeleteCustomer(customerRepository);
        }, { dependencies: ['customerRepository'] });

        // Register Auth Use Cases
        container.register('registerUser', (userRepository) => {
            return new RegisterUser(userRepository);
        }, { dependencies: ['userRepository'] });

        container.register('authenticateUser', (userRepository, config) => {
            return new AuthenticateUser(userRepository, config.JWT_SECRET);
        }, { dependencies: ['userRepository', 'config'] });        // Register Controllers
        container.register('stockController', (container) => {
            return new StockController(container);
        }, { dependencies: ['container'] });

        container.register('documentController', (container) => {
            return new DocumentController(container);
        }, { dependencies: ['container'] });

        container.register('customerController', (container) => {
            return new CustomerController(container);
        }, { dependencies: ['container'] });

        container.register('authController', (container) => {
            return new AuthController(container);
        }, { dependencies: ['container'] });

        return container;
    }

    static async initializeDatabase(container) {
        const database = container.get('database');
        await database.connect();
        console.log('Database initialized successfully');
        return database;
    }

    static async bootstrap() {
        try {
            console.log('Bootstrapping Clean Architecture DI Container...');
            
            const container = this.setupContainer();
            await this.initializeDatabase(container);
            
            console.log('Clean Architecture bootstrap completed successfully');
            console.log(`Registered services: ${container.getRegisteredServices().join(', ')}`);
            
            return container;
        } catch (error) {
            console.error('Failed to bootstrap Clean Architecture:', error);
            throw error;
        }
    }

    static async shutdown(container) {
        try {
            const database = container.get('database');
            await database.close();
            console.log('Clean Architecture shutdown completed');
        } catch (error) {
            console.error('Error during shutdown:', error);
        }
    }
}

module.exports = { DIBootstrap };
