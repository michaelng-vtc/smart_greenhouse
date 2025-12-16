<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class ChangePassword {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $userId = $data['user_id'] ?? null;
        $oldPassword = $data['old_password'] ?? null;
        $newPassword = $data['new_password'] ?? null;

        if (!$userId || !$oldPassword || !$newPassword) {
            $response->getBody()->write(json_encode(['error' => 'User ID, old password, and new password are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        // Verify old password
        $stmt = $conn->prepare("SELECT password FROM users WHERE id = :id");
        $stmt->bindParam(':id', $userId);
        $stmt->execute();

        if ($stmt->rowCount() === 0) {
            $response->getBody()->write(json_encode(['error' => 'User not found']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }

        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!password_verify($oldPassword, $user['password'])) {
            $response->getBody()->write(json_encode(['error' => 'Incorrect old password']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(401);
        }

        // Update password
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        $updateStmt = $conn->prepare("UPDATE users SET password = :password WHERE id = :id");
        $updateStmt->bindParam(':password', $hashedPassword);
        $updateStmt->bindParam(':id', $userId);

        if ($updateStmt->execute()) {
            $response->getBody()->write(json_encode(['message' => 'Password updated successfully']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } else {
            $response->getBody()->write(json_encode(['error' => 'Failed to update password']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
