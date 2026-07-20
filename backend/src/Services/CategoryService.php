<?php

namespace App\Services;

use App\Repositories\CategoryRepository;
use App\Utils\Response;
use Exception;

class CategoryService {
    private CategoryRepository $categoryRepo;

    public function __construct() {
        $this->categoryRepo = new CategoryRepository();
    }

    public function listCategories(string $companyId): array {
        return $this->categoryRepo->listByCompany($companyId);
    }

    public function createCategory(array $userContext, array $data): array {
        if (empty($data['name'])) {
            Response::badRequest("Category name is required.");
        }

        $id = bin2hex(random_bytes(16)); // Generate UUID

        try {
            $insertData = [
                'id' => $id,
                'company_id' => $userContext['company_id'],
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
                'icon_code_point' => $data['iconCodePoint'] ?? null,
                'icon_font_family' => $data['iconFontFamily'] ?? null,
                'icon_font_package' => $data['iconFontPackage'] ?? null,
                'created_by' => $userContext['uid'],
                'status' => 'active'
            ];

            $this->categoryRepo->create($insertData);
            return ['id' => $id, 'name' => $data['name']];
        } catch (Exception $e) {
            error_log("Failed to create category: " . $e->getMessage());
            Response::error("Failed to create category.", 500);
        }
    }

    public function updateCategory(string $id, array $userContext, array $data): bool {
        if (empty($data['name'])) {
            Response::badRequest("Category name is required.");
        }

        // Verify category exists and belongs to company
        $existing = $this->categoryRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Category not found.");
        }

        try {
            $updateData = [
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
                'icon_code_point' => $data['iconCodePoint'] ?? null,
                'icon_font_family' => $data['iconFontFamily'] ?? null,
                'icon_font_package' => $data['iconFontPackage'] ?? null,
                'updated_by' => $userContext['uid']
            ];

            return $this->categoryRepo->update($id, $userContext['company_id'], $updateData);
        } catch (Exception $e) {
            error_log("Failed to update category: " . $e->getMessage());
            Response::error("Failed to update category.", 500);
        }
    }

    public function deleteCategory(string $id, array $userContext): bool {
        $existing = $this->categoryRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Category not found.");
        }

        try {
            // 1. Delete all products belonging to this category
            $this->categoryRepo->deleteProductsByCategory($id, $userContext['company_id']);
            
            // 2. Delete the category itself
            return $this->categoryRepo->hardDelete($id, $userContext['company_id']);
        } catch (Exception $e) {
            error_log("Failed to delete category: " . $e->getMessage());
            Response::error("Failed to delete category: " . $e->getMessage(), 500);
        }
    }
}
