<?php

namespace App\Config;

use PDO;
use Exception;
use Throwable;

class TransactionManager {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Execute a closure inside a database transaction block
     */
    public function transaction(callable $callback): mixed {
        try {
            $this->db->beginTransaction();
            
            $result = $callback($this->db);
            
            $this->db->commit();
            return $result;
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            error_log("Transaction Failed & Rolled Back: " . $e->getMessage());
            throw new Exception("Transaction operation failed.");
        }
    }
}
