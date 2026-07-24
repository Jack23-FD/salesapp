<?php

namespace App\Services;

use App\Repositories\LicenseRepository;
use App\Utils\LicenseGenerator;
use Exception;

/**
 * License Service
 * Implements core business logic for creating and verifying licenses.
 */
class LicenseService {
    private LicenseRepository $licenseRepo;

    public function __construct() {
        $this->licenseRepo = new LicenseRepository();
    }

    /**
     * Create a new license key and save it to database.
     */
    public function createLicense(string $customerName, string $expiryDate): array {
        if (empty($customerName) || empty($expiryDate)) {
            return [
                'success' => false,
                'message' => 'customer_name and expiry_date are required'
            ];
        }

        // Generate a random key formatted like KIOSK-A82F91CD
        $licenseKey = LicenseGenerator::generate();

        try {
            $this->licenseRepo->create([
                'license_key' => $licenseKey,
                'customer_name' => $customerName,
                'expiry_date' => $expiryDate,
                'status' => 'active'
            ]);

            return [
                'success' => true,
                'license_key' => $licenseKey
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to create license: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Verify an existing license key against existence, active status, and expiry date.
     */
    public function verifyLicense(string $licenseKey): array {
        if (empty($licenseKey)) {
            return [
                'valid' => false,
                'message' => 'License expired or invalid'
            ];
        }

        try {
            $license = $this->licenseRepo->findByKey($licenseKey);

            // 1. Check if license exists in database
            if (!$license) {
                return [
                    'valid' => false,
                    'message' => 'License expired or invalid'
                ];
            }

            // 2. Check if status is active
            if ($license['status'] !== 'active') {
                return [
                    'valid' => false,
                    'message' => 'License expired or invalid'
                ];
            }

            // 3. Check if current date has not passed expiry date
            $today = date('Y-m-d');
            if ($license['expiry_date'] < $today) {
                return [
                    'valid' => false,
                    'message' => 'License expired or invalid'
                ];
            }

            return [
                'valid' => true,
                'message' => 'License is active'
            ];
        } catch (Exception $e) {
            return [
                'valid' => false,
                'message' => 'License expired or invalid'
            ];
        }
    }
}
