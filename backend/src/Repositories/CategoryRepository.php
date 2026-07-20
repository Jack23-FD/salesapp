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

    /**
     * Hard-delete all products belonging to a category
     */
    public function deleteProductsByCategory(string $categoryId, string $companyId): void {
        $sql = "DELETE FROM products WHERE category_id = :category_id AND company_id = :company_id";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'category_id' => $categoryId,
                'company_id' => $companyId
            ]);
        } catch (PDOException $e) {
            error_log("Error in deleteProductsByCategory on products: " . $e->getMessage());
            throw new Exception("Failed to delete products associated with this category.");
        }
    }
}
