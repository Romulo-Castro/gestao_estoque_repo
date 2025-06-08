const StoreRepository = require('../../../domain/repositories/store-repository');
const Store = require('../../../domain/entities/store');

/**
 * Implementação SQLite do Store Repository
 */
class SQLiteStoreRepository extends StoreRepository {
    constructor(database) {
        super();
        this.db = database;
    }

    /**
     * Busca todas as stores
     */
    async findAll() {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                created_at as createdAt,
                updated_at as updatedAt
            FROM stores 
            ORDER BY name ASC
        `;
        
        const rows = await this.db.query(query);
        return rows.map(row => this._mapToEntity(row));
    }

    /**
     * Busca store por ID
     */
    async findById(storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                created_at as createdAt,
                updated_at as updatedAt
            FROM stores 
            WHERE id = ?
        `;
        
        const rows = await this.db.query(query, [storeId]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Busca store por email
     */
    async findByEmail(email) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                created_at as createdAt,
                updated_at as updatedAt
            FROM stores 
            WHERE email = ?
        `;
        
        const rows = await this.db.query(query, [email]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Cria uma nova store
     */
    async create(store) {
        const query = `
            INSERT INTO stores (
                name, email, phone, address, created_at, updated_at
            ) VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))
        `;
        
        const params = [
            store.name,
            store.email,
            store.phone,
            store.address
        ];
        
        const result = await this.db.run(query, params);
        
        // Buscar a store criada
        return await this.findById(result.lastID);
    }

    /**
     * Atualiza uma store existente
     */
    async update(store) {
        const query = `
            UPDATE stores 
            SET 
                name = ?,
                email = ?,
                phone = ?,
                address = ?,
                updated_at = datetime('now')
            WHERE id = ?
        `;
        
        const params = [
            store.name,
            store.email,
            store.phone,
            store.address,
            store.id
        ];
        
        const result = await this.db.run(query, params);
        
        if (result.changes === 0) {
            throw new Error('Store not found');
        }
        
        return await this.findById(store.id);
    }

    /**
     * Remove uma store
     */
    async delete(storeId) {
        const query = 'DELETE FROM stores WHERE id = ?';
        const result = await this.db.run(query, [storeId]);
        return result.changes > 0;
    }

    /**
     * Mapeia row do banco para entidade Store
     */
    _mapToEntity(row) {
        return new Store({
            id: row.id,
            name: row.name,
            email: row.email,
            phone: row.phone,
            address: row.address,
            createdAt: new Date(row.createdAt),
            updatedAt: new Date(row.updatedAt)
        });
    }
}

module.exports = SQLiteStoreRepository;
