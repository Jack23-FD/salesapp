<?php

namespace App\Models;

/**
 * License Model
 * Represents a License record entity in the system.
 */
class License {
    public ?int $id;
    public string $licenseKey;
    public string $customerName;
    public string $expiryDate;
    public string $status;
    public ?string $createdAt;

    public function __construct(
        ?int $id = null,
        string $licenseKey = '',
        string $customerName = '',
        string $expiryDate = '',
        string $status = 'active',
        ?string $createdAt = null
    ) {
        $this->id = $id;
        $this->licenseKey = $licenseKey;
        $this->customerName = $customerName;
        $this->expiryDate = $expiryDate;
        $this->status = $status;
        $this->createdAt = $createdAt;
    }

    public static function fromArray(array $data): self {
        return new self(
            id: isset($data['id']) ? (int)$data['id'] : null,
            licenseKey: $data['license_key'] ?? '',
            customerName: $data['customer_name'] ?? '',
            expiryDate: $data['expiry_date'] ?? '',
            status: $data['status'] ?? 'active',
            createdAt: $data['created_at'] ?? null
        );
    }

    public function toArray(): array {
        return [
            'id' => $this->id,
            'license_key' => $this->licenseKey,
            'customer_name' => $this->customerName,
            'expiry_date' => $this->expiryDate,
            'status' => $this->status,
            'created_at' => $this->createdAt,
        ];
    }
}
