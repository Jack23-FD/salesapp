# Transaction Management Reference

## Database Schema

The inventory system uses a transaction-based approach to track all inventory movements. Each inventory change is recorded in either the `inbound_transactions` or `outbound_transactions` tables.

### Core Tables

#### categories
```sql
CREATE TABLE categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT
);
```

#### products
```sql
CREATE TABLE products (
  id VARCHAR(50) PRIMARY KEY,
  productname VARCHAR(100) NOT NULL,
  category VARCHAR(50) NOT NULL,
  barcode VARCHAR(100),
  price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  FOREIGN KEY (category) REFERENCES categories(id)
);
```

#### inbound_transactions
```sql
CREATE TABLE inbound_transactions (
  id VARCHAR(50) PRIMARY KEY,
  item_id VARCHAR(50) NOT NULL,
  quantity INT NOT NULL,
  transaction_date DATETIME NOT NULL,
  FOREIGN KEY (item_id) REFERENCES products(id) ON DELETE CASCADE
);
```

#### outbound_transactions
```sql
CREATE TABLE outbound_transactions (
  id VARCHAR(50) PRIMARY KEY,
  item_id VARCHAR(50) NOT NULL,
  quantity INT NOT NULL,
  transaction_date DATETIME NOT NULL,
  FOREIGN KEY (item_id) REFERENCES products(id) ON DELETE CASCADE
);
```

## Sample Data

### categories
| id     | name            | description                    |
|--------|-----------------|--------------------------------|
| CAT001 | Electronics     | Electronic devices and components |
| CAT002 | Office Supplies | Office and stationery items    |
| CAT003 | Furniture       | Office furniture and fixtures  |

### products
| id      | productname   | category | barcode         | price   | quantity |
|---------|---------------|----------|-----------------|---------|----------|
| PROD001 | Laptop        | CAT001   | 1234567890123   | 1200.00 | 10       |
| PROD002 | Office Chair  | CAT003   | 2345678901234   | 150.00  | 25       |
| PROD003 | Printer Paper | CAT002   | 3456789012345   | 5.99    | 100      |

### inbound_transactions
| id       | item_id  | quantity | transaction_date      |
|----------|----------|----------|----------------------|
| INB00001 | PROD001  | 10       | 2023-07-15 09:30:00  |
| INB00002 | PROD002  | 25       | 2023-07-15 10:45:00  |
| INB00003 | PROD003  | 100      | 2023-07-16 14:20:00  |

### outbound_transactions
| id       | item_id  | quantity | transaction_date      |
|----------|----------|----------|----------------------|
| OUT00001 | PROD001  | 2        | 2023-07-16 11:30:00  |
| OUT00002 | PROD002  | 5        | 2023-07-17 09:15:00  |
| OUT00003 | PROD003  | 20       | 2023-07-17 16:45:00  |

## Transaction Operations

### Adding Inventory (Inbound)

When adding new inventory:
1. Create or update a product record in the `products` table
2. Record an inbound transaction in the `inbound_transactions` table

```sql
-- Example: Adding 5 new laptops
-- First update product quantity
UPDATE products 
SET quantity = quantity + 5 
WHERE id = 'PROD001';

-- Then record the transaction
INSERT INTO inbound_transactions 
(id, item_id, quantity, transaction_date) 
VALUES 
('INB00004', 'PROD001', 5, NOW());
```

### Removing Inventory (Outbound)

When removing inventory:
1. Update the product quantity in the `products` table
2. Record an outbound transaction in the `outbound_transactions` table

```sql
-- Example: Removing 3 office chairs
-- First verify sufficient quantity
SELECT quantity FROM products WHERE id = 'PROD002';

-- Then update product quantity
UPDATE products 
SET quantity = quantity - 3 
WHERE id = 'PROD002' AND quantity >= 3;

-- Finally record the transaction
INSERT INTO outbound_transactions 
(id, item_id, quantity, transaction_date) 
VALUES 
('OUT00004', 'PROD002', 3, NOW());
```

## Dashboard Queries

The following queries are used to generate dashboard statistics:

### Inbound Statistics

```sql
-- Get total inbound quantity for a date
SELECT SUM(quantity) as total 
FROM inbound_transactions 
WHERE DATE(transaction_date) = '2023-07-15';

-- Get unique categories with inbound transactions on a date
SELECT COUNT(DISTINCT p.category) as count 
FROM inbound_transactions t
JOIN products p ON t.item_id = p.id
WHERE DATE(t.transaction_date) = '2023-07-15';

-- Get total inbound value for a date
SELECT SUM(t.quantity * p.price) as total_value
FROM inbound_transactions t
JOIN products p ON t.item_id = p.id
WHERE DATE(t.transaction_date) = '2023-07-15';
```

### Outbound Statistics

