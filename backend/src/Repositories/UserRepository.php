<?php

namespace App\Repositories;

use PDO;
use PDOException;
use Exception;

class UserRepository extends BaseRepository {
    protected function getTableName(): string {
        return 'users';
    }

    /**
     * Fetch a user profile by their ID (UID)
     */
    public function findUserById(string $id): ?array {
        $sql = "SELECT u.*, c.name as company_name 
                FROM users u
                JOIN companies c ON u.company_id = c.id
                WHERE u.id = :id AND u.deleted_at IS NULL LIMIT 1";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute(['id' => $id]);
            $result = $stmt->fetch();
            return $result ? $result : null;
        } catch (PDOException $e) {
            error_log("Error in findUserById: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }

    /**
     * List all staff members for a specific company
     */
    public function listStaffByCompany(string $companyId): array {
        $sql = "SELECT id, name, email, phone_number, role, status, created_at 
                FROM users 
                WHERE company_id = :company_id AND deleted_at IS NULL";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute(['company_id' => $companyId]);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            error_log("Error in listStaffByCompany: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }
}
