<?php

namespace App\Utils;

class Router {
    private static array $routes = [];

    public static function add(string $method, string $route, callable|array $handler, array $middlewares = []): void {
        // Convert route format like /api/v1/products/{id} to a regular expression
        $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<$1>[a-zA-Z0-9_\-]+)', $route);
        $pattern = '#^' . trim($pattern, '/') . '$#';

        self::$routes[] = [
            'method' => strtoupper($method),
            'pattern' => $pattern,
            'handler' => $handler,
            'middlewares' => $middlewares
        ];
    }

    public static function get(string $route, callable|array $handler, array $middlewares = []): void {
        self::add('GET', $route, $handler, $middlewares);
    }

    public static function post(string $route, callable|array $handler, array $middlewares = []): void {
        self::add('POST', $route, $handler, $middlewares);
    }

    public static function put(string $route, callable|array $handler, array $middlewares = []): void {
        self::add('PUT', $route, $handler, $middlewares);
    }

    public static function delete(string $route, callable|array $handler, array $middlewares = []): void {
        self::add('DELETE', $route, $handler, $middlewares);
    }

    public static function dispatch(string $requestMethod, string $requestUri): void {
        $requestMethod = strtoupper($requestMethod);
        $path = trim(parse_url($requestUri, PHP_URL_PATH), '/');

        // Normalize path against Hostinger subdirectory deployment (if any)
        $scriptDir = trim(dirname($_SERVER['SCRIPT_NAME']), '/');
        if (!empty($scriptDir) && strpos($path, $scriptDir) === 0) {
            $path = substr($path, strlen($scriptDir));
            $path = trim($path, '/');
        }

        foreach (self::$routes as $route) {
            if ($route['method'] === $requestMethod && preg_match($route['pattern'], $path, $matches)) {
                // Extract named parameter arguments
                $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);

                // Execute Route Middlewares
                $userContext = [];
                foreach ($route['middlewares'] as $middleware) {
                    if (is_callable($middleware)) {
                        $userContext = $middleware($userContext);
                    }
                }

                // Execute Route Handler
                $handler = $route['handler'];
                if (is_array($handler)) {
                    [$controllerClass, $method] = $handler;
                    if (class_exists($controllerClass)) {
                        $controller = new $controllerClass();
                        if (method_exists($controller, $method)) {
                            call_user_func_array([$controller, $method], [$params, $userContext]);
                            return;
                        }
                    }
                } elseif (is_callable($handler)) {
                    call_user_func($handler, $params, $userContext);
                    return;
                }

                Response::error("Internal Server Error: Handler execution failed.", 500);
                return;
            }
        }

        Response::notFound("Endpoint not found.");
    }
}
