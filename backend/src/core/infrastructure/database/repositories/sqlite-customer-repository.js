const CustomerRepository = require('../../../domain/repositories/customer-repository');
const Customer = require('../../../domain/entities/customer');

/**
 * Implementação SQLite do Customer Repository
 */
class SQLiteCustomerRepository extends CustomerRepository {
    constructor(database) {
        super();
        this.db = database;
    }

    /**
     * Busca todos os customers de uma loja
     */
    async findByStore(storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                store_id as storeId,
                created_at as createdAt,
                updated_at as updatedAt
            FROM customers 
            WHERE store_id = ?
            ORDER BY name ASC
        `;
        
        const rows = await this.db.query(query, [storeId]);
        return rows.map(row => this._mapToEntity(row));
    }

    /**
     * Busca customer por ID e loja
     */
    async findByIdAndStore(customerId, storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                store_id as storeId,
                created_at as createdAt,
                updated_at as updatedAt
            FROM customers 
            WHERE id = ? AND store_id = ?
        `;
        
        const rows = await this.db.query(query, [customerId, storeId]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Busca customer por email em uma loja
     */
    async findByEmailAndStore(email, storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                store_id as storeId,
                created_at as createdAt,
                updated_at as updatedAt
            FROM customers 
            WHERE email = ? AND store_id = ?
        `;
        
        const rows = await this.db.query(query, [email, storeId]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Cria um novo customer
     */
    async create(customer) {
        const query = `
            INSERT INTO customers (
                name, email, phone, address, store_id, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        `;
        
        const params = [
            customer.name,
            customer.email,
            customer.phone,
            customer.address,
            customer.storeId
        ];
        
        const result = await this.db.run(query, params);
        
        // Buscar o customer criado
        return await this.findByIdAndStore(result.lastID, customer.storeId);
    }

    /**
     * Atualiza um customer existente
     */
    async update(customer) {
        const query = `
            UPDATE customers 
            SET 
                name = ?,
                email = ?,
                phone = ?,
                address = ?,
                updated_at = datetime('now')
            WHERE id = ? AND store_id = ?
        `;
        
        const params = [
            customer.name,
            customer.email,
            customer.phone,
            customer.address,
            customer.id,
            customer.storeId
        ];
        
        const result = await this.db.run(query, params);
        
        if (result.changes === 0) {
            throw new Error('Customer not found or not authorized');
        }
        
        return await this.findByIdAndStore(customer.id, customer.storeId);
    }

    /**
     * Remove um customer
     */
    async delete(customerId, storeId) {
        const query = 'DELETE FROM customers WHERE id = ? AND store_id = ?';
        const result = await this.db.run(query, [customerId, storeId]);
        return result.changes > 0;
    }

    /**
     * Mapeia row do banco para entidade Customer
     */
    _mapToEntity(row) {
        return new Customer({
            id: row.id,
            name: row.name,
            email: row.email,
            phone: row.phone,
            address: row.address,
            storeId: row.storeId,
            createdAt: new Date(row.createdAt),
            updatedAt: new Date(row.updatedAt)
        });
    }
}

module.exports = SQLiteCustomerRepository;
