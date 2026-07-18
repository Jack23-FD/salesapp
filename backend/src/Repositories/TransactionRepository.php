<?php

namespace App\Repositories;

use PDO;
use PDOException;
use Exception;

class TransactionRepository extends BaseRepository {
    protected function getTableName(): string {
        return 'transactions';
    }

    /**
     * Fetch aggregated statistics for Inbound transactions on a specific date
     */
    public function getInboundStats(string $companyId, string $date): array {
        $sql = "SELECT COALESCE(SUM(t.quantity), 0) as total_units,
                       COUNT(DISTINCT t.product_id) as total_products,
                       COALESCE(SUM(t.quantity * p.price), 0.0) as total_value
                FROM transactions t
                JOIN products p ON t.product_id = p.id
                WHERE t.company_id = :company_id 
                  AND DATE(t.date) = DATE(:date) 
                  AND t.type = 'inbound'";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'company_id' => $companyId,
                'date' => $date
            ]);
            return $stmt->fetch();
        } catch (PDOException $e) {
            error_log("Error in getInboundStats: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }

    /**
     * Fetch aggregated statistics for Outbound transactions on a specific date
     */
    public function getOutboundStats(string $companyId, string $date): array {
        $sql = "SELECT COALESCE(SUM(t.quantity), 0) as total_units,
                       COUNT(DISTINCT t.product_id) as total_products,
                       COALESCE(SUM(t.quantity * p.price), 0.0) as total_value
                FROM transactions t
                JOIN products p ON t.product_id = p.id
                WHERE t.company_id = :company_id 
                  AND DATE(t.date) = DATE(:date) 
                  AND t.type = 'outbound'";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'company_id' => $companyId,
                'date' => $date
            ]);
            return $stmt->fetch();
        } catch (PDOException $e) {
            error_log("Error in getOutboundStats: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }

    /**
     * Count unique product categories touched by transactions on a specific date
     */
    public function getActiveCategoriesCount(string $companyId, string $date, string $type): int {
        $sql = "SELECT COUNT(DISTINCT p.category_id)
                FROM transactions t
                JOIN products p ON t.product_id = p.id
                WHERE t.company_id = :company_id 
                  AND DATE(t.date) = DATE(:date) 
                  AND t.type = :type";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'company_id' => $companyId,
                'date' => $date,
                'type' => $type
            ]);
            return (int) $stmt->fetchColumn();
        } catch (PDOException $e) {
            error_log("Error in getActiveCategoriesCount: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }
}
