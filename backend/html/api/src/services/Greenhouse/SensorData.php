<?php

namespace App\Services\Greenhouse;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class SensorData {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        
        if (!isset($data['topic']) || !isset($data['data'])) {
            $response->getBody()->write(json_encode(['error' => 'Invalid payload']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $topic = $data['topic'];
        $timestamp = $data['timestamp'] ?? date('Y-m-d H:i:s');
        $readings = $data['data'];

        $db = new Database();
        $conn = $db->connect();

        try {
            $conn->beginTransaction();
            $stmt = $conn->prepare("INSERT INTO sensor_readings (timestamp, topic, value_key, value) VALUES (:timestamp, :topic, :key, :value)");

            foreach ($readings as $key => $value) {
                if ($key === 'rssi') continue; // Skip RSSI if needed, or keep it
                if (is_numeric($value)) {
                    $stmt->execute([
                        ':timestamp' => $timestamp,
                        ':topic' => $topic,
                        ':key' => $key,
                        ':value' => $value
                    ]);
                }
            }
            $conn->commit();
            $response->getBody()->write(json_encode(['status' => 'success']));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $conn->rollBack();
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
