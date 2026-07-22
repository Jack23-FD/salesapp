<?php

namespace App\Services;

use App\DTOs\CategoryDTO;
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

        $dto = CategoryDTO::fromArray($data, $userContext['company_id'], $userContext['uid']);
        $id = bin2hex(random_bytes(16));

        try {
            $insertData = array_merge($dto->toDatabaseArray(), ['id' => $id]);

            $this->categoryRepo->create($insertData);
            return ['id' => $id, 'name' => $dto->name];
        } catch (Exception $e) {
            error_log("Failed to create category: " . $e->getMessage());
            Response::error("Failed to create category.", 500);
        }
    }

    public function updateCategory(string $id, array $userContext, array $data): bool {
        if (empty($data['name'])) {
            Response::badRequest("Category name is required.");
        }

        $existing = $this->categoryRepo->findById($id, $userContext['company_id']);
        if (!$existing) {
            Response::notFound("Category not found.");
        }

        $dto = CategoryDTO::fromArray(array_merge(['id' => $id], $data), $userContext['company_id'], $userContext['uid']);

        try {
            $updateData = [
                'name' => $dto->name,
                'description' => $dto->description,
                'icon_code_point' => $dto->iconCodePoint,
                'icon_font_family' => $dto->iconFontFamily,
                'icon_font_package' => $dto->iconFontPackage,
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
