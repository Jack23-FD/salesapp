<?php

namespace App\Services;

use App\DTOs\ProductDTO;
use App\Repositories\ProductRepository;
use App\Utils\Response;
use Exception;

class ProductService
{
    private ProductRepository $productRepo;

    public function __construct()
    {
        $this->productRepo = new ProductRepository();
    }

    public function listProducts(string $companyId, ?string $categoryId = null, ?string $search = null): array
    {
        return $this->productRepo->listByCompany($companyId, $categoryId, $search);
    }

    public function createProduct(array $userContext, array $data): array
    {
        if (empty($data['name']) || empty($data['categoryId']) || !isset($data['price'])) {
            Response::badRequest("Missing required product fields (name, categoryId, price).");
        }

        $dto = ProductDTO::fromArray($data, $userContext['company_id'], $userContext['uid']);

        // Validate barcode uniqueness
        if (!empty($dto->barcode)) {
            $existingProduct = $this->productRepo->findByBarcode($userContext['company_id'], $dto->barcode);
            if ($existingProduct) {
                Response::badRequest("A product with this barcode already exists.");
            }
        }

        $id = bin2hex(random_bytes(16));

        try {
            $insertData = array_merge($dto->toDatabaseArray(), ['id' => $id]);

            $this->productRepo->create($insertData);

            // Record initial stock as an inbound transaction for the dashboard
            if ($insertData['quantity'] > 0) {
                $db = \App\Config\Database::getInstance()->getConnection();
                $transactionId = bin2hex(random_bytes(16));
                $stmt = $db->prepare("
                    INSERT INTO transactions (id, company_id, product_id, quantity, type, date, created_by)
                    VALUES (:id, :company_id, :product_id, :quantity, 'inbound', NOW(), :created_by)
                ");
                $stmt->execute([
                    'id' => $transactionId,
                    'company_id' => $insertData['company_id'],
                    'product_id' => $id,
                    'quantity' => $insertData['quantity'],
                    'created_by' => $insertData['created_by']
                ]);
            }

            return ['id' => $id, 'name' => $dto->name];
        } catch (Exception $e) {
            error_log("Failed to create product: " . $e->getMessage());
            Response::error("Failed to create product.", 500);
        }
    }

    public function updateProduct(string $id, array $userContext, array $data): bool
    {
        if (empty($data['name']) || empty($data['categoryId']) || !isset($data['price'])) {
            Response::badRequest("Missing required product fields.");
        }

        $existing = $this->productRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Product not found.");
        }

        $dto = ProductDTO::fromArray(array_merge(['id' => $id], $data), $userContext['company_id'], $userContext['uid']);

        // Validate barcode uniqueness
        if (!empty($dto->barcode)) {
            $existingProduct = $this->productRepo->findByBarcode($userContext['company_id'], $dto->barcode);
            if ($existingProduct && $existingProduct['id'] !== $id) {
                Response::badRequest("A product with this barcode already exists.");
            }
        }

        try {
            $updateData = [
                'category_id' => $dto->categoryId,
                'name' => $dto->name,
                'quantity' => $dto->quantity,
                'unit' => $dto->unit,
                'price' => $dto->price,
                'barcode' => $dto->barcode,
                'min_level' => $dto->minLevel,
                'image_url' => $dto->imageUrl,
                'updated_by' => $userContext['uid']
            ];

            return $this->productRepo->update($id, $userContext['company_id'], $updateData);
        } catch (Exception $e) {
            error_log("Failed to update product: " . $e->getMessage());
            Response::error("Failed to update product.", 500);
        }
    }

    public function deleteProduct(string $id, array $userContext): bool
    {
        $existing = $this->productRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Product not found.");
        }

        try {
            return $this->productRepo->hardDelete($id, $userContext['company_id']);
        } catch (Exception $e) {
            error_log("Failed to delete product: " . $e->getMessage());
            Response::error("Failed to delete product: " . $e->getMessage(), 500);
        }
    }
}
