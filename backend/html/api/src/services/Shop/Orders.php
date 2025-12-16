<?php

namespace App\Services\Shop;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Orders {
    // Create a new order
    public function create(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $userId = $data['user_id'] ?? null;
        $items = $data['items'] ?? null;
        $totalAmount = $data['total_amount'] ?? null;

        if (!$userId || !$items || !is_array($items) || empty($items)) {
            $response->getBody()->write(json_encode(['error' => 'User ID and items are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $conn->beginTransaction();

            // Insert order
            $stmt = $conn->prepare("INSERT INTO orders (user_id, total_amount, status, created_at) VALUES (:user_id, :total_amount, 'pending', NOW())");
            $stmt->bindParam(':user_id', $userId);
            $stmt->bindParam(':total_amount', $totalAmount);
            $stmt->execute();
            
            $orderId = $conn->lastInsertId();

            // Insert order items
            $itemStmt = $conn->prepare("INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (:order_id, :product_id, :quantity, :price)");
            
            foreach ($items as $item) {
                $itemStmt->bindParam(':order_id', $orderId);
                $itemStmt->bindParam(':product_id', $item['product_id']);
                $itemStmt->bindParam(':quantity', $item['quantity']);
                $itemStmt->bindParam(':price', $item['price']);
                $itemStmt->execute();
            }

            $conn->commit();

            $response->getBody()->write(json_encode([
                'message' => 'Order created successfully',
                'order_id' => $orderId
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $conn->rollBack();
            $response->getBody()->write(json_encode(['error' => 'Failed to create order: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    // Get user's orders
    public function getUserOrders(Request $request, Response $response, array $args) {
        $userId = $args['user_id'] ?? null;

        if (!$userId) {
            $response->getBody()->write(json_encode(['error' => 'User ID is required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            // Fetch orders and items in a flat list, then group in PHP
            // This avoids JSON_OBJECT compatibility issues with older MySQL versions
            $stmt = $conn->prepare("
                SELECT o.id as order_id, o.user_id, o.total_amount, o.status, o.created_at,
                       oi.product_id, oi.quantity, oi.price,
                       p.name as product_name
                FROM orders o
                LEFT JOIN order_items oi ON o.id = oi.order_id
                LEFT JOIN products p ON oi.product_id = p.id
                WHERE o.user_id = :user_id
                ORDER BY o.created_at DESC
            ");
            $stmt->bindParam(':user_id', $userId);
            $stmt->execute();

            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $ordersMap = [];

            foreach ($rows as $row) {
                $orderId = $row['order_id'];
                
                if (!isset($ordersMap[$orderId])) {
                    $ordersMap[$orderId] = [
                        'id' => $orderId,
                        'user_id' => $row['user_id'],
                        'total_amount' => $row['total_amount'],
                        'status' => $row['status'],
                        'created_at' => $row['created_at'],
                        'items' => []
                    ];
                }

                if ($row['product_id']) {
                    $ordersMap[$orderId]['items'][] = [
                        'product_id' => $row['product_id'],
                        'product_name' => $row['product_name'],
                        'quantity' => $row['quantity'],
                        'price' => $row['price']
                    ];
                }
            }

            // Convert map to indexed array
            $orders = array_values($ordersMap);

            $response->getBody()->write(json_encode($orders));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to fetch orders: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
