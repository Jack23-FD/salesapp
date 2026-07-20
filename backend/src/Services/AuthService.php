<?php

namespace App\Services;

use App\Repositories\CompanyRepository;
use App\Repositories\UserRepository;
use App\Config\TransactionManager;
use App\Utils\Response;
use Exception;

class AuthService {
    private CompanyRepository $companyRepo;
    private UserRepository $userRepo;
    private TransactionManager $txManager;

    public function __construct() {
        $this->companyRepo = new CompanyRepository();
        $this->userRepo = new UserRepository();
        $this->txManager = new TransactionManager();
    }

    /**
     * Register a new user (admin or staff)
     */
    public function registerUser(array $data): array {
        // Validate input data
        if (empty($data['uid']) || empty($data['name']) || empty($data['email']) || empty($data['companyName'])) {
            Response::badRequest("Missing required registration fields.");
        }

        $role = $data['role'] ?? 'admin';
        if ($role !== 'admin' && $role !== 'staff') {
            Response::badRequest("Invalid registration role.");
        }

        try {
            if ($role === 'staff') {
                // Look up company by name
                $company = $this->companyRepo->findByName($data['companyName']);
                if (!$company) {
                    Response::badRequest("Company '{$data['companyName']}' does not exist. Please contact your administrator.");
                }
                
                $companyId = $company['id'];
                
                // Create user record with staff role
                $this->userRepo->create([
                    'id' => $data['uid'],
                    'company_id' => $companyId,
                    'name' => $data['name'],
                    'email' => $data['email'],
                    'phone_number' => $data['phoneNumber'] ?? null,
                    'role' => 'staff',
                    'status' => 'active'
                ]);

                return [
                    'uid' => $data['uid'],
                    'company_id' => $companyId,
                    'role' => 'staff'
                ];
            } else {
                $companyId = bin2hex(random_bytes(16)); // Generate secure company UUID
                
                return $this->txManager->transaction(function() use ($companyId, $data) {
                    // 1. Create company record
                    $this->companyRepo->create([
                        'id' => $companyId,
                        'name' => $data['companyName'],
                        'status' => 'active'
                    ]);

                    // 2. Create user record with admin role
                    $this->userRepo->create([
                        'id' => $data['uid'],
                        'company_id' => $companyId,
                        'name' => $data['name'],
                        'email' => $data['email'],
                        'phone_number' => $data['phoneNumber'] ?? null,
                        'role' => 'admin',
                        'status' => 'active'
                    ]);

                    return [
                        'uid' => $data['uid'],
                        'company_id' => $companyId,
                        'role' => 'admin'
                    ];
                });
            }
        } catch (Exception $e) {
            error_log("Failed to register user: " . $e->getMessage());
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Fetch user profile details
     */
    public function getProfile(string $uid): array {
        $user = $this->userRepo->findUserById($uid);
        if (!$user) {
            Response::notFound("User profile not found.");
        }
        return $user;
    }

    /**
     * Invite and register a new staff member (Admin Only)
     */
    public function registerStaff(array $adminUser, array $data): array {
        if (empty($data['uid']) || empty($data['name']) || empty($data['email'])) {
            Response::badRequest("Missing required staff registration fields.");
        }

        try {
            $this->userRepo->create([
                'id' => $data['uid'],
                'company_id' => $adminUser['company_id'],
                'name' => $data['name'],
                'email' => $data['email'],
                'phone_number' => $data['phoneNumber'] ?? null,
                'role' => 'staff',
                'status' => 'active'
            ]);

            return [
                'uid' => $data['uid'],
                'company_id' => $adminUser['company_id'],
                'role' => 'staff'
            ];
        } catch (Exception $e) {
            error_log("Failed to register staff user: " . $e->getMessage());
            Response::error("Failed to add staff member.", 500);
        }
    }

    /**
     * List all staff members
     */
    public function listStaff(string $companyId): array {
        return $this->userRepo->listStaffByCompany($companyId);
    }
}
