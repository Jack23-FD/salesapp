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

// Register basic health-check route
Router::get('api/v1/health', function() {
    Response::success("Kiosk API Service is healthy and running.", [
        "app" => "Kiosk",
        "environment" => $_ENV['APP_ENV'] ?? 'production',
        "php_version" => PHP_VERSION,
        "database" => $_ENV['DB_DATABASE'] ?? 'u650540262_kioskdp'
    ]);
});

// Dispatch the current request
Router::dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
