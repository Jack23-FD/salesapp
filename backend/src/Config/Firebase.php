<?php

namespace App\Config;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Exception;

class Firebase {
    private static string $publicKeyUrl = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
    private static string $cacheFile = __DIR__ . '/../../config/public_keys_cache.json';

    public static function verifyIdToken(string $token): ?array {
        $projectId = $_ENV['FIREBASE_PROJECT_ID'] ?? '';
        if (empty($projectId)) {
            error_log("Firebase Configuration Error: FIREBASE_PROJECT_ID is empty in .env");
            return null;
        }

        try {
            $publicKeys = self::getGooglePublicKeys();
            
            // Decode and verify token
            $decoded = JWT::decode($token, $publicKeys);
            $payload = (array) $decoded;

            // Verify claims
            if ($payload['iss'] !== "https://securetoken.google.com/{$projectId}") {
                throw new Exception("Invalid Issuer claim");
            }
            if ($payload['aud'] !== $projectId) {
                throw new Exception("Invalid Audience claim");
            }
            if (empty($payload['sub'])) {
                throw new Exception("Subject (UID) claim is empty");
            }

            return [
                "uid" => $payload['sub'],
                "email" => $payload['email'] ?? '',
                "name" => $payload['name'] ?? ''
            ];
        } catch (Exception $e) {
            error_log("Firebase Token Verification Failed: " . $e->getMessage());
            return null;
        }
    }

    private static function getGooglePublicKeys(): array {
        $cacheDir = dirname(self::$cacheFile);
        if (!is_dir($cacheDir)) {
            mkdir($cacheDir, 0755, true);
        }

        // Load from cache if valid (cache for 6 hours)
        if (file_exists(self::$cacheFile) && (time() - filemtime(self::$cacheFile) < 21600)) {
            $cachedData = json_decode(file_get_contents(self::$cacheFile), true);
            if (!empty($cachedData)) {
                return self::convertToKeysArray($cachedData);
            }
        }

        // Fetch fresh keys from Google
        try {
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, self::$publicKeyUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            $response = curl_exec($ch);
            curl_close($ch);

            if ($response === false) {
                throw new Exception("Failed to contact Google API server");
            }

            $keysData = json_decode($response, true);
            if (empty($keysData)) {
                throw new Exception("Received empty keys from Google");
            }

            // Write to cache
            file_put_contents(self::$cacheFile, json_encode($keysData));
            
            return self::convertToKeysArray($keysData);
        } catch (Exception $e) {
            error_log("Failed to fetch Google Public Keys: " . $e->getMessage());
            // Fallback to stale cache if available
            if (file_exists(self::$cacheFile)) {
                $cachedData = json_decode(file_get_contents(self::$cacheFile), true);
                return self::convertToKeysArray($cachedData);
            }
            throw $e;
        }
    }

    private static function convertToKeysArray(array $keysData): array {
        $keys = [];
        foreach ($keysData as $kid => $cert) {
            $keys[$kid] = new Key($cert, 'RS256');
        }
        return $keys;
    }
}
