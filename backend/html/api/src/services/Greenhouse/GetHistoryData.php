<?php
namespace App\Services\Greenhouse;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class GetHistoryData {
    public function __invoke(Request $request, Response $response, $args) {
        $valueKey = $args['value_key'];
        $params = $request->getQueryParams();
        $hours = isset($params['hours']) ? (int)$params['hours'] : 24;
        
        $db = new Database();
        $conn = $db->connect();
        try {
            $timeThreshold = date('Y-m-d H:i:s', strtotime("-{$hours} hours"));
            
            // Handle aliases
            $keys = [$valueKey];
            if (strtolower($valueKey) === 'humidity') {
                $keys[] = 'hum';
            }
            if (strtolower($valueKey) === 'soil_raw') {
                $keys[] = 'value';
            }
            
            // Create placeholders for IN clause
            $placeholders = implode(',', array_fill(0, count($keys), '?'));
            
            $sql = "SELECT timestamp, value FROM sensor_readings WHERE value_key IN ($placeholders) AND timestamp > ? ORDER BY timestamp ASC";
            $stmt = $conn->prepare($sql);
            
            // Execute with keys and timeThreshold
            $params = array_merge($keys, [$timeThreshold]);
            $stmt->execute($params);
            
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $history = [];
            foreach ($data as $row) {
                $history[] = [
                    "timestamp" => $row['timestamp'],
                    strtolower($valueKey) => $row['value']
                ];
            }
            
            $response->getBody()->write(json_encode($history));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
