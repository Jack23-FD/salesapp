<?php

namespace App\Controllers;

use App\Services\ProductService;
use App\Utils\Response;

class ProductController {
    private ProductService $productService;

    public function __construct() {
        $this->productService = new ProductService();
    }

    /**
     * GET /api/v1/products
     */
    public function index(array $params, array $userContext): void {
        // Capture optional query parameters for filtering and searching
        $categoryId = $_GET['categoryId'] ?? null;
        $search = $_GET['search'] ?? null;

        $result = $this->productService->listProducts($userContext['company_id'], $categoryId, $search);
        Response::success("Products retrieved successfully.", $result);
    }

    /**
     * POST /api/v1/products
     */
    public function create(array $params, array $userContext): void {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $result = $this->productService->createProduct($userContext, $data);
        Response::success("Product created successfully.", $result, 201);
    }

    /**
     * PUT /api/v1/products/{id}
     */
    public function update(array $params, array $userContext): void {
        $id = $params['id'] ?? '';
        if (empty($id)) {
            Response::badRequest("Product ID is required.");
        }

        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $this->productService->updateProduct($id, $userContext, $data);
        Response::success("Product updated successfully.");
    }

    /**
     * DELETE /api/v1/products/{id}
     */
    public function delete(array $params, array $userContext): void {
        $id = $params['id'] ?? '';
        if (empty($id)) {
            Response::badRequest("Product ID is required.");
        }

        $this->productService->deleteProduct($id, $userContext);
        Response::success("Product deleted successfully.");
    }
}
