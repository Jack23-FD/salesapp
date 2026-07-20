<?php

namespace App\Controllers;

use App\Services\AuthService;
use App\Utils\Response;
use App\Middleware\RoleMiddleware;

class AuthController {
    private AuthService $authService;

    public function __construct() {
        $this->authService = new AuthService();
    }

    /**
     * POST /api/v1/auth/register (Public - requires Firebase verification context)
     */
    public function registerAdmin(array $params, array $userContext): void {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        
        // Ensure request payload UID matches the verified token UID
        $data['uid'] = $userContext['uid'];
        $data['email'] = $userContext['email'];

        $result = $this->authService->registerUser($data);
        Response::success("User registered successfully.", $result, 201);
    }

    /**
     * GET /api/v1/users/profile
     */
    public function getProfile(array $params, array $userContext): void {
        $result = $this->authService->getProfile($userContext['uid']);
        Response::success("Profile retrieved successfully.", $result);
    }

    /**
     * POST /api/v1/users/staff (Admin Only)
     */
    public function registerStaff(array $params, array $userContext): void {
        RoleMiddleware::isAdmin($userContext);

        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $result = $this->authService->registerStaff($userContext, $data);
        Response::success("Staff member registered successfully.", $result, 201);
    }

    /**
     * GET /api/v1/users/staff (Admin Only)
     */
    public function listStaff(array $params, array $userContext): void {
        RoleMiddleware::isAdmin($userContext);

        $result = $this->authService->listStaff($userContext['company_id']);
        Response::success("Staff list retrieved successfully.", $result);
    }
}
