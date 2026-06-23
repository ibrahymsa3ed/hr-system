<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sends push notifications to a user's registered devices.
 *
 * Default implementation logs and (when FCM_CREDENTIALS / server key is set)
 * posts to Firebase Cloud Messaging. Swap the transport here without touching
 * callers (attendance reminders, approval notifications).
 */
class PushNotifier
{
    public function toUser(User $user, string $title, string $body, array $data = []): void
    {
        $tokens = $user->deviceTokens()->pluck('token')->all();
        if (empty($tokens)) {
            return;
        }

        $serverKey = config('services.fcm.server_key');
        if (! $serverKey) {
            // No FCM configured (e.g. local/dev): record intent only.
            Log::info('push', compact('title', 'body', 'data') + ['user' => $user->id, 'tokens' => count($tokens)]);

            return;
        }

        Http::withToken($serverKey)
            ->post('https://fcm.googleapis.com/fcm/send', [
                'registration_ids' => $tokens,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => $data,
            ]);
    }
}
