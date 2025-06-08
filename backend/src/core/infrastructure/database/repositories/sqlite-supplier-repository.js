const SupplierRepository = require('../../../domain/repositories/supplier-repository');
const Supplier = require('../../../domain/entities/supplier');

/**
 * Implementação SQLite do Supplier Repository
 */
class SQLiteSupplierRepository extends SupplierRepository {
    constructor(database) {
        super();
        this.db = database;
    }

    /**
     * Busca todos os suppliers de uma loja
     */
    async findByStore(storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                contact_person as contactPerson,
                store_id as storeId,
                created_at as createdAt,
                updated_at as updatedAt
            FROM suppliers 
            WHERE store_id = ?
            ORDER BY name ASC
        `;
        
        const rows = await this.db.query(query, [storeId]);
        return rows.map(row => this._mapToEntity(row));
    }

    /**
     * Busca supplier por ID e loja
     */
    async findByIdAndStore(supplierId, storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                contact_person as contactPerson,
                store_id as storeId,
                created_at as createdAt,
                updated_at as updatedAt
            FROM suppliers 
            WHERE id = ? AND store_id = ?
        `;
        
        const rows = await this.db.query(query, [supplierId, storeId]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Busca supplier por email em uma loja
     */
    async findByEmailAndStore(email, storeId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                phone,
                address,
                contact_person as contactPerson,
                store_id as storeId,
                created_at as createdAt,
                updated_at as updatedAt
            FROM suppliers 
            WHERE email = ? AND store_id = ?
        `;
        
        const rows = await this.db.query(query, [email, storeId]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Cria um novo supplier
     */
    async create(supplier) {
        const query = `
            INSERT INTO suppliers (
                name, email, phone, address, contact_person, store_id, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        `;
        
        const params = [
            supplier.name,
            supplier.email,
            supplier.phone,
            supplier.address,
            supplier.contactPerson,
            supplier.storeId
        ];
        
        const result = await this.db.run(query, params);
        
        // Buscar o supplier criado
        return await this.findByIdAndStore(result.lastID, supplier.storeId);
    }

    /**
     * Atualiza um supplier existente
     */
    async update(supplier) {
        const query = `
            UPDATE suppliers 
            SET 
                name = ?,
                email = ?,
                phone = ?,
                address = ?,
                contact_person = ?,
                updated_at = datetime('now')
            WHERE id = ? AND store_id = ?
        `;
        
        const params = [
            supplier.name,
            supplier.email,
            supplier.phone,
            supplier.address,
            supplier.contactPerson,
            supplier.id,
            supplier.storeId
        ];
        
        const result = await this.db.run(query, params);
        
        if (result.changes === 0) {
            throw new Error('Supplier not found or not authorized');
        }
        
        return await this.findByIdAndStore(supplier.id, supplier.storeId);
    }

    /**
     * Remove um supplier
     */
    async delete(supplierId, storeId) {
        const query = 'DELETE FROM suppliers WHERE id = ? AND store_id = ?';
        const result = await this.db.run(query, [supplierId, storeId]);
        return result.changes > 0;
    }

    /**
     * Mapeia row do banco para entidade Supplier
     */
    _mapToEntity(row) {
        return new Supplier({
            id: row.id,
            name: row.name,
            email: row.email,
            phone: row.phone,
            address: row.address,
            contactPerson: row.contactPerson,
            storeId: row.storeId,
            createdAt: new Date(row.createdAt),
            updatedAt: new Date(row.updatedAt)
        });
    }
}

module.exports = SQLiteSupplierRepository;
