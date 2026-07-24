<?php

namespace App\Utils;

/**
 * License Generator Utility
 * Generates secure, random license keys formatted like KIOSK-A82F91CD.
 */
class LicenseGenerator {
    /**
     * Generate a random license key.
     *
     * @param string $prefix Prefix for the license key (default: 'KIOSK')
     * @param int $length Number of random hexadecimal characters (default: 8)
     * @return string
     */
    public static function generate(string $prefix = 'KIOSK', int $length = 8): string {
        $bytes = random_bytes((int) ceil($length / 2));
        $hex = strtoupper(substr(bin2hex($bytes), 0, $length));
        return "{$prefix}-{$hex}";
    }
}
