<?php

namespace App\DTOs;

readonly class TransactionDTO extends BaseDTO {
    public function __construct(
        public ?string $id,
        public string $companyId,
        public string $productId,
        public string $type,
        public int $quantity,
        public ?string $notes = null,
        public ?string $createdBy = null,
        public ?string $createdAt = null
    ) {}

    public static function fromArray(array $data, string $companyId = '', string $userId = ''): self {
        return new self(
            id: $data['id'] ?? null,
            companyId: $data['company_id'] ?? $companyId,
            productId: $data['productId'] ?? $data['product_id'] ?? '',
            type: strtolower($data['type'] ?? 'inbound'),
            quantity: intval($data['quantity'] ?? 0),
            notes: $data['notes'] ?? null,
            createdBy: $data['created_by'] ?? $userId,
            createdAt: $data['date'] ?? $data['created_at'] ?? date('Y-m-d H:i:s')
        );
    }

    public function toDatabaseArray(): array {
        return [
            'id' => $this->id,
            'company_id' => $this->companyId,
            'product_id' => $this->productId,
            'type' => $this->type,
            'quantity' => $this->quantity,
            'notes' => $this->notes,
            'created_by' => $this->createdBy,
            'created_at' => $this->createdAt,
        ];
    }
}
