<?php

namespace App\Services\Greenhouse;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class FanLog {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        
        if (!isset($data['duty_cycle']) || !isset($data['status'])) {
            $response->getBody()->write(json_encode(['error' => 'Invalid payload']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $timestamp = $data['timestamp'] ?? date('Y-m-d H:i:s');
        $duty = $data['duty_cycle'];
        $status = $data['status'];

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("INSERT INTO fan_logs (timestamp, duty_cycle, status) VALUES (:timestamp, :duty, :status)");
            $stmt->execute([
                ':timestamp' => $timestamp,
                ':duty' => $duty,
                ':status' => $status
            ]);
            
            $response->getBody()->write(json_encode(['status' => 'success']));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
