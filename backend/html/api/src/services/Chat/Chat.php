<?php
namespace App\Services\Chat;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Chat {
    public function getUsers(Request $request, Response $response) {
        $currentUserId = $request->getQueryParams()['user_id'] ?? 0;
        
        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("SELECT id, username, email FROM users WHERE id != :id");
            $stmt->bindParam(':id', $currentUserId);
            $stmt->execute();
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $response->getBody()->write(json_encode($users));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to fetch users: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    public function getMessages(Request $request, Response $response, array $args) {
        $userId = $request->getQueryParams()['user_id'] ?? null;
        $otherUserId = $args['other_user_id'] ?? null;

        if (!$userId || !$otherUserId) {
            $response->getBody()->write(json_encode(['error' => 'User IDs required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("
                SELECT m.*, u.username as sender_name
                FROM chat_messages m 
                JOIN users u ON m.sender_id = u.id 
                WHERE (m.sender_id = :uid AND m.receiver_id = :oid) 
                   OR (m.sender_id = :oid AND m.receiver_id = :uid)
                ORDER BY m.created_at ASC
                LIMIT 100
            ");
            $stmt->bindParam(':uid', $userId);
            $stmt->bindParam(':oid', $otherUserId);
            $stmt->execute();
            $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $response->getBody()->write(json_encode($messages));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to fetch messages: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    public function sendMessage(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $senderId = $data['sender_id'] ?? null;
        $receiverId = $data['receiver_id'] ?? null;
        $content = $data['content'] ?? null;

        if (!$senderId || !$receiverId || !$content) {
            $response->getBody()->write(json_encode(['error' => 'Sender, Receiver and content are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("INSERT INTO chat_messages (sender_id, receiver_id, content) VALUES (:sender_id, :receiver_id, :content)");
            $stmt->bindParam(':sender_id', $senderId);
            $stmt->bindParam(':receiver_id', $receiverId);
            $stmt->bindParam(':content', $content);
            $stmt->execute();

            $response->getBody()->write(json_encode(['message' => 'Message sent successfully']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to send message: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
