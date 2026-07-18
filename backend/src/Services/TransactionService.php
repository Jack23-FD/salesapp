<?php

namespace App\Services;

use App\Repositories\TransactionRepository;
use App\Repositories\ProductRepository;
use App\Config\TransactionManager;
use App\Utils\Response;
use Exception;

class TransactionService {
    private TransactionRepository $transactionRepo;
    private ProductRepository $productRepo;
    private TransactionManager $txManager;

    public function __construct() {
        $this->transactionRepo = new TransactionRepository();
        $this->productRepo = new ProductRepository();
        $this->txManager = new TransactionManager();
    }

    /**
     * Record an Inbound or Outbound stock transaction and update the product stock level
     */
    public function recordTransaction(array $userContext, array $data): array {
        if (empty($data['productId']) || empty($data['quantity']) || empty($data['type'])) {
            Response::badRequest("Missing required transaction fields (productId, quantity, type).");
        }

        $productId = $data['productId'];
        $qty = intval($data['quantity']);
        $type = strtolower($data['type']);

        if ($qty <= 0) {
            Response::badRequest("Transaction quantity must be greater than zero.");
        }

        if ($type !== 'inbound' && $type !== 'outbound') {
            Response::badRequest("Invalid transaction type. Must be 'inbound' or 'outbound'.");
        }

        // Verify product exists and belongs to company
        $product = $this->productRepo->findById($productId, $userContext['company_id']);
        if (!$product) {
            Response::notFound("Product not found.");
        }

        // Business Rule: For outbound transactions, verify sufficient stock level exists
        if ($type === 'outbound' && $product['quantity'] < $qty) {
            Response::badRequest("Insufficient stock level. Available: {$product['quantity']}, Requested: {$qty}");
        }

        $id = bin2hex(random_bytes(16)); // UUID for transaction log
        $dateStr = $data['date'] ?? date('Y-m-d H:i:s');

        try {
            return $this->txManager->transaction(function() use ($id, $userContext, $productId, $qty, $type, $dateStr, $product) {
                // 1. Create transaction log record
                $this->transactionRepo->create([
                    'id' => $id,
                    'company_id' => $userContext['company_id'],
                    'product_id' => $productId,
                    'quantity' => $qty,
                    'type' => $type,
                    'date' => $dateStr,
                    'created_by' => $userContext['uid']
                ]);

                // 2. Adjust product inventory quantity
                $newQty = ($type === 'inbound') ? ($product['quantity'] + $qty) : ($product['quantity'] - $qty);
                $this->productRepo->update($productId, $userContext['company_id'], [
                    'quantity' => $newQty,
                    'updated_by' => $userContext['uid']
                ]);

                return [
                    'id' => $id,
                    'productId' => $productId,
                    'newQuantity' => $newQty
                ];
            });
        } catch (Exception $e) {
            error_log("Failed to record transaction: " . $e->getMessage());
            Response::error("Transaction recording failed.", 500);
        }
    }

    /**
     * Retrieve aggregated dashboard stats for a selected date
     */
    public function getStats(string $companyId, string $date): array {
        try {
            $inbound = $this->transactionRepo->getInboundStats($companyId, $date);
            $outbound = $this->transactionRepo->getOutboundStats($companyId, $date);

            $inboundCatCount = $this->transactionRepo->getActiveCategoriesCount($companyId, $date, 'inbound');
            $outboundCatCount = $this->transactionRepo->getActiveCategoriesCount($companyId, $date, 'outbound');

            return [
                'inbound' => [
                    'units' => intval($inbound['total_units']),
                    'categories' => $inboundCatCount,
                    'value' => floatval($inbound['total_value'])
                ],
                'outbound' => [
                    'units' => intval($outbound['total_units']),
                    'categories' => $outboundCatCount,
                    'value' => floatval($outbound['total_value'])
                ]
            ];
        } catch (Exception $e) {
            error_log("Failed to fetch dashboard metrics: " . $e->getMessage());
            Response::error("Metrics aggregation failed.", 500);
        }
    }
}
