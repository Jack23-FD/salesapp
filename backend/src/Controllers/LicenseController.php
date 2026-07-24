<?php

namespace App\Controllers;

use App\Services\LicenseService;
use App\Utils\Response;

/**
 * License Controller
 * Handles HTTP API endpoints for license creation and verification.
 */
class LicenseController {
    private LicenseService $licenseService;

    public function __construct() {
        $this->licenseService = new LicenseService();
    }

    /**
     * POST /api/license/create
     * Endpoint for creating a new customer license key.
     */
    public function create(array $params, array $userContext): void {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        $customerName = $data['customer_name'] ?? '';
        $expiryDate = $data['expiry_date'] ?? '';

        if (empty($customerName) || empty($expiryDate)) {
            Response::badRequest("Missing required fields: customer_name and expiry_date.");
        }

        $result = $this->licenseService->createLicense($customerName, $expiryDate);

        if (!$result['success']) {
            Response::error($result['message'] ?? "Failed to create license.", 400);
        }

        header("Content-Type: application/json; charset=UTF-8");
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "license_key" => $result['license_key']
        ], JSON_PRETTY_PRINT);
        exit();
    }

    /**
     * POST /api/license/verify
     * Endpoint for verifying if a license key is valid and active.
     */
    public function verify(array $params, array $userContext): void {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];

        $licenseKey = $data['license_key'] ?? '';

        $result = $this->licenseService->verifyLicense($licenseKey);

        header("Content-Type: application/json; charset=UTF-8");
        http_response_code(200);
        echo json_encode($result, JSON_PRETTY_PRINT);
        exit();
    }
}
