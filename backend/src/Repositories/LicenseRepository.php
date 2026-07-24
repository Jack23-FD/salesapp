<?php

namespace App\Repositories;

use App\Config\Database;
use PDO;
use PDOException;
use Exception;

/**
 * License Repository
 * Handles direct database operations for the licenses table.
 */
class LicenseRepository {
    protected PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Insert a new license record into the database.
     */
    public function create(array $data): bool {
        $sql = "INSERT INTO licenses (license_key, customer_name, expiry_date, status) 
                VALUES (:license_key, :customer_name, :expiry_date, :status)";
        try {
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([
                'license_key' => $data['license_key'],
                'customer_name' => $data['customer_name'],
                'expiry_date' => $data['expiry_date'],
                'status' => $data['status'] ?? 'active'
            ]);
        } catch (PDOException $e) {
            error_log("LicenseRepository create error: " . $e->getMessage());
            throw new Exception("Database query failed while creating license.");
        }
    }

    /**
     * Find a license record by its unique license key.
     */
    public function findByKey(string $licenseKey): ?array {
        $sql = "SELECT * FROM licenses WHERE license_key = :license_key LIMIT 1";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute(['license_key' => $licenseKey]);
            $result = $stmt->fetch();
            return $result ?: null;
        } catch (PDOException $e) {
            error_log("LicenseRepository findByKey error: " . $e->getMessage());
            throw new Exception("Database query failed while fetching license.");
        }
    }
}
