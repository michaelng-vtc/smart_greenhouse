<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class CheckUsername
{
    public function __invoke(Request $request, Response $response)
    {
        $queryParams = $request->getQueryParams();
        $username = $queryParams['username'] ?? null;

        if (!$username) {
            $response->getBody()->write(json_encode(['error' => 'Username is required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("SELECT COUNT(*) FROM users WHERE username = :username");
            $stmt->bindParam(':username', $username);
            $stmt->execute();
            $count = $stmt->fetchColumn();

            $exists = $count > 0;

            $response->getBody()->write(json_encode(['exists' => $exists]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Database error: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
