<?php

namespace App\Services\Greenhouse;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class CurtainLog {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        
        if (!isset($data['status'])) {
            $response->getBody()->write(json_encode(['error' => 'Invalid payload']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $timestamp = $data['timestamp'] ?? date('Y-m-d H:i:s');
        $status = $data['status'];
        $lux = $data['lux'] ?? null;

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("INSERT INTO curtain_logs (timestamp, status, lux) VALUES (:timestamp, :status, :lux)");
            $stmt->execute([
                ':timestamp' => $timestamp,
                ':status' => $status,
                ':lux' => $lux
            ]);
            
            $response->getBody()->write(json_encode(['status' => 'success']));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
