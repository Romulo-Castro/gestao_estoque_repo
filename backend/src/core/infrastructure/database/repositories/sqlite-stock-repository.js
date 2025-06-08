// Stock Repository Implementation
const StockItem = require('../../../domain/entities/stock-item');
const Quantity = require('../../../domain/value-objects/quantity');

class SQLiteStockRepository {
    constructor(database) {
        this.db = database;
    }    async findByStoreId(storeId) {
        const sql = `
            SELECT 
                si.*,
                g.name as group_name
            FROM stock_items si
            LEFT JOIN item_groups g ON si.group_id = g.id
            WHERE si.store_id = ?
            ORDER BY si.name ASC
        `;
        
        const rows = await this.db.all(sql, [storeId]);
        return rows.map(row => this.mapRowToEntity(row));
    }    async findById(itemId, storeId) {
        const sql = `
            SELECT 
                si.*,
                g.name as group_name
            FROM stock_items si
            LEFT JOIN item_groups g ON si.group_id = g.id
            WHERE si.id = ? AND si.store_id = ?
        `;
        
        const row = await this.db.get(sql, [itemId, storeId]);
        return row ? this.mapRowToEntity(row) : null;
    }

    async findByIdAndStore(itemId, storeId) {
        return await this.findById(itemId, storeId);
    }

    async save(stockItem) {
        const data = {
            store_id: stockItem.storeId,
            name: stockItem.name,
            quantity: stockItem.quantity.value,
            unit: stockItem.quantity.unit,
            group_id: stockItem.groupId,
            properties: JSON.stringify(stockItem.properties),
            image_filename: stockItem.imageFilename,
            created_at: stockItem.createdAt.toISOString(),
            updated_at: new Date().toISOString()
        };

        if (stockItem.id) {
            // Update existing
            const sql = `
                UPDATE stock_items 
                SET name = ?, quantity = ?, unit = ?, group_id = ?, 
                    properties = ?, image_filename = ?, updated_at = ?
                WHERE id = ? AND store_id = ?
            `;
            
            const result = await this.db.run(sql, [
                data.name, data.quantity, data.unit, data.group_id,
                data.properties, data.image_filename, data.updated_at,
                stockItem.id, data.store_id
            ]);
            
            return result.changes > 0 ? stockItem : null;
        } else {
            // Create new
            const sql = `
                INSERT INTO stock_items 
                (store_id, name, quantity, unit, group_id, properties, image_filename, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            `;
            
            const result = await this.db.run(sql, [
                data.store_id, data.name, data.quantity, data.unit,
                data.group_id, data.properties, data.image_filename,
                data.created_at, data.updated_at
            ]);
            
            stockItem.id = result.lastID;
            return stockItem;
        }
    }

    async delete(itemId, storeId) {
        const sql = `DELETE FROM stock_items WHERE id = ? AND store_id = ?`;
        const result = await this.db.run(sql, [itemId, storeId]);
        return result.changes > 0;
    }

    async updateQuantity(itemId, storeId, newQuantity) {
        const sql = `
            UPDATE stock_items 
            SET quantity = ?, updated_at = ?
            WHERE id = ? AND store_id = ?
        `;
        
        const result = await this.db.run(sql, [
            newQuantity.value,
            new Date().toISOString(),
            itemId,
            storeId
        ]);
        
        return result.changes > 0;
    }    async findByGroupId(groupId, storeId) {
        const sql = `
            SELECT 
                si.*,
                g.name as group_name
            FROM stock_items si
            LEFT JOIN item_groups g ON si.group_id = g.id
            WHERE si.group_id = ? AND si.store_id = ?
            ORDER BY si.name ASC
        `;
        
        const rows = await this.db.all(sql, [groupId, storeId]);
        return rows.map(row => this.mapRowToEntity(row));
    }    async searchByName(storeId, searchTerm) {
        const sql = `
            SELECT 
                si.*,
                g.name as group_name
            FROM stock_items si
            LEFT JOIN item_groups g ON si.group_id = g.id
            WHERE si.store_id = ? AND si.name LIKE ?
            ORDER BY si.name ASC
        `;
        
        const rows = await this.db.all(sql, [storeId, `%${searchTerm}%`]);
        return rows.map(row => this.mapRowToEntity(row));
    }

    async getTotalItemsCount(storeId) {
        const sql = `SELECT COUNT(*) as count FROM stock_items WHERE store_id = ?`;
        const row = await this.db.get(sql, [storeId]);
        return row.count || 0;
    }    async getLowStockItems(storeId, threshold = 10) {
        const sql = `
            SELECT 
                si.*,
                g.name as group_name
            FROM stock_items si
            LEFT JOIN item_groups g ON si.group_id = g.id
            WHERE si.store_id = ? AND si.quantity <= ?
            ORDER BY si.quantity ASC, si.name ASC
        `;
        
        const rows = await this.db.all(sql, [storeId, threshold]);
        return rows.map(row => this.mapRowToEntity(row));
    }    mapRowToEntity(row) {
        const properties = row.properties ? JSON.parse(row.properties) : {};
        
        return new StockItem({
            id: row.id,
            storeId: row.store_id,
            name: row.name,
            quantity: new Quantity(row.quantity, row.unit || 'un'),
            groupId: row.group_id,
            properties,
            imageFilename: row.image_filename,
            createdAt: new Date(row.created_at),
            updatedAt: new Date(row.updated_at),
            // Additional group information if joined
            groupName: row.group_name
        });
    }
}

module.exports = { SQLiteStockRepository };
