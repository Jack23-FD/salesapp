<?php

namespace App\Middleware;

use App\Utils\Response;

class RoleMiddleware {
    public static function isAdmin(array $authenticatedUser): void {
        if (!isset($authenticatedUser['role']) || $authenticatedUser['role'] !== 'admin') {
            Response::forbidden("Access Denied: Admin privileges required.");
        }
    }
}
