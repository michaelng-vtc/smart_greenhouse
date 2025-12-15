<?php

namespace App\Services\Greenhouse;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Profiles {
    public function getActive(Request $request, Response $response) {
        $db = new Database();
        $conn = $db->connect();

        try {
            // Get active profile name
            $stmt = $conn->prepare("SELECT value FROM config_settings WHERE `key` = 'active_profile_name'");
            $stmt->execute();
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $activeName = 'Default';
            if ($row) {
                $config = json_decode($row['value'], true);
                $activeName = $config['name'] ?? 'Default';
            } else {
                // Init default active profile if missing
                $stmt = $conn->prepare("INSERT INTO config_settings (`key`, value) VALUES ('active_profile_name', :value)");
                $stmt->execute([':value' => json_encode(['name' => 'Default'])]);
            }

            // Get profile setpoints
            $stmt = $conn->prepare("SELECT value FROM config_settings WHERE `key` = :key");
            $stmt->execute([':key' => "profile_" . $activeName]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            $setpoints = [];
            if ($row) {
                $profileData = json_decode($row['value'], true);
                $setpoints = $profileData['setpoints'] ?? [];
            } else {
                // Init default setpoints if missing
                $defaultSetpoints = [
                    "vpd_target_low" => 0.8,
                    "vpd_target_high" => 1.2,
                    "vpd_mister_threshold" => 1.0,
                    "temp_min_c" => 18.0,
                    "temp_max_c" => 30.0,
                    "co2_min_ppm" => 500,
                    "co2_low_ppm" => 600,
                    "co2_high_ppm" => 1500,
                    "light_max_lux" => 50000,
                    "soil_min_percent" => 30.0
                ];
                $setpoints = $defaultSetpoints;
                
                // Save to DB
                $stmt = $conn->prepare("INSERT INTO config_settings (`key`, value) VALUES (:key, :value)");
                $stmt->execute([
                    ':key' => "profile_" . $activeName,
                    ':value' => json_encode(['profile_name' => $activeName, 'setpoints' => $defaultSetpoints])
                ]);

                // Also init Strawberry profile while we are at it
                $strawberrySetpoints = [
                    "vpd_target_low" => 0.6,
                    "vpd_target_high" => 1.0,
                    "vpd_mister_threshold" => 1.1,
                    "temp_min_c" => 16.0,
                    "temp_max_c" => 24.0,
                    "co2_min_ppm" => 600,
                    "co2_low_ppm" => 700,
                    "co2_high_ppm" => 1000,
                    "light_max_lux" => 45000,
                    "soil_min_percent" => 40.0
                ];
                $stmt->execute([
                    ':key' => "profile_Strawberry",
                    ':value' => json_encode(['profile_name' => 'Strawberry', 'setpoints' => $strawberrySetpoints])
                ]);
            }

            $result = [
                'profile_name' => $activeName,
                'setpoints' => $setpoints
            ];

            $response->getBody()->write(json_encode($result));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    public function getAll(Request $request, Response $response) {
        $db = new Database();
        $conn = $db->connect();
        try {
            // Get active profile name
            $stmt = $conn->prepare("SELECT value FROM config_settings WHERE `key` = 'active_profile_name'");
            $stmt->execute();
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $activeName = 'Default';
            if ($row) {
                $config = json_decode($row['value'], true);
                $activeName = $config['name'] ?? 'Default';
            }

            // Get all profiles
            $stmt = $conn->prepare("SELECT `key`, value FROM config_settings WHERE `key` LIKE 'profile_%'");
            $stmt->execute();
            $profiles = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $result = ["active_profile" => $activeName, "profiles" => []];
            foreach ($profiles as $row) {
                $profileName = str_replace('profile_', '', $row['key']);
                $setpoints = json_decode($row['value'], true);
                $result["profiles"][$profileName] = $setpoints;
            }
            
            $response->getBody()->write(json_encode($result));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    public function save(Request $request, Response $response) {
        $data = $request->getParsedBody();
        if (empty($data['profile_name']) || empty($data['setpoints'])) {
             $response->getBody()->write(json_encode(['error' => 'Invalid payload']));
             return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $profileName = $data['profile_name'];
        $setpoints = $data['setpoints'];
        $dbKey = "profile_" . $profileName;

        $db = new Database();
        $conn = $db->connect();
        try {
            $stmt = $conn->prepare("INSERT INTO config_settings (`key`, value) VALUES (:key, :value) ON DUPLICATE KEY UPDATE value = :value");
            $stmt->execute([':key' => $dbKey, ':value' => json_encode($setpoints)]);
            
            $response->getBody()->write(json_encode(["status" => "success", "message" => "Profile saved"]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    public function activate(Request $request, Response $response, $args) {
        $profileName = $args['profile_name'];
        $dbKey = "profile_" . $profileName;
        
        $db = new Database();
        $conn = $db->connect();
        try {
            // Check if profile exists
            $stmt = $conn->prepare("SELECT 1 FROM config_settings WHERE `key` = :key");
            $stmt->execute([':key' => $dbKey]);
            if (!$stmt->fetch()) {
                $response->getBody()->write(json_encode(['error' => 'Profile not found']));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }

            // Set active profile
            $stmt = $conn->prepare("INSERT INTO config_settings (`key`, value) VALUES ('active_profile_name', :value) ON DUPLICATE KEY UPDATE value = :value");
            $stmt->execute([':value' => json_encode(['name' => $profileName])]);

            // Get new setpoints to return
            $stmt = $conn->prepare("SELECT value FROM config_settings WHERE `key` = :key");
            $stmt->execute([':key' => $dbKey]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $setpoints = json_decode($row['value'], true);

            $response->getBody()->write(json_encode([
                "status" => "success", 
                "message" => "Profile activated",
                "setpoints" => $setpoints
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
