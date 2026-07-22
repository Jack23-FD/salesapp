<?php

namespace App\DTOs;

readonly class CategoryDTO extends BaseDTO {
    public function __construct(
        public ?string $id,
        public string $companyId,
        public string $name,
        public ?string $description = null,
        public ?int $iconCodePoint = null,
        public ?string $iconFontFamily = null,
        public ?string $iconFontPackage = null,
        public ?string $createdBy = null,
        public string $status = 'active'
    ) {}

    public static function fromArray(array $data, string $companyId = '', string $userId = ''): self {
        return new self(
            id: $data['id'] ?? null,
            companyId: $data['company_id'] ?? $companyId,
            name: trim($data['name'] ?? ''),
            description: $data['description'] ?? null,
            iconCodePoint: isset($data['iconCodePoint']) ? intval($data['iconCodePoint']) : (isset($data['icon_code_point']) ? intval($data['icon_code_point']) : null),
            iconFontFamily: $data['iconFontFamily'] ?? $data['icon_font_family'] ?? null,
            iconFontPackage: $data['iconFontPackage'] ?? $data['icon_font_package'] ?? null,
            createdBy: $data['created_by'] ?? $userId,
            status: $data['status'] ?? 'active'
        );
    }

    public function toDatabaseArray(): array {
        return [
            'id' => $this->id,
            'company_id' => $this->companyId,
            'name' => $this->name,
            'description' => $this->description,
            'icon_code_point' => $this->iconCodePoint,
            'icon_font_family' => $this->iconFontFamily,
            'icon_font_package' => $this->iconFontPackage,
            'created_by' => $this->createdBy,
            'status' => $this->status,
        ];
    }
}
