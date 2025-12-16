<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Login {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $username = $data['username'] ?? null;
        $password = $data['password'] ?? null;

        if (!$username || !$password) {
            $response->getBody()->write(json_encode(['error' => 'Username and password are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        $stmt = $conn->prepare("SELECT id, username, password, is_verified FROM users WHERE username = :username");
        $stmt->bindParam(':username', $username);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            if (password_verify($password, $user['password'])) {
                if ($user['is_verified'] == 0) {
                    $response->getBody()->write(json_encode(['error' => 'Please verify your email address before logging in']));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
                }

                // Password correct
                unset($user['password']); // Don't send password back
                $response->getBody()->write(json_encode(['message' => 'Login successful', 'user' => $user]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
            }
        }

        $response->getBody()->write(json_encode(['error' => 'Invalid username or password']));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(401);
    }
}
