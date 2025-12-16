<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class ResendCode {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $email = $data['email'] ?? null;

        if (!$email) {
            $response->getBody()->write(json_encode(['error' => 'Email is required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        // Check if user exists and is not verified
        $stmt = $conn->prepare("SELECT id, is_verified FROM users WHERE email = :email");
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        if ($stmt->rowCount() == 0) {
            $response->getBody()->write(json_encode(['error' => 'User not found']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }

        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($user['is_verified'] == 1) {
            $response->getBody()->write(json_encode(['error' => 'User already verified']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        // Generate new verification code
        $verificationCode = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

        // Update user with new code
        $updateStmt = $conn->prepare("UPDATE users SET verification_code = :code WHERE email = :email");
        $updateStmt->bindParam(':code', $verificationCode);
        $updateStmt->bindParam(':email', $email);

        if ($updateStmt->execute()) {
            // Send verification email
            $subject = "Smart Greenhouse Verification Code (Resend)";
            $message = "Your new verification code is: $verificationCode";
            $headers = "From: no-reply@smartgreenhouse.com";
            mail($email, $subject, $message, $headers);

            $response->getBody()->write(json_encode(['message' => 'Verification code resent successfully']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } else {
            $response->getBody()->write(json_encode(['error' => 'Failed to resend code']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
