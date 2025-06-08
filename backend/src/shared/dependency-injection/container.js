// Dependency Injection Container
class DIContainer {
    constructor() {
        this.services = new Map();
        this.singletons = new Map();
    }

    // Register a service with its dependencies
    register(name, factory, options = {}) {
        this.services.set(name, {
            factory,
            singleton: options.singleton || false,
            dependencies: options.dependencies || []
        });
    }

    // Register a singleton service
    registerSingleton(name, factory, dependencies = []) {
        this.register(name, factory, { singleton: true, dependencies });
    }

    // Get a service instance
    get(name) {
        const service = this.services.get(name);
        if (!service) {
            throw new Error(`Service '${name}' not found`);
        }

        // Return existing singleton instance
        if (service.singleton && this.singletons.has(name)) {
            return this.singletons.get(name);
        }

        // Resolve dependencies
        const dependencies = service.dependencies.map(dep => this.get(dep));
        
        // Create new instance
        const instance = service.factory(...dependencies);

        // Store singleton instance
        if (service.singleton) {
            this.singletons.set(name, instance);
        }

        return instance;
    }

    // Check if service is registered
    has(name) {
        return this.services.has(name);
    }

    // Clear all services (useful for testing)
    clear() {
        this.services.clear();
        this.singletons.clear();
    }

    // Get all registered service names
    getRegisteredServices() {
        return Array.from(this.services.keys());
    }
}

module.exports = { DIContainer };
