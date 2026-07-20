<?php

namespace App\Repositories;

use PDO;
use PDOException;
use Exception;

class ProductRepository extends BaseRepository {
    protected function getTableName(): string {
        return 'products';
    }

    /**
     * List all active products for a company with optional filters
     */
    public function listByCompany(string $companyId, ?string $categoryId = null, ?string $search = null): array {
        $sql = "SELECT p.*, c.name as category_name 
                FROM products p
                JOIN categories c ON p.category_id = c.id AND c.deleted_at IS NULL
                WHERE p.company_id = :company_id AND p.deleted_at IS NULL";
        
        $params = ['company_id' => $companyId];

        if ($categoryId) {
            $sql .= " AND p.category_id = :category_id";
            $params['category_id'] = $categoryId;
        }

        if ($search) {
            $sql .= " AND (p.name LIKE :search OR p.barcode = :barcode)";
            $params['search'] = "%{$search}%";
            $params['barcode'] = $search;
        }

        $sql .= " ORDER BY p.name ASC";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            error_log("Error in listByCompany on products: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }

    /**
     * Check if a product exists by barcode inside a company
     */
    public function findByBarcode(string $companyId, string $barcode): ?array {
        $sql = "SELECT * FROM products WHERE company_id = :company_id AND barcode = :barcode AND deleted_at IS NULL LIMIT 1";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'company_id' => $companyId,
                'barcode' => $barcode
            ]);
            $result = $stmt->fetch();
            return $result ? $result : null;
        } catch (PDOException $e) {
            error_log("Error in findByBarcode on products: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }
}
