<?php
namespace App\Services\Greenhouse;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class FanData {
    public function __invoke(Request $request, Response $response) {
        $params = $request->getQueryParams();
        $hours = isset($params['hours']) ? (int)$params['hours'] : 24;
        
        $db = new Database();
        $conn = $db->connect();
        try {
            $timeThreshold = date('Y-m-d H:i:s', strtotime("-{$hours} hours"));
            $stmt = $conn->prepare("SELECT timestamp, duty_cycle, status FROM fan_logs WHERE timestamp > :time ORDER BY timestamp ASC");
            $stmt->execute([':time' => $timeThreshold]);
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $response->getBody()->write(json_encode($data));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
