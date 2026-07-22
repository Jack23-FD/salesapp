<?php

namespace App\DTOs;

use JsonSerializable;

abstract class BaseDTO implements JsonSerializable {
    /**
     * Convert DTO properties to an associative array.
     */
    public function toArray(): array {
        return get_object_vars($this);
    }

    /**
     * Specify data which should be serialized to JSON.
     */
    public function jsonSerialize(): mixed {
        return $this->toArray();
    }
}
