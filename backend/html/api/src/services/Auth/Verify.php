<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Verify {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $email = $data['email'] ?? null;
        $code = $data['code'] ?? null;

        if (!$email || !$code) {
            $response->getBody()->write(json_encode(['error' => 'Email and verification code are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        $stmt = $conn->prepare("SELECT id FROM users WHERE email = :email AND verification_code = :code");
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':code', $code);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $updateStmt = $conn->prepare("UPDATE users SET is_verified = 1, verification_code = NULL WHERE email = :email");
            $updateStmt->bindParam(':email', $email);
            
            if ($updateStmt->execute()) {
                $response->getBody()->write(json_encode(['message' => 'Email verified successfully']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
            }
        }

        $response->getBody()->write(json_encode(['error' => 'Invalid verification code']));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
    }
}
