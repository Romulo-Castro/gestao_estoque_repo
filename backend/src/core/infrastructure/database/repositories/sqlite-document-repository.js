// Document Repository Implementation
const Document = require('../../../domain/entities/document');
const DocumentType = require('../../../domain/value-objects/document-type');
const Money = require('../../../domain/value-objects/money');
const DateRange = require('../../../domain/value-objects/date-range');

class SQLiteDocumentRepository {
    constructor(database) {
        this.db = database;
    }

    async findByStoreId(storeId, filters = {}) {
        let sql = `
            SELECT 
                d.*,
                c.name as customer_name,
                s.name as supplier_name
            FROM documents d
            LEFT JOIN customers c ON d.customer_id = c.id
            LEFT JOIN suppliers s ON d.supplier_id = s.id
            WHERE d.store_id = ?
        `;
        
        const params = [storeId];

        // Apply filters
        if (filters.type) {
            sql += ' AND d.type = ?';
            params.push(filters.type);
        }

        if (filters.dateRange && filters.dateRange instanceof DateRange) {
            sql += ' AND d.document_date BETWEEN ? AND ?';
            params.push(filters.dateRange.startDate.toISOString());
            params.push(filters.dateRange.endDate.toISOString());
        }

        if (filters.customerId) {
            sql += ' AND d.customer_id = ?';
            params.push(filters.customerId);
        }

        if (filters.supplierId) {
            sql += ' AND d.supplier_id = ?';
            params.push(filters.supplierId);
        }

        sql += ' ORDER BY d.document_date DESC, d.created_at DESC';

        const rows = await this.db.all(sql, params);
        return rows.map(row => this.mapRowToEntity(row));
    }

    async findById(documentId, storeId) {
        const sql = `
            SELECT 
                d.*,
                c.name as customer_name,
                s.name as supplier_name
            FROM documents d
            LEFT JOIN customers c ON d.customer_id = c.id
            LEFT JOIN suppliers s ON d.supplier_id = s.id
            WHERE d.id = ? AND d.store_id = ?
        `;
        
        const row = await this.db.get(sql, [documentId, storeId]);
        if (!row) return null;

        const document = this.mapRowToEntity(row);

        // Load document items
        const itemsSql = `
            SELECT 
                di.*,
                si.name as item_name,
                si.unit
            FROM document_items di
            JOIN stock_items si ON di.stock_item_id = si.id
            WHERE di.document_id = ?
            ORDER BY di.id ASC
        `;
        
        const itemRows = await this.db.all(itemsSql, [documentId]);
        document.items = itemRows.map(item => ({
            id: item.id,
            stockItemId: item.stock_item_id,
            itemName: item.item_name,
            quantity: item.quantity,
            unit: item.unit,
            unitPrice: new Money(item.unit_price, 'BRL'),
            totalPrice: new Money(item.total_price, 'BRL'),
            notes: item.notes
        }));

        return document;
    }

    async save(document) {
        const data = {
            store_id: document.storeId,
            type: document.type.value,
            document_number: document.documentNumber,
            document_date: document.documentDate.toISOString(),
            customer_id: document.customerId,
            supplier_id: document.supplierId,
            total_amount: document.totalAmount ? document.totalAmount.amount : 0,
            currency: document.totalAmount ? document.totalAmount.currency : 'BRL',
            notes: document.notes,
            created_at: document.createdAt.toISOString(),
            updated_at: new Date().toISOString()
        };

        if (document.id) {
            // Update existing document
            const sql = `
                UPDATE documents 
                SET type = ?, document_number = ?, document_date = ?, 
                    customer_id = ?, supplier_id = ?, total_amount = ?, 
                    currency = ?, notes = ?, updated_at = ? 
                WHERE id = ? AND store_id = ?
            `;
            
            const result = await this.db.run(sql, [
                data.type, data.document_number, data.document_date,
                data.customer_id, data.supplier_id, data.total_amount,
                data.currency, data.notes, data.updated_at,
                document.id, data.store_id
            ]);
            
            if (result.changes === 0) return null;
        } else {
            // Create new document
            const sql = `
                INSERT INTO documents 
                (store_id, type, document_number, document_date, customer_id, 
                 supplier_id, total_amount, currency, notes, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
            `;
            
            const result = await this.db.run(sql, [
                data.store_id, data.type, data.document_number, data.document_date,
                data.customer_id, data.supplier_id, data.total_amount,
                data.currency, data.notes, data.created_at, data.updated_at
            ]);
            
            document.id = result.lastID;
        }

        // Save document items if present
        if (document.items && document.items.length > 0) {
            await this.saveDocumentItems(document.id, document.items);
        }

        return document;
    }

