<?php

namespace App\Repositories;

use App\Config\Database;
use PDO;
use PDOException;
use Exception;

abstract class BaseRepository {
    protected PDO $db;
    protected string $tableName;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
        $this->tableName = $this->getTableName();
    }

    abstract protected function getTableName(): string;

    /**
     * Fetch a record by its Primary Key
     */
    public function findById(string $id, string $companyId): ?array {
        $sql = "SELECT * FROM {$this->tableName} WHERE id = :id AND company_id = :company_id AND deleted_at IS NULL LIMIT 1";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'id' => $id,
                'company_id' => $companyId
            ]);
            $result = $stmt->fetch();
            return $result ? $result : null;
        } catch (PDOException $e) {
            error_log("Error in findById on {$this->tableName}: " . $e->getMessage());
            throw new Exception("Database query failed.");
        }
    }

    /**
     * Create a new record
     */
    public function create(array $data): bool {
        $columns = implode(', ', array_keys($data));
        $placeholders = ':' . implode(', :', array_keys($data));
        
        $sql = "INSERT INTO {$this->tableName} ({$columns}) VALUES ({$placeholders})";
        
        try {
            $stmt = $this->db->prepare($sql);
            return $stmt->execute($data);
        } catch (PDOException $e) {
            error_log("Error in create on {$this->tableName}: " . $e->getMessage());
            throw new Exception("Failed to insert record.");
        }
    }

    /**
     * Update an existing record
     */
    public function update(string $id, string $companyId, array $data): bool {
        $fields = '';
        foreach ($data as $key => $value) {
            $fields .= "{$key} = :{$key}, ";
        }
        $fields = rtrim($fields, ', ');

        $sql = "UPDATE {$this->tableName} SET {$fields} WHERE id = :target_id AND company_id = :target_company_id AND deleted_at IS NULL";
        
        // Merge the target filters into query parameters
        $data['target_id'] = $id;
        $data['target_company_id'] = $companyId;

        try {
            $stmt = $this->db->prepare($sql);
            return $stmt->execute($data);
        } catch (PDOException $e) {
            error_log("Error in update on {$this->tableName}: " . $e->getMessage());
            throw new Exception("Failed to update record.");
        }
    }

    public function softDelete(string $id, string $companyId, string $userId): bool {
        $sql = "UPDATE {$this->tableName} 
                SET deleted_at = NOW(), deleted_by = :deleted_by, status = 'deleted' 
                WHERE id = :id AND company_id = :company_id AND deleted_at IS NULL";
        try {
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                'id' => $id,
                'company_id' => $companyId,
                'deleted_by' => $userId
            ]);
        } catch (PDOException $e) {
            error_log("Error in softDelete on {$this->tableName}: " . $e->getMessage());
            throw new Exception("Failed to delete record.");
        }
    }

    /**
     * Hard Delete a record
     */
    public function hardDelete(string $id, string $companyId): bool {
        $sql = "DELETE FROM {$this->tableName} WHERE id = :id AND company_id = :company_id";
        try {
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                'id' => $id,
                'company_id' => $companyId
            ]);
        } catch (PDOException $e) {
            error_log("Error in hardDelete on {$this->tableName}: " . $e->getMessage());
            throw new Exception("Failed to delete record.");
        }
    }
}
