<?php

namespace App\Utils;

class Response {
    private static function convertToCamelCase(mixed $data): mixed {
        if (!is_array($data)) {
            return $data;
        }

        $result = [];
        foreach ($data as $key => $value) {
            $newKey = $key;
            if (is_string($key)) {
                // Convert snake_case to camelCase
                $newKey = lcfirst(str_replace(' ', '', ucwords(str_replace('_', ' ', $key))));
            }
            $result[$newKey] = self::convertToCamelCase($value);
        }
        return $result;
    }

    public static function json(string $status, string $message, mixed $data = null, int $statusCode = 200): void {
        http_response_code($statusCode);
        
        $response = [
            "status" => $status,
            "message" => $message
        ];

        if ($data !== null) {
            $response["data"] = self::convertToCamelCase($data);
        }

        echo json_encode($response, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        exit();
    }

    public static function success(string $message, mixed $data = null, int $statusCode = 200): void {
        self::json("success", $message, $data, $statusCode);
    }

    public static function error(string $message, int $statusCode = 500, mixed $errors = null): void {
        http_response_code($statusCode);
        
        $response = [
            "status" => "error",
            "message" => $message
        ];

        if ($errors !== null) {
            $response["errors"] = self::convertToCamelCase($errors);
        }

        echo json_encode($response, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        exit();
    }

    public static function badRequest(string $message = "Bad Request"): void {
        self::error($message, 400);
    }

    public static function unauthorized(string $message = "Unauthorized"): void {
        self::error($message, 401);
    }

    public static function forbidden(string $message = "Forbidden"): void {
        self::error($message, 403);
    }

    public static function notFound(string $message = "Resource Not Found"): void {
        self::error($message, 404);
    }
}
