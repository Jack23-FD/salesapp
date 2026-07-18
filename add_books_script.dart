import 'dart:math';
import 'package:mysql1/mysql1.dart';
import 'package:uuid/uuid.dart';

void main() async {
  final settings = ConnectionSettings(
    host: '127.0.0.1',
    port: 3306,
    user: 'root',
    password: 'Jack@123',
    db: 'kiosk',
  );

  print('Connecting to database...');
  final conn = await MySqlConnection.connect(settings);
  print('Connected!');

  final uuid = Uuid();
  
  // 1. Check if "stationary" category exists, or create it.
  var catResults = await conn.query('SELECT id FROM categories WHERE name = "Stationary"');
  String categoryId;
  
  if (catResults.isEmpty) {
    categoryId = uuid.v4();
    print('Creating category "Stationary" with ID: $categoryId');
    await conn.query(
      'INSERT INTO categories (id, name, description) VALUES ("$categoryId", "Stationary", "Stationary items like books")'
    );
  } else {
    categoryId = catResults.first['id'].toString();
    print('Found existing "Stationary" category with ID: $categoryId');
  }

  // 2. Add 10 books
  final random = Random();
  
  for (int i = 1; i <= 10; i++) {
    final bookId = uuid.v4();
    final bookName = 'Book $i';
    // Generate a random 12-digit barcode
    String barcode = '';
    for (int j = 0; j < 12; j++) {
      barcode += random.nextInt(10).toString();
    }
    
    final price = 100.00;
    final quantity = 10; // Stock quantity 10
    
    print('Inserting $bookName (Barcode: $barcode)...');
    
    var exist = await conn.query('SELECT id FROM products WHERE barcode = "$barcode"');
    if(exist.isEmpty){
        await conn.query(
          'INSERT INTO products (id, productname, category, barcode, price, quantity) VALUES ("$bookId", "$bookName", "$categoryId", "$barcode", $price, $quantity)'
        );
    }
  }

  print('Successfully added 10 books to Stationary category!');
  await conn.close();
}
