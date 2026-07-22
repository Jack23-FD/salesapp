<?php

namespace App\DTOs;

readonly class ProductDTO extends BaseDTO {
    public function __construct(
        public ?string $id,
        public string $companyId,
        public string $categoryId,
        public string $name,
        public int $quantity,
        public string $unit,
        public float $price,
        public ?string $barcode = null,
        public ?float $minLevel = null,
        public ?string $imageUrl = null,
        public ?string $createdBy = null,
        public string $status = 'active'
    ) {}

    public static function fromArray(array $data, string $companyId = '', string $userId = ''): self {
        return new self(
            id: $data['id'] ?? null,
            companyId: $data['company_id'] ?? $companyId,
            categoryId: $data['categoryId'] ?? $data['category_id'] ?? '',
            name: trim($data['name'] ?? ''),
            quantity: intval($data['quantity'] ?? 0),
            unit: $data['unit'] ?? 'pcs',
            price: floatval($data['price'] ?? 0),
            barcode: !empty($data['barcode']) ? trim($data['barcode']) : null,
            minLevel: isset($data['minLevel']) ? floatval($data['minLevel']) : (isset($data['min_level']) ? floatval($data['min_level']) : null),
            imageUrl: $data['imageUrl'] ?? $data['image_url'] ?? null,
            createdBy: $data['created_by'] ?? $userId,
            status: $data['status'] ?? 'active'
        );
    }

    public function toDatabaseArray(): array {
        return [
            'id' => $this->id,
            'company_id' => $this->companyId,
            'category_id' => $this->categoryId,
            'name' => $this->name,
            'quantity' => $this->quantity,
            'unit' => $this->unit,
            'price' => $this->price,
            'barcode' => $this->barcode,
            'min_level' => $this->minLevel,
            'image_url' => $this->imageUrl,
            'created_by' => $this->createdBy,
            'status' => $this->status,
        ];
    }
}
