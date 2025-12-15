<?php

namespace App\Services\Greenhouse;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class GetSystemStatus {
    private $db;
    private $conn;

    public function __construct() {
        $this->db = new Database();
        $this->conn = $this->db->connect();
    }

    private function getLatestLog($table) {
        try {
            $stmt = $this->conn->prepare("SELECT * FROM $table ORDER BY timestamp DESC LIMIT 1");
            $stmt->execute();
            $data = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$data) {
                return ['status' => 'OFF', 'timestamp' => null];
            }
            return $data;
        } catch (\Exception $e) {
            return ['error' => $e->getMessage()];
        }
    }

    public function getFan(Request $request, Response $response) {
        $data = $this->getLatestLog('fan_logs');
        $response->getBody()->write(json_encode($data));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function getCurtain(Request $request, Response $response) {
        $data = $this->getLatestLog('curtain_logs');
        $response->getBody()->write(json_encode($data));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function getIrrigation(Request $request, Response $response) {
        $data = $this->getLatestLog('irrigation_logs');
        $response->getBody()->write(json_encode($data));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function getHeater(Request $request, Response $response) {
        $data = $this->getLatestLog('heater_logs');
        $response->getBody()->write(json_encode($data));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function getMister(Request $request, Response $response) {
        $data = $this->getLatestLog('mister_logs');
        $response->getBody()->write(json_encode($data));
        return $response->withHeader('Content-Type', 'application/json');
    }
}
