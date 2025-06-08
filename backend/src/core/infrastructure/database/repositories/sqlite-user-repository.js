const UserRepository = require('../../../domain/repositories/user-repository');
const User = require('../../../domain/entities/user');

/**
 * Implementação SQLite do User Repository
 */
class SQLiteUserRepository extends UserRepository {
    constructor(database) {
        super();
        this.db = database;
    }

    /**
     * Busca user por email
     */
    async findByEmail(email) {
        const query = `
            SELECT 
                id,
                name,
                email,
                password_hash as passwordHash,
                role,
                is_active as isActive,
                created_at as createdAt,
                updated_at as updatedAt
            FROM users 
            WHERE email = ?
        `;
        
        const rows = await this.db.query(query, [email]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Busca user por ID
     */
    async findById(userId) {
        const query = `
            SELECT 
                id,
                name,
                email,
                password_hash as passwordHash,
                role,
                is_active as isActive,
                created_at as createdAt,
                updated_at as updatedAt
            FROM users 
            WHERE id = ?
        `;
        
        const rows = await this.db.query(query, [userId]);
        return rows.length > 0 ? this._mapToEntity(rows[0]) : null;
    }

    /**
     * Cria um novo user
     */
    async create(user) {
        const query = `
            INSERT INTO users (
                name, email, password_hash, role, is_active, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        `;
        
        const params = [
            user.name,
            user.email,
            user.passwordHash,
            user.role,
            user.isActive ? 1 : 0
        ];
        
        const result = await this.db.run(query, params);
        
        // Buscar o user criado
        return await this.findById(result.lastID);
    }

    /**
     * Atualiza um user existente
     */
    async update(user) {
        const query = `
            UPDATE users 
            SET 
                name = ?,
                email = ?,
                password_hash = ?,
                role = ?,
                is_active = ?,
                updated_at = datetime('now')
            WHERE id = ?
        `;
        
        const params = [
            user.name,
            user.email,
            user.passwordHash,
            user.role,
            user.isActive ? 1 : 0,
            user.id
        ];
        
        const result = await this.db.run(query, params);
        
        if (result.changes === 0) {
            throw new Error('User not found');
        }
        
        return await this.findById(user.id);
    }

    /**
     * Remove um user
     */
    async delete(userId) {
        const query = 'DELETE FROM users WHERE id = ?';
        const result = await this.db.run(query, [userId]);
        return result.changes > 0;
    }

    /**
     * Verifica se um email já existe
     */
    async emailExists(email) {
        const query = 'SELECT COUNT(*) as count FROM users WHERE email = ?';
        const rows = await this.db.query(query, [email]);
        return rows[0].count > 0;
    }

    /**
     * Mapeia row do banco para entidade User
     */
    _mapToEntity(row) {
        return new User({
            id: row.id,
            name: row.name,
            email: row.email,
            passwordHash: row.passwordHash,
            role: row.role,
            isActive: row.isActive === 1,
            createdAt: new Date(row.createdAt),
            updatedAt: new Date(row.updatedAt)
        });
    }
}

module.exports = SQLiteUserRepository;
