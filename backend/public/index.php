<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;
use App\Utils\Response;

// Enable CORS and general API headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle CORS Preflight Requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Initialize Environment Variables
if (file_exists(__DIR__ . '/../.env')) {
    try {
        $dotenv = Dotenv::createImmutable(__DIR__ . '/..');
        $dotenv->load();
    } catch (\Exception $e) {
        error_log("Failed to load .env config: " . $e->getMessage());
    }
}

// Parse request URL
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$scriptName = dirname($_SERVER['SCRIPT_NAME']);
// Normalize routing path relative to public_html or subdirectory deployments
$route = str_replace($scriptName, '', $requestUri);
$route = trim($route, '/');

$parts = explode('/', $route);

// Validate API Version prefix (/api/v1/)
if (count($parts) < 3 || $parts[0] !== 'api' || $parts[1] !== 'v1') {
    Response::notFound("API Endpoint Not Found. Ensure path starts with /api/v1/");
}

$resource = $parts[2];
$id = $parts[3] ?? null;

// Basic Health Check Endpoint
if ($resource === 'health') {
    Response::success("SalesApp Backend API is running.", [
        "environment" => $_ENV['APP_ENV'] ?? 'development',
        "php_version" => PHP_VERSION,
        "database" => $_ENV['DB_DATABASE'] ?? 'unknown'
    ]);
}

Response::notFound("Resource endpoint '/api/v1/{$resource}' is not yet implemented.");
