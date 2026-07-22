<?php

namespace App\DTOs;

readonly class UserDTO extends BaseDTO {
    public function __construct(
        public ?string $uid,
        public ?string $companyId,
        public string $name,
        public string $email,
        public ?string $companyName = null,
        public ?string $phoneNumber = null,
        public string $role = 'staff',
        public string $status = 'active'
    ) {}

    public static function fromArray(array $data, ?string $companyId = null): self {
        return new self(
            uid: $data['uid'] ?? $data['id'] ?? null,
            companyId: $data['company_id'] ?? $companyId,
            name: trim($data['name'] ?? ''),
            email: trim($data['email'] ?? ''),
            companyName: $data['companyName'] ?? $data['company_name'] ?? null,
            phoneNumber: $data['phoneNumber'] ?? $data['phone_number'] ?? null,
            role: $data['role'] ?? 'staff',
            status: $data['status'] ?? 'active'
        );
    }

    public function toDatabaseArray(): array {
        return [
            'id' => $this->uid,
            'company_id' => $this->companyId,
            'name' => $this->name,
            'email' => $this->email,
            'phone_number' => $this->phoneNumber,
            'role' => $this->role,
            'status' => $this->status,
        ];
    }
}
