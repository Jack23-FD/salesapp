<?php

namespace App\Controllers;

use App\Services\TransactionService;
use App\Utils\Response;

class TransactionController {
    private TransactionService $transactionService;

    public function __construct() {
        $this->transactionService = new TransactionService();
    }

    /**
     * POST /api/v1/transactions
     */
    public function create(array $params, array $userContext): void {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $result = $this->transactionService->recordTransaction($userContext, $data);
        Response::success("Transaction recorded and stock updated successfully.", $result, 201);
    }

    /**
     * GET /api/v1/transactions/stats
     */
    public function stats(array $params, array $userContext): void {
        // Retrieve optional date filter, default to today
        $date = $_GET['date'] ?? date('Y-m-d');
        
        $result = $this->transactionService->getStats($userContext['company_id'], $date);
        Response::success("Metrics retrieved successfully.", $result);
    }
}