```sql
-- Get total outbound quantity for a date
SELECT SUM(quantity) as total 
FROM outbound_transactions 
WHERE DATE(transaction_date) = '2023-07-16';

-- Get unique categories with outbound transactions on a date
SELECT COUNT(DISTINCT p.category) as count 
FROM outbound_transactions t
JOIN products p ON t.item_id = p.id
WHERE DATE(t.transaction_date) = '2023-07-16';

-- Get total outbound value for a date
SELECT SUM(t.quantity * p.price) as total_value
FROM outbound_transactions t
JOIN products p ON t.item_id = p.id
WHERE DATE(t.transaction_date) = '2023-07-16';
```

## Transaction History and Reports

### Transaction Timeline

```sql
-- Get comprehensive transaction timeline
SELECT 
  'Inbound' as type,
  t.id,
  p.productname,
  c.name as category,
  t.quantity,
  t.transaction_date,
  (p.price * t.quantity) as value
FROM inbound_transactions t
JOIN products p ON t.item_id = p.id
JOIN categories c ON p.category = c.id

UNION ALL

SELECT 
  'Outbound' as type,
  t.id,
  p.productname,
  c.name as category,
  t.quantity,
  t.transaction_date,
  (p.price * t.quantity) as value
FROM outbound_transactions t
JOIN products p ON t.item_id = p.id
JOIN categories c ON p.category = c.id

ORDER BY transaction_date DESC;
```

### Inventory Valuation

```sql
-- Get current inventory valuation by category
SELECT 
  c.name as category,
  SUM(p.quantity) as total_items,
  SUM(p.quantity * p.price) as total_value
FROM products p
JOIN categories c ON p.category = c.id
GROUP BY c.name
ORDER BY total_value DESC;
```

### Stock Movement Analysis

```sql
-- Get net movement of stock for each product
SELECT 
  p.id,
  p.productname,
  c.name as category,
  COALESCE(i.total_in, 0) as total_in,
  COALESCE(o.total_out, 0) as total_out,
  (COALESCE(i.total_in, 0) - COALESCE(o.total_out, 0)) as net_movement,
  p.quantity as current_stock
FROM products p
JOIN categories c ON p.category = c.id
LEFT JOIN (
  SELECT item_id, SUM(quantity) as total_in 
  FROM inbound_transactions 
  GROUP BY item_id
) i ON p.id = i.item_id
LEFT JOIN (
  SELECT item_id, SUM(quantity) as total_out 
  FROM outbound_transactions 
  GROUP BY item_id
) o ON p.id = o.item_id
ORDER BY net_movement DESC;
```

## Error Handling and Data Integrity

### Transaction Validation

Before recording transactions, validate:
1. Product exists
2. Sufficient quantity (for outbound)
3. Valid transaction date
4. Positive quantity values

### Transaction Atomicity

Ensure database operations maintain ACID properties:
1. Atomic: All operations succeed or none do
2. Consistent: Database remains in a valid state
3. Isolated: Concurrent transactions don't interfere
4. Durable: Completed transactions are permanently stored

Example using transactions:

```sql
START TRANSACTION;

-- Update product quantity
UPDATE products 
SET quantity = quantity - 5 
WHERE id = 'PROD003' AND quantity >= 5;

-- Record the transaction
INSERT INTO outbound_transactions 
(id, item_id, quantity, transaction_date) 
VALUES 
('OUT00005', 'PROD003', 5, NOW());

-- Check if both operations succeeded
IF (ROW_COUNT() > 0) THEN
  COMMIT;
ELSE
  ROLLBACK;
END IF;
```

## Maintenance and Troubleshooting

### Database Maintenance

```sql
-- Check and repair tables if needed
CHECK TABLE inbound_transactions, outbound_transactions;
REPAIR TABLE inbound_transactions, outbound_transactions;

-- Optimize tables for performance
OPTIMIZE TABLE inbound_transactions, outbound_transactions;

-- Create indexes for faster queries
CREATE INDEX idx_inbound_date ON inbound_transactions(transaction_date);
CREATE INDEX idx_outbound_date ON outbound_transactions(transaction_date);
```

### Common Issues and Resolutions

1. **Missing Transaction Records**:
   - Check if the transaction recording function is being called
   - Verify transaction dates are in correct format
   - Ensure database connection is working properly

2. **Zero Statistics in Dashboard**:
   - Verify transactions exist for the selected date
   - Check date formatting in queries
   - Execute dashboard queries directly against database to confirm results

3. **Transaction-Product Mismatch**:
   - Regenerate transaction data from existing products
   - Use the reference integrity checking script below

```sql
-- Find orphaned transactions (referencing non-existent products)
SELECT t.* FROM inbound_transactions t
LEFT JOIN products p ON t.item_id = p.id
WHERE p.id IS NULL;

-- Find products with no transactions
SELECT p.* FROM products p
LEFT JOIN (
  SELECT item_id FROM inbound_transactions 
  UNION 
  SELECT item_id FROM outbound_transactions
) t ON p.id = t.item_id
WHERE t.item_id IS NULL;
```

4. **Restoring Consistency**:
   - To restore consistency, you can regenerate transaction data from existing products 