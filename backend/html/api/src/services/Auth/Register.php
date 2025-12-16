<?php

namespace App\Services\Auth;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use PDO;

class Register {
    public function __invoke(Request $request, Response $response) {
        $data = $request->getParsedBody();
        $username = $data['username'] ?? null;
        $email = $data['email'] ?? null;
        $password = $data['password'] ?? null;

        if (!$username || !$email || !$password) {
            $response->getBody()->write(json_encode(['error' => 'Username, email, and password are required']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        $db = new Database();
        $conn = $db->connect();

        // Check if user exists
        $stmt = $conn->prepare("SELECT id FROM users WHERE username = :username OR email = :email");
        $stmt->bindParam(':username', $username);
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $response->getBody()->write(json_encode(['error' => 'Username or email already exists']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(409);
        }

        // Hash password
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        
        // Generate verification code
        $verificationCode = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

        // Insert user
        $stmt = $conn->prepare("INSERT INTO users (username, email, password, verification_code) VALUES (:username, :email, :password, :code)");
        $stmt->bindParam(':username', $username);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':password', $hashedPassword);
        $stmt->bindParam(':code', $verificationCode);

        if ($stmt->execute()) {
            // Send verification email
            $subject = "Smart Greenhouse Verification Code";
            $message = "Your verification code is: $verificationCode";
            // Use mailx via shell_exec if standard mail() is not configured, or just use mail()
            // Given the user showed mailx working, we can try standard mail() first as it usually wraps sendmail/postfix.
            // If that fails, we might need a specific command.
            // Let's use standard mail() with a simple header.
            $headers = "From: no-reply@smartgreenhouse.com";
            mail($email, $subject, $message, $headers);

            $response->getBody()->write(json_encode(['message' => 'Registration successful. Please verify your email.']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } else {
            $response->getBody()->write(json_encode(['error' => 'Registration failed']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
