<?php

namespace App\Services\Shop;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Products {
    public function getAll(Request $request, Response $response) {
        $queryParams = $request->getQueryParams();
        $userId = $queryParams['user_id'] ?? null;

        $sql = "SELECT * FROM products";
        if ($userId) {
            $sql .= " WHERE user_id = :user_id";
        }
        
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
                stock INT DEFAULT 0,
                user_id INT DEFAULT NULL
            )");

            // Add user_id column if it doesn't exist (for existing tables)
            try {
                $conn->exec("ALTER TABLE products ADD COLUMN user_id INT DEFAULT NULL");
            } catch (\Exception $e) {
                // Column likely already exists, ignore
            }

            if ($userId) {
                $stmt = $conn->prepare($sql);
                $stmt->execute([':user_id' => $userId]);
            } else {
                $stmt = $conn->query($sql);
            }
            
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

    public function create(Request $request, Response $response) {
        $data = $request->getParsedBody();
        
        $name = $data['name'] ?? null;
        $description = $data['description'] ?? '';
        $price = $data['price'] ?? null;
        $imageUrl = $data['image_url'] ?? '';
        $stock = $data['stock'] ?? 0;
        $userId = $data['user_id'] ?? null;

        if (!$name || !$price) {
            $response->getBody()->write(json_encode(['error' => 'Name and price are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("INSERT INTO products (name, description, price, image_url, stock, user_id) VALUES (:name, :description, :price, :image_url, :stock, :user_id)");
            $stmt->execute([
                ':name' => $name,
                ':description' => $description,
                ':price' => $price,
                ':image_url' => $imageUrl,
                ':stock' => $stock,
                ':user_id' => $userId
            ]);

            $response->getBody()->write(json_encode(['message' => 'Product created successfully']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to create product: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    public function delete(Request $request, Response $response, $args) {
        $id = $args['id'];
        
        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("DELETE FROM products WHERE id = :id");
            $stmt->execute([':id' => $id]);

            if ($stmt->rowCount() > 0) {
                $response->getBody()->write(json_encode(['message' => 'Product deleted successfully']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
            } else {
                $response->getBody()->write(json_encode(['error' => 'Product not found']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to delete product: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