    async saveDocumentItems(documentId, items) {
        // First delete existing items
        await this.db.run('DELETE FROM document_items WHERE document_id = ?', [documentId]);

        // Insert new items
        const sql = `
            INSERT INTO document_items 
            (document_id, stock_item_id, quantity, unit_price, total_price, notes)
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        for (const item of items) {
            await this.db.run(sql, [
                documentId,
                item.stockItemId,
                item.quantity,
                item.unitPrice ? item.unitPrice.amount : 0,
                item.totalPrice ? item.totalPrice.amount : 0,
                item.notes
            ]);
        }
    }

    async delete(documentId, storeId) {
        // SQLite will handle cascade deletes for document_items
        const sql = `DELETE FROM documents WHERE id = ? AND store_id = ?`;
        const result = await this.db.run(sql, [documentId, storeId]);
        return result.changes > 0;
    }

    // New methods for use cases
    async findByIdAndStore(documentId, storeId) {
        return await this.findById(documentId, storeId);
    }

    async findByIdAndStoreWithItems(documentId, storeId) {
        return await this.findById(documentId, storeId);
    }

    async createWithTransaction(document, stockAdjustments = []) {
        try {
            await this.db.run('BEGIN TRANSACTION');

            // Create the document
            const savedDocument = await this.save(document);

            // Apply stock adjustments if provided
            for (const adjustment of stockAdjustments) {
                await this.db.run(
                    'UPDATE stock_items SET quantity = quantity + ?, updated_at = ? WHERE id = ? AND store_id = ?',
                    [adjustment.quantityChange, new Date().toISOString(), adjustment.stockItemId, document.storeId]
                );
            }

            await this.db.run('COMMIT');
            return savedDocument;
        } catch (error) {
            await this.db.run('ROLLBACK');
            throw error;
        }
    }

    async updateHeader(documentId, storeId, headerData) {
        const sql = `
            UPDATE documents 
            SET document_date = ?, customer_id = ?, supplier_id = ?, notes = ?, updated_at = ?
            WHERE id = ? AND store_id = ?
        `;
        
        const result = await this.db.run(sql, [
            headerData.documentDate ? headerData.documentDate.toISOString() : null,
            headerData.customerId || null,
            headerData.supplierId || null,
            headerData.notes || null,
            new Date().toISOString(),
            documentId,
            storeId
        ]);
        
        return result.changes > 0;
    }

    async cancelWithTransaction(documentId, storeId, stockReversals = []) {
        try {
            await this.db.run('BEGIN TRANSACTION');

            // Delete the document
            const deleted = await this.delete(documentId, storeId);
            if (!deleted) {
                throw new Error('Documento não encontrado ou já removido');
            }

            // Apply stock reversals if provided
            for (const reversal of stockReversals) {
                await this.db.run(
                    'UPDATE stock_items SET quantity = quantity + ?, updated_at = ? WHERE id = ? AND store_id = ?',
                    [reversal.quantityChange, new Date().toISOString(), reversal.stockItemId, storeId]
                );
            }

            await this.db.run('COMMIT');
            // Since the document is deleted, we don't return it. 
            // The use case can return a success message or the ID.
            return { id: documentId, cancelled: true }; 
        } catch (error) {
            await this.db.run('ROLLBACK');
            throw error;
        }
    }

    async findByDateRange(storeId, dateRange) {
        const sql = `
            SELECT 
                d.*,
                c.name as customer_name,
                s.name as supplier_name
            FROM documents d
            LEFT JOIN customers c ON d.customer_id = c.id
            LEFT JOIN suppliers s ON d.supplier_id = s.id
            WHERE d.store_id = ? AND d.document_date BETWEEN ? AND ?
            ORDER BY d.document_date DESC
        `;
        
        const rows = await this.db.all(sql, [
            storeId,
            dateRange.startDate.toISOString(),
            dateRange.endDate.toISOString()
        ]);
        
        return rows.map(row => this.mapRowToEntity(row));
    }

    async getStatsByPeriod(storeId, dateRange) {
        const sql = `
            SELECT 
                type,
                COUNT(*) as count,
                SUM(total_amount) as total_amount,
                AVG(total_amount) as avg_amount
            FROM documents 
            WHERE store_id = ? AND document_date BETWEEN ? AND ?
            GROUP BY type
        `;
        
        const rows = await this.db.all(sql, [
            storeId,
            dateRange.startDate.toISOString(),
            dateRange.endDate.toISOString()
        ]);
        
        return rows.reduce((stats, row) => {
            stats[row.type] = {
                count: row.count,
                totalAmount: new Money(row.total_amount || 0, 'BRL'),
                averageAmount: new Money(row.avg_amount || 0, 'BRL')
            };
            return stats;
        }, {});
    }

    async getMonthlyTotals(storeId, year) {
        const sql = `
            SELECT 
                strftime('%m', document_date) as month,
                type,
                SUM(total_amount) as total
            FROM documents 
            WHERE store_id = ? AND strftime('%Y', document_date) = ?
            GROUP BY month, type
            ORDER BY month
        `;
        
        const rows = await this.db.all(sql, [storeId, year.toString()]);
        
        const monthlyData = {};
        for (let i = 1; i <= 12; i++) {
            const month = i.toString().padStart(2, '0');
            monthlyData[month] = {
                ENTRADA: new Money(0, 'BRL'),
                SAIDA: new Money(0, 'BRL'),
                BALANCA: new Money(0, 'BRL')
            };
        }

        rows.forEach(row => {
            monthlyData[row.month][row.type] = new Money(row.total || 0, 'BRL');
        });

        return monthlyData;
    }

    mapRowToEntity(row) {
        return new Document({
            id: row.id,
            storeId: row.store_id,
            type: new DocumentType(row.type),
            documentNumber: row.document_number,
            documentDate: new Date(row.document_date),
            customerId: row.customer_id,
            supplierId: row.supplier_id,
            totalAmount: new Money(row.total_amount || 0, row.currency || 'BRL'),
            notes: row.notes,
            createdAt: new Date(row.created_at),
            updatedAt: new Date(row.updated_at),
            // Additional joined data
            customerName: row.customer_name,
            supplierName: row.supplier_name
        });
    }
}

module.exports = { SQLiteDocumentRepository };
