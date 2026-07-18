<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;
use App\Utils\Response;
use App\Utils\Router;
use App\Middleware\AuthMiddleware;

// CORS headers configuration
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Load environment variables (.env)
if (file_exists(__DIR__ . '/../.env')) {
    try {
        $dotenv = Dotenv::createImmutable(__DIR__ . '/..');
        $dotenv->load();
    } catch (\Exception $e) {
        error_log("Failed to load environment configuration: " . $e->getMessage());
    }
}

// Middleware closures
$authenticate = function($context) {
    return AuthMiddleware::authenticate();
};

// Health Check Route
Router::get('api/v1/health', function() {
    Response::success("Kiosk API Service is healthy and running.", [
        "app" => "Kiosk",
        "environment" => $_ENV['APP_ENV'] ?? 'production',
        "php_version" => PHP_VERSION,
        "database" => $_ENV['DB_DATABASE'] ?? 'u650540262_kioskdp'
    ]);
});

// Authentication & Staff Management Routes
Router::post('api/v1/auth/register', [\App\Controllers\AuthController::class, 'registerAdmin'], [$authenticate]);
Router::get('api/v1/users/profile', [\App\Controllers\AuthController::class, 'getProfile'], [$authenticate]);
Router::post('api/v1/users/staff', [\App\Controllers\AuthController::class, 'registerStaff'], [$authenticate]);
Router::get('api/v1/users/staff', [\App\Controllers\AuthController::class, 'listStaff'], [$authenticate]);

// Category Management Routes
Router::get('api/v1/categories', [\App\Controllers\CategoryController::class, 'index'], [$authenticate]);
Router::post('api/v1/categories', [\App\Controllers\CategoryController::class, 'create'], [$authenticate]);
Router::put('api/v1/categories/{id}', [\App\Controllers\CategoryController::class, 'update'], [$authenticate]);
Router::delete('api/v1/categories/{id}', [\App\Controllers\CategoryController::class, 'delete'], [$authenticate]);

// Product Management Routes
Router::get('api/v1/products', [\App\Controllers\ProductController::class, 'index'], [$authenticate]);
Router::post('api/v1/products', [\App\Controllers\ProductController::class, 'create'], [$authenticate]);
Router::put('api/v1/products/{id}', [\App\Controllers\ProductController::class, 'update'], [$authenticate]);
Router::delete('api/v1/products/{id}', [\App\Controllers\ProductController::class, 'delete'], [$authenticate]);

// Stock Transaction & Dashboard Stats Routes
Router::post('api/v1/transactions', [\App\Controllers\TransactionController::class, 'create'], [$authenticate]);
Router::get('api/v1/transactions/stats', [\App\Controllers\TransactionController::class, 'stats'], [$authenticate]);

// Dispatch the current request
Router::dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
