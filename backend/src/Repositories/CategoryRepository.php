<?php

namespace App\Repositories;

use PDO;
use PDOException;
use Exception;

class CategoryRepository extends BaseRepository {
    protected function getTableName(): string {
        return 'categories';
    }

    /**
     * List all active categories for a company
     */
    public function listByCompany(string $companyId): array {
        $sql = "SELECT id, name, description, icon_code_point, icon_font_family, icon_font_package, status, created_at 
                FROM categories 
                WHERE company_id = :company_id AND deleted_at IS NULL 
                ORDER BY name ASC";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute(['company_id' => $companyId]);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            error_log("Error in listByCompany on categories: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }
}
