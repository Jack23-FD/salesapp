<?php

namespace App\Services;

use App\Repositories\ProductRepository;
use App\Utils\Response;
use Exception;

class ProductService {
    private ProductRepository $productRepo;

    public function __construct() {
        $this->productRepo = new ProductRepository();
    }

    public function listProducts(string $companyId, ?string $categoryId = null, ?string $search = null): array {
        return $this->productRepo->listByCompany($companyId, $categoryId, $search);
    }

    public function createProduct(array $userContext, array $data): array {
        if (empty($data['name']) || empty($data['categoryId']) || !isset($data['price'])) {
            Response::badRequest("Missing required product fields (name, categoryId, price).");
        }

        $id = bin2hex(random_bytes(16));

        try {
            $insertData = [
                'id' => $id,
                'company_id' => $userContext['company_id'],
                'category_id' => $data['categoryId'],
                'name' => $data['name'],
                'quantity' => intval($data['quantity'] ?? 0),
                'unit' => $data['unit'] ?? 'pcs',
                'price' => floatval($data['price']),
                'barcode' => $data['barcode'] ?? null,
                'min_level' => isset($data['minLevel']) ? floatval($data['minLevel']) : null,
                'image_url' => $data['imageUrl'] ?? null,
                'created_by' => $userContext['uid'],
                'status' => 'active'
            ];

            $this->productRepo->create($insertData);
            return ['id' => $id, 'name' => $data['name']];
        } catch (Exception $e) {
            error_log("Failed to create product: " . $e->getMessage());
            Response::error("Failed to create product.", 500);
        }
    }

    public function updateProduct(string $id, array $userContext, array $data): bool {
        if (empty($data['name']) || empty($data['categoryId']) || !isset($data['price'])) {
            Response::badRequest("Missing required product fields.");
        }

        $existing = $this->productRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Product not found.");
        }

        try {
            $updateData = [
                'category_id' => $data['categoryId'],
                'name' => $data['name'],
                'quantity' => intval($data['quantity'] ?? 0),
                'unit' => $data['unit'] ?? 'pcs',
                'price' => floatval($data['price']),
                'barcode' => $data['barcode'] ?? null,
                'min_level' => isset($data['minLevel']) ? floatval($data['minLevel']) : null,
                'image_url' => $data['imageUrl'] ?? null,
                'updated_by' => $userContext['uid']
            ];

            return $this->productRepo->update($id, $userContext['company_id'], $updateData);
        } catch (Exception $e) {
            error_log("Failed to update product: " . $e->getMessage());
            Response::error("Failed to update product.", 500);
        }
    }

    public function deleteProduct(string $id, array $userContext): bool {
        $existing = $this->productRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Product not found.");
        }

        try {
            return $this->productRepo->softDelete($id, $userContext['company_id'], $userContext['uid']);
        } catch (Exception $e) {
            error_log("Failed to delete product: " . $e->getMessage());
            Response::error("Failed to delete product.", 500);
        }
    }
}
