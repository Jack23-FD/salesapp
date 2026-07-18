<?php

namespace App\Controllers;

use App\Services\CategoryService;
use App\Utils\Response;

class CategoryController {
    private CategoryService $categoryService;

    public function __construct() {
        $this->categoryService = new CategoryService();
    }

    /**
     * GET /api/v1/categories
     */
    public function index(array $params, array $userContext): void {
        $result = $this->categoryService->listCategories($userContext['company_id']);
        Response::success("Categories retrieved successfully.", $result);
    }

    /**
     * POST /api/v1/categories
     */
    public function create(array $params, array $userContext): void {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $result = $this->categoryService->createCategory($userContext, $data);
        Response::success("Category created successfully.", $result, 201);
    }

    /**
     * PUT /api/v1/categories/{id}
     */
    public function update(array $params, array $userContext): void {
        $id = $params['id'] ?? '';
        if (empty($id)) {
            Response::badRequest("Category ID is required.");
        }

        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $this->categoryService->updateCategory($id, $userContext, $data);
        Response::success("Category updated successfully.");
    }

    /**
     * DELETE /api/v1/categories/{id}
     */
    public function delete(array $params, array $userContext): void {
        $id = $params['id'] ?? '';
        if (empty($id)) {
            Response::badRequest("Category ID is required.");
        }

        $this->categoryService->deleteCategory($id, $userContext);
        Response::success("Category deleted successfully.");
    }
}
