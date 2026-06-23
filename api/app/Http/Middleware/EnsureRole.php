<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Role gate for the Sanctum-authenticated user. Uses the model's roles
 * directly (guard 'web'), avoiding the Sanctum/spatie guard mismatch that
 * trips up the stock `role` middleware on API routes.
 *
 * Usage: ->middleware('hr.role:hr_admin,hr_director')
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        abort_if(! $user || ! $user->hasAnyRole($roles), 403, 'Insufficient role.');

        return $next($request);
    }
}
