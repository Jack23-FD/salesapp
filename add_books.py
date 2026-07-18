import pymysql
import uuid
import random

def main():
    print("Connecting to database...")
    try:
        conn = pymysql.connect(
            host='127.0.0.1',
            user='root',
            password='Jack@123',
            database='kiosk',
            port=3306,
            autocommit=True
        )
        print("Connected!")
    except Exception as e:
        print(f"Failed to connect: {e}")
        return

    cursor = conn.cursor()

    print("Creating tables if they don't exist...")
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS categories (
          id VARCHAR(50) PRIMARY KEY,
          name VARCHAR(100) NOT NULL,
          description TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS products (
          id VARCHAR(50) PRIMARY KEY,
          productname VARCHAR(100) NOT NULL,
          category VARCHAR(50) NOT NULL,
          barcode VARCHAR(100),
          price DECIMAL(10,2) NOT NULL,
          quantity INT NOT NULL DEFAULT 1
        )
    """)

    # 1. Category Stationary
    cursor.execute("SELECT id FROM categories WHERE name = %s", ('Stationary',))
    cat = cursor.fetchone()
    
    if not cat:
        category_id = str(uuid.uuid4())
        print(f"Creating category 'Stationary' with ID {category_id}")
        cursor.execute(
            "INSERT INTO categories (id, name, description) VALUES (%s, %s, %s)",
            (category_id, 'Stationary', 'Stationary items like books')
        )
    else:
        category_id = cat[0]
        print(f"Found category 'Stationary' with ID {category_id}")

    # 2. Add 10 books
    for i in range(1, 11):
        book_id = str(uuid.uuid4())
        book_name = f"Book {i}"
        barcode = ''.join([str(random.randint(0, 9)) for _ in range(12)])
        price = 100.00
        quantity = 10 # 10 items

        # check if barcode exists
        cursor.execute("SELECT id FROM products WHERE barcode = %s", (barcode,))
        if not cursor.fetchone():
            print(f"Inserting {book_name} (Barcode: {barcode})...")
            cursor.execute(
                "INSERT INTO products (id, productname, category, barcode, price, quantity) VALUES (%s, %s, %s, %s, %s, %s)",
                (book_id, book_name, category_id, barcode, price, quantity)
            )

    print("Successfully added 10 books to Stationary category!")
    conn.close()

if __name__ == '__main__':
    main()
