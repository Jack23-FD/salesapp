<?php

namespace App\Repositories;

class CompanyRepository extends BaseRepository {
    protected function getTableName(): string {
        return 'companies';
    }

    /**
     * Find a company by its exact name
     */
    public function findByName(string $name): ?array {
        $sql = "SELECT * FROM companies WHERE name = :name AND deleted_at IS NULL LIMIT 1";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute(['name' => $name]);
            $result = $stmt->fetch();
            return $result ? $result : null;
        } catch (\PDOException $e) {
            error_log("Error in findByName on companies: " . $e->getMessage());
            throw new \Exception("Database query failed.");
        }
    }
}
