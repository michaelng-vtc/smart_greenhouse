<?php

namespace App\Services\Greenhouse;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Config {
    public function getSoil(Request $request, Response $response) {
        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("SELECT value FROM config_settings WHERE `key` = 'soil_calib'");
            $stmt->execute();
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            $config = [];
            if ($row) {
                $config = json_decode($row['value'], true);
            } else {
                // Init default soil calibration
                $config = ["dry_adc" => 3000, "wet_adc" => 1200];
                $stmt = $conn->prepare("INSERT INTO config_settings (`key`, value) VALUES ('soil_calib', :value)");
                $stmt->execute([':value' => json_encode($config)]);
            }

            $response->getBody()->write(json_encode($config));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    public function setSoil(Request $request, Response $response) {
        $data = $request->getParsedBody();
        if (!isset($data['dry_adc']) || !isset($data['wet_adc'])) {
             $response->getBody()->write(json_encode(['error' => 'Invalid payload']));
             return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        if ($data['dry_adc'] <= $data['wet_adc']) {
             $response->getBody()->write(json_encode(['error' => 'Dry ADC must be greater than Wet ADC']));
             return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $db = new Database();
        $conn = $db->connect();
        try {
            $stmt = $conn->prepare("INSERT INTO config_settings (`key`, value) VALUES ('soil_calib', :value) ON DUPLICATE KEY UPDATE value = :value");
            $stmt->execute([':value' => json_encode($data)]);
            
            $response->getBody()->write(json_encode(["status" => "success", "message" => "Calibration saved"]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
