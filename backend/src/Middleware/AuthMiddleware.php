<?php

namespace App\Middleware;

use App\Config\Database;
use App\Config\Firebase;
use App\Utils\Response;
use PDO;

class AuthMiddleware {
    public static function authenticate(): array {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

        if (!$authHeader || !preg_match('/Bearer\s(\S+)/i', $authHeader, $matches)) {
            Response::unauthorized("Access Denied: Missing or invalid Authorization header format.");
        }

        $token = $matches[1];
        $firebaseUser = Firebase::verifyIdToken($token);

        if (!$firebaseUser) {
            Response::unauthorized("Access Denied: Invalid or expired Firebase ID token.");
        }

        // Query our local database to fetch company ID, status, and role
        $db = Database::getInstance()->getConnection();
        $stmt = $db->prepare("
            SELECT u.id, u.company_id, u.name, u.email, u.role, u.status, c.status as company_status 
            FROM users u
            JOIN companies c ON u.company_id = c.id
            WHERE u.id = :id AND u.deleted_at IS NULL
            LIMIT 1
        ");
        
        $stmt->execute(['id' => $firebaseUser['uid']]);
        $user = $stmt->fetch();

        // If user doesn't exist in local database, but token is valid, they are allowed to proceed to signup/registration routes only
        if (!$user) {
            $requestUri = $_SERVER['REQUEST_URI'] ?? '';
            if (strpos($requestUri, 'api/v1/auth/register') !== false) {
                // We return just the Firebase token details so they can register
                return [
                    "uid" => $firebaseUser['uid'],
                    "email" => $firebaseUser['email'],
                    "name" => $firebaseUser['name'],
                    "is_registered" => false
                ];
            }
            
            Response::unauthorized("Access Denied: Firebase user is not registered in the database. Please complete registration first.");
        }

        if ($user['status'] !== 'active') {
            Response::forbidden("Access Denied: User account is inactive.");
        }

        if ($user['company_status'] !== 'active') {
            Response::forbidden("Access Denied: Company account is suspended.");
        }

        return [
            "uid" => $user['id'],
            "company_id" => $user['company_id'],
            "name" => $user['name'],
            "email" => $user['email'],
            "role" => $user['role'],
            "is_registered" => true
        ];
    }
}
