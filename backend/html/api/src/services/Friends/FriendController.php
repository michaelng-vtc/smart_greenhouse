<?php

namespace App\Services\Friends;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Config\Database;
use App\Services\Friends\Friends;

class FriendController
{
    public function request(Request $request, Response $response)
    {
        $data = $request->getParsedBody();
        $db = (new Database())->connect();
        $service = new Friends($db);
        $result = $service->addFriend($data['user_id'], $data['friend_username']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(isset($result['error']) ? 400 : 200);
    }

    public function getAll(Request $request, Response $response, array $args)
    {
        $db = (new Database())->connect();
        $service = new Friends($db);
        $result = $service->getFriends($args['user_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function getPending(Request $request, Response $response, array $args)
    {
        $db = (new Database())->connect();
        $service = new Friends($db);
        $result = $service->getPendingRequests($args['user_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function getSent(Request $request, Response $response, array $args)
    {
        $db = (new Database())->connect();
        $service = new Friends($db);
        $result = $service->getSentRequests($args['user_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function accept(Request $request, Response $response)
    {
        $data = $request->getParsedBody();
        $db = (new Database())->connect();
        $service = new Friends($db);
        $result = $service->acceptRequest($data['user_id'], $data['request_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(isset($result['error']) ? 400 : 200);
    }

    public function delete(Request $request, Response $response)
    {
        $data = $request->getParsedBody();
        $db = (new Database())->connect();
        $service = new Friends($db);
        $result = $service->deleteFriend($data['user_id'], $data['friend_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(isset($result['error']) ? 400 : 200);
    }
}
