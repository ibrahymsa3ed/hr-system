<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Issue a Sanctum token. Used for both password and (post device-unlock)
     * biometric logins — biometrics gate the stored credentials on-device.
     */
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['email' => __('auth.failed')]);
        }

        $token = $user->createToken($data['device_name'] ?? 'app')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->profile($user),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->profile($request->user())]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => __('auth.logged_out')]);
    }

    /** Register an FCM device token for push notifications. */
    public function registerDevice(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string'],
            'platform' => ['nullable', 'in:android,ios,web'],
        ]);

        $request->user()->deviceTokens()->updateOrCreate(
            ['token' => $data['token']],
            ['platform' => $data['platform'] ?? null],
        );

        return response()->json(['message' => 'registered']);
    }

    private function profile(User $user): array
    {
        $user->load('employee.branch', 'employee.section');

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'roles' => $user->getRoleNames(),
            'employee' => $user->employee,
        ];
    }
}
