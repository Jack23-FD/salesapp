-- MySQL 8.0+ Production Database Schema for SalesApp Enterprise Backend
-- Database: u650540262_kioskdp

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `companies`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Tenants (Companies) Table
CREATE TABLE `companies` (
    `id` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_companies_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Users Table (Aligned with Firebase Authentication UID)
CREATE TABLE `users` (
    `id` VARCHAR(50) NOT NULL, -- Firebase UID
    `company_id` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `phone_number` VARCHAR(30) NULL,
    `role` ENUM('admin', 'staff') NOT NULL DEFAULT 'staff',
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_users_email` (`email`),
    CONSTRAINT `fk_users_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    INDEX `idx_users_tenant` (`company_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Product Categories Table
CREATE TABLE `categories` (
    `id` VARCHAR(50) NOT NULL,
    `company_id` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `icon_code_point` INT NULL,
    `icon_font_family` VARCHAR(50) NULL,
    `icon_font_package` VARCHAR(50) NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_by` VARCHAR(50) NULL,
    `updated_by` VARCHAR(50) NULL,
    `deleted_by` VARCHAR(50) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_categories_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_categories_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_categories_updater` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_categories_deleter` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    INDEX `idx_categories_tenant` (`company_id`, `status`, `deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Products (Items) Table
CREATE TABLE `products` (
    `id` VARCHAR(50) NOT NULL,
    `company_id` VARCHAR(50) NOT NULL,
    `category_id` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `unit` VARCHAR(20) NOT NULL DEFAULT 'pcs',
    `price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `barcode` VARCHAR(100) NULL,
    `min_level` DECIMAL(12, 2) NULL,
    `image_url` TEXT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_by` VARCHAR(50) NULL,
    `updated_by` VARCHAR(50) NULL,
    `deleted_by` VARCHAR(50) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_products_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_products_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_products_updater` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_products_deleter` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    INDEX `idx_products_tenant` (`company_id`, `status`, `deleted_at`),
    INDEX `idx_products_barcode` (`barcode`),
    INDEX `idx_products_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Stock Transactions Table
CREATE TABLE `transactions` (
    `id` VARCHAR(50) NOT NULL,
    `company_id` VARCHAR(50) NOT NULL,
    `product_id` VARCHAR(50) NOT NULL,
    `quantity` INT NOT NULL,
    `type` ENUM('inbound', 'outbound') NOT NULL,
    `date` DATETIME NOT NULL,
    `created_by` VARCHAR(50) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_transactions_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_transactions_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_transactions_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    INDEX `idx_transactions_query` (`company_id`, `date`, `type`),
    INDEX `idx_transactions_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Audit Logs Table
CREATE TABLE `audit_logs` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `company_id` VARCHAR(50) NOT NULL,
    `user_id` VARCHAR(50) NULL,
    `action` VARCHAR(50) NOT NULL,
    `table_name` VARCHAR(50) NOT NULL,
    `record_id` VARCHAR(50) NOT NULL,
    `old_values` JSON NULL,
    `new_values` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_audit_logs_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_audit_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    INDEX `idx_audit_logs_tenant` (`company_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
