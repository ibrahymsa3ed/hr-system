<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Remind staff who forgot to punch in/out, based on their shift schedule.
Schedule::command('hr:missing-punch-reminders')->everyFiveMinutes();
