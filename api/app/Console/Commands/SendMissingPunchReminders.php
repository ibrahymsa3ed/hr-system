<?php

namespace App\Console\Commands;

use App\Models\Employee;
use App\Services\PushNotifier;
use Carbon\Carbon;
use Illuminate\Console\Command;

/**
 * Reminds employees who forgot to check in/out, based on their shift schedule.
 * Runs every few minutes (see routes/console.php). Only employees with a phone
 * are reminded — phoneless staff are recorded by their supervisor.
 */
class SendMissingPunchReminders extends Command
{
    protected $signature = 'hr:missing-punch-reminders';

    protected $description = 'Notify employees who have not yet checked in/out for their shift';

    public function handle(PushNotifier $push): int
    {
        $grace = config('hr.attendance.missing_punch_grace_minutes');
        $today = now()->toDateString();
        $weekday = (int) now()->dayOfWeek; // 0=Sun..6=Sat
        $sent = 0;

        $employees = Employee::query()
            ->where('has_mobile', true)
            ->whereHas('user')
            ->with(['user', 'attendanceRecords' => fn ($q) => $q->where('work_date', $today)])
            ->get();

        foreach ($employees as $employee) {
            $shift = $employee->activeShift();
            if (! $shift || ! in_array($weekday, $shift->work_days ?? [], true)) {
                continue;
            }

            $record = $employee->attendanceRecords->first();
            $tz = $employee->branch->timezone ?? 'UTC';
            $start = Carbon::parse("$today {$shift->start_time}", $tz);
            $end = Carbon::parse("$today {$shift->end_time}", $tz);
            $now = now();

            // Missed check-in: shift started over `grace` minutes ago, no punch yet.
            if (! $record?->check_in_at && $now->gt($start->copy()->addMinutes($grace)) && $now->lt($end)) {
                $push->toUser($employee->user, 'Check-in reminder', "Don't forget to record your arrival.", ['type' => 'missing_check_in']);
                $sent++;
            }

            // Missed check-out: shift ended over `grace` minutes ago, checked in but not out.
            if ($record?->check_in_at && ! $record?->check_out_at && $now->gt($end->copy()->addMinutes($grace))) {
                $push->toUser($employee->user, 'Check-out reminder', "Don't forget to record your departure.", ['type' => 'missing_check_out']);
                $sent++;
            }
        }

        $this->info("Sent {$sent} reminder(s).");

        return self::SUCCESS;
    }
}
