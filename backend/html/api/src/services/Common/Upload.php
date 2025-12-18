<?php
namespace App\Services\Common;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class Upload {
    public function __invoke(Request $request, Response $response) {
        try {
            $directory = __DIR__ . '/../../../public/uploads';
            
            if (!is_dir($directory)) {
                if (!mkdir($directory, 0777, true)) {
                    throw new \Exception("Failed to create directory: $directory");
                }
            }

            $uploadedFiles = $request->getUploadedFiles();
            
            if (empty($uploadedFiles['image'])) {
                // Check for post_max_size exceeded
                $contentLength = $_SERVER['CONTENT_LENGTH'] ?? 0;
                if ($contentLength > 0 && empty($_POST) && empty($_FILES)) {
                    $response->getBody()->write(json_encode(['error' => 'File too large (exceeded post_max_size)']));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(413);
                }

                $response->getBody()->write(json_encode(['error' => 'No image uploaded']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            $uploadedFile = $uploadedFiles['image'];

            if ($uploadedFile->getError() === UPLOAD_ERR_OK) {
                $clientFilename = $uploadedFile->getClientFilename();
                $extension = '';
                if ($clientFilename) {
                    $extension = pathinfo($clientFilename, PATHINFO_EXTENSION);
                }
                // Fallback if extension is missing
                if (!$extension) $extension = 'jpg';
                
                // Get user_id from request body (multipart fields)
                $parsedBody = $request->getParsedBody();
                $userId = $parsedBody['user_id'] ?? 'anon';

                // Generate a unique name using timestamp and random entropy to prevent collisions
                // Include user_id in filename for better organization
                $basename = uniqid('seed_u' . $userId . '_', true);
                $filename = sprintf('%s.%s', $basename, $extension);
                $targetPath = $directory . DIRECTORY_SEPARATOR . $filename;

                $uploadedFile->moveTo($targetPath);

                // Return relative path
                $url = 'uploads/' . $filename;
                
                $response->getBody()->write(json_encode(['url' => $url]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
            }

            $errorCode = $uploadedFile->getError();
            $errorMsg = 'Upload failed with error code: ' . $errorCode;
            if ($errorCode === UPLOAD_ERR_INI_SIZE || $errorCode === UPLOAD_ERR_FORM_SIZE) {
                $errorMsg = 'File is too large';
            }

            $response->getBody()->write(json_encode(['error' => $errorMsg]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);

        } catch (\Throwable $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Internal Error: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}
