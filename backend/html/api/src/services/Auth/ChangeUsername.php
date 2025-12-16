<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class ChangeUsername {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $userId = $data['user_id'] ?? null;
        $newUsername = $data['new_username'] ?? null;

        if (!$userId || !$newUsername) {
            $response->getBody()->write(json_encode(['error' => 'User ID and new username are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        // Check if username already exists
        $stmt = $conn->prepare("SELECT id FROM users WHERE username = :username AND id != :id");
        $stmt->bindParam(':username', $newUsername);
        $stmt->bindParam(':id', $userId);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $response->getBody()->write(json_encode(['error' => 'Username already taken']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(409);
        }

        // Update username
        $updateStmt = $conn->prepare("UPDATE users SET username = :username WHERE id = :id");
        $updateStmt->bindParam(':username', $newUsername);
        $updateStmt->bindParam(':id', $userId);

        if ($updateStmt->execute()) {
            $response->getBody()->write(json_encode(['message' => 'Username updated successfully', 'username' => $newUsername]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } else {
            $response->getBody()->write(json_encode(['error' => 'Failed to update username']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
