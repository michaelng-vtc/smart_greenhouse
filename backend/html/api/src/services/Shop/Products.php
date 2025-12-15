<?php

namespace App\Services\Shop;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Products {
    public function getAll(Request $request, Response $response) {
        $sql = "SELECT * FROM products";
        
        try {
            $db = new Database();
            $conn = $db->connect();

            // Check if table exists, if not create it (Auto-migration for demo)
            $conn->exec("CREATE TABLE IF NOT EXISTS products (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2) NOT NULL,
                image_url VARCHAR(255),
                stock INT DEFAULT 0
            )");

            // Check if table is empty, seed it
            $check = $conn->query("SELECT COUNT(*) FROM products")->fetchColumn();
            if ($check == 0) {
                $conn->exec("INSERT INTO products (name, description, price, image_url, stock) VALUES
                    ('Tomato Seeds', 'Organic heirloom tomato seeds.', 2.99, 'assets/images/tomato_seeds.png', 100),
                    ('Basil Seeds', 'Fresh sweet basil seeds.', 1.99, 'assets/images/basil_seeds.png', 150),
                    ('Lettuce Seeds', 'Crisp romaine lettuce seeds.', 2.49, 'assets/images/lettuce_seeds.png', 120),
                    ('Pepper Seeds', 'Spicy jalapeño pepper seeds.', 3.49, 'assets/images/pepper_seeds.png', 80),
                    ('Cucumber Seeds', 'Crunchy garden cucumber seeds.', 2.99, 'assets/images/cucumber_seeds.png', 90),
                    ('Strawberry Seeds', 'Sweet wild strawberry seeds.', 4.99, 'assets/images/strawberry_seeds.png', 60)
                ");
            }

            $stmt = $conn->query($sql);
            $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Convert numeric strings to numbers if needed
            foreach ($products as &$product) {
                $product['price'] = (float)$product['price'];
                $product['stock'] = (int)$product['stock'];
            }

            $json = json_encode($products);
            if ($json === false) {
                throw new \Exception("JSON encoding failed: " . json_last_error_msg());
            }

            $response->getBody()->write($json);
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);
        } catch (\Throwable $e) {
            $error = ["error" => $e->getMessage()];
            // Ensure we don't write false if this json_encode fails too
            $jsonError = json_encode($error);
            if ($jsonError) {
                $response->getBody()->write($jsonError);
            } else {
                $response->getBody()->write('{"error":"Unknown error"}');
            }
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }
}
