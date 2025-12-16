<?php

require_once __DIR__ . '/../vendor/autoload.php';

$app = Slim\Factory\AppFactory::create();

// Handle preflight OPTIONS requests
$app->options('/{routes:.+}', function ($request, $response, $args) {
    return $response;
});

//handle json format
$app->addBodyParsingMiddleware();

// Add Slim routing middleware
$app->addRoutingMiddleware();

// Set the base path to run the app in a subdirectory.
// This path is used in urlFor().
$app->setBasePath('/api/public');

$app->addErrorMiddleware(true, true, true);

// Add CORS middleware to handle cross-origin requests
$app->add(function ($request, $handler) {
    $response = $handler->handle($request);
    return $response
        ->withHeader('Access-Control-Allow-Origin', '*')
        ->withHeader('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Accept, Origin, Authorization')
        ->withHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
});

// Define app routes here
$app->get('/', function ($request, $response) {
    $response->getBody()->write('Hello, World!');
    return $response;
})->setName('root'); //<<<set root

//require all php files in /../src/services subdirectories
require_once __DIR__ . '/../src/Config/Database.php';
foreach (glob(__DIR__ . '/../src/services/*/*.php') as $filename) {
    // var_dump($filename); // for debug only
    require_once($filename);
}

// Greenhouse Routes (API v1)
$app->group('/v1', function (Slim\Routing\RouteCollectorProxy $group) {
    // Auth
    $group->post('/auth/register', 'App\Services\Auth\Register');
    $group->post('/auth/verify', 'App\Services\Auth\Verify');
    $group->post('/auth/login', 'App\Services\Auth\Login');
    $group->post('/auth/resend', 'App\Services\Auth\ResendCode');
    $group->post('/auth/change-password', 'App\Services\Auth\ChangePassword');
    $group->post('/auth/change-username', 'App\Services\Auth\ChangeUsername');

    // 1. Sensor Data
    $group->post('/sensors', 'App\Services\Greenhouse\SensorData');
    $group->get('/latest', 'App\Services\Greenhouse\GetLatestData:getAll');
    $group->get('/latest/{value_key}', 'App\Services\Greenhouse\GetLatestData:getByKey');
    $group->get('/history/{value_key}', 'App\Services\Greenhouse\GetHistoryData');

    // 2. System Data
    $group->get('/fan/history', 'App\Services\Greenhouse\FanData');
    $group->get('/fan/status', function ($request, $response) {
        return (new \App\Services\Greenhouse\GetSystemStatus())->getFan($request, $response);
    });
    $group->post('/fan/log', 'App\Services\Greenhouse\FanLog');
    
    $group->get('/curtain/status', function ($request, $response) {
        return (new \App\Services\Greenhouse\GetSystemStatus())->getCurtain($request, $response);
    });
    $group->post('/curtain/log', 'App\Services\Greenhouse\CurtainLog');
    
    $group->get('/irrigation/status', function ($request, $response) {
        return (new \App\Services\Greenhouse\GetSystemStatus())->getIrrigation($request, $response);
    });
    $group->post('/irrigation/log', 'App\Services\Greenhouse\IrrigationLog');
    
    $group->get('/heater/status', function ($request, $response) {
        return (new \App\Services\Greenhouse\GetSystemStatus())->getHeater($request, $response);
    });
    $group->post('/heater/log', 'App\Services\Greenhouse\HeaterLog');
    
    $group->get('/mister/status', function ($request, $response) {
        return (new \App\Services\Greenhouse\GetSystemStatus())->getMister($request, $response);
    });
    $group->post('/mister/log', 'App\Services\Greenhouse\MisterLog');

    // // 3. Profiles
    $group->get('/profiles', 'App\Services\Greenhouse\Profiles:getAll');
    $group->post('/profiles', 'App\Services\Greenhouse\Profiles:save');
    $group->post('/profiles/activate/{profile_name}', 'App\Services\Greenhouse\Profiles:activate');
    $group->get('/profiles/active', 'App\Services\Greenhouse\Profiles:getActive');

    // 4. Config
    $group->get('/config/soil', 'App\Services\Greenhouse\Config:getSoil');
    $group->post('/config/soil', 'App\Services\Greenhouse\Config:setSoil');

    // 5. Shop
    $group->get('/products', 'App\Services\Shop\Products:getAll');
    $group->post('/orders', 'App\Services\Shop\Orders:create');
    $group->get('/orders/user/{user_id}', 'App\Services\Shop\Orders:getUserOrders');

    // 6. Plant Info
    $group->get('/plant-info', 'App\Services\Plant\PlantInfo:getAll');
    $group->post('/plant-info', 'App\Services\Plant\PlantInfo:create');
    $group->get('/plant-info/{id}/comments', 'App\Services\Plant\PlantInfo:getComments');
    $group->post('/plant-info/{id}/comments', 'App\Services\Plant\PlantInfo:addComment');

    // 7. Chat
    $group->get('/chat/users', 'App\Services\Chat\Chat:getUsers');
    $group->get('/chat/messages/{other_user_id}', 'App\Services\Chat\Chat:getMessages');
    $group->post('/chat/messages', 'App\Services\Chat\Chat:sendMessage');

    // 8. Friends
    $group->post('/friends/request', function ($request, $response) {
        $data = $request->getParsedBody();
        $db = (new \App\Config\Database())->connect();
        $service = new \App\Services\Friends\Friends($db);
        $result = $service->addFriend($data['user_id'], $data['friend_username']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(isset($result['error']) ? 400 : 200);
    });

    $group->get('/friends/{user_id}', function ($request, $response, $args) {
        $db = (new \App\Config\Database())->connect();
        $service = new \App\Services\Friends\Friends($db);
        $result = $service->getFriends($args['user_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json');
    });

    $group->get('/friends/requests/{user_id}', function ($request, $response, $args) {
        $db = (new \App\Config\Database())->connect();
        $service = new \App\Services\Friends\Friends($db);
        $result = $service->getPendingRequests($args['user_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json');
    });

    $group->post('/friends/accept', function ($request, $response) {
        $data = $request->getParsedBody();
        $db = (new \App\Config\Database())->connect();
        $service = new \App\Services\Friends\Friends($db);
        $result = $service->acceptRequest($data['user_id'], $data['request_id']);
        $response->getBody()->write(json_encode($result));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(isset($result['error']) ? 400 : 200);
    });
});

// Run app
$app->run();