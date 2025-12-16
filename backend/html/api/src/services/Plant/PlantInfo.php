<?php
namespace App\Services\Plant;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class PlantInfo {
    public function getAll(Request $request, Response $response) {
        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->query("SELECT * FROM plant_info ORDER BY created_at DESC");
            $info = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $response->getBody()->write(json_encode($info));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to fetch plant info: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    public function create(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $title = $data['title'] ?? null;
        $content = $data['content'] ?? null;
        $imageUrl = $data['image_url'] ?? null;

        if (!$title || !$content) {
            $response->getBody()->write(json_encode(['error' => 'Title and content are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("INSERT INTO plant_info (title, content, image_url) VALUES (:title, :content, :image_url)");
            $stmt->bindParam(':title', $title);
            $stmt->bindParam(':content', $content);
            $stmt->bindParam(':image_url', $imageUrl);
            $stmt->execute();

            $response->getBody()->write(json_encode(['message' => 'Plant info created successfully']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to create plant info: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    public function getComments(Request $request, Response $response, array $args) {
        $id = $args['id'];
        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("
                SELECT c.*, u.username 
                FROM plant_info_comments c 
                JOIN users u ON c.user_id = u.id 
                WHERE c.plant_info_id = :id 
                ORDER BY c.created_at DESC
            ");
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $response->getBody()->write(json_encode($comments));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to fetch comments: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    public function addComment(Request $request, Response $response, array $args) {
        $id = $args['id'];
        $data = $request->getParsedBody();
        $userId = $data['user_id'] ?? null;
        $content = $data['content'] ?? null;

        if (!$userId || !$content) {
            $response->getBody()->write(json_encode(['error' => 'User ID and content are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        try {
            $stmt = $conn->prepare("INSERT INTO plant_info_comments (plant_info_id, user_id, content) VALUES (:plant_info_id, :user_id, :content)");
            $stmt->bindParam(':plant_info_id', $id);
            $stmt->bindParam(':user_id', $userId);
            $stmt->bindParam(':content', $content);
            $stmt->execute();

            $response->getBody()->write(json_encode(['message' => 'Comment added successfully']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => 'Failed to add comment: ' . $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
