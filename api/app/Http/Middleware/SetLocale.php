<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Sets the app locale (en|ar) from the Accept-Language header so API responses
 * and validation messages are localized. Falls back to the configured default.
 */
class SetLocale
{
    public function handle(Request $request, Closure $next): Response
    {
        $supported = ['en', 'ar'];
        $locale = substr((string) $request->header('Accept-Language', ''), 0, 2);

        app()->setLocale(in_array($locale, $supported, true) ? $locale : config('app.locale'));

        return $next($request);
    }
}
