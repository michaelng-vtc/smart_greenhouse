<?php
namespace App\Services\Greenhouse;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class GetLatestData {
    public function getAll(Request $request, Response $response) {
        $db = new Database();
        $conn = $db->connect();
        try {
            $sql = "
                SELECT t1.timestamp, t1.topic, t1.value_key, t1.value
                FROM sensor_readings t1
                INNER JOIN (
                    SELECT MAX(id) AS max_id FROM sensor_readings GROUP BY topic, value_key
                ) t2 ON t1.id = t2.max_id ORDER BY t1.timestamp DESC
            ";
            $stmt = $conn->query($sql);
            $latestData = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $result = [];
            foreach ($latestData as $row) {
                $key = strtolower($row['value_key']);
                $result[$key] = ["timestamp" => $row['timestamp'], "value" => $row['value']];
            }
            $response->getBody()->write(json_encode($result));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    public function getByKey(Request $request, Response $response, $args) {
        $valueKey = $args['value_key'];
        $db = new Database();
        $conn = $db->connect();
        try {
            $stmt = $conn->prepare("SELECT timestamp, value FROM sensor_readings WHERE value_key = :key ORDER BY id DESC LIMIT 1");
            $stmt->execute([':key' => $valueKey]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($row) {
                $response->getBody()->write(json_encode($row));
            } else {
                $response->getBody()->write(json_encode(['error' => 'Not found']));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
