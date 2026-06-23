<?php

namespace App\Services;

use App\Models\AttendanceRecord;
use App\Models\Employee;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Validation\ValidationException;

/**
 * Attendance engine: geofenced check-in/out, lateness & overtime, and the
 * "supervisor records for a phoneless employee" path.
 */
class AttendanceService
{
    /**
     * Check in an employee. $recordedBy is set when a supervisor records on
     * behalf of a phoneless employee; null for self check-in.
     */
    public function checkIn(Employee $employee, float $lat, float $lng, ?User $recordedBy = null): AttendanceRecord
    {
        $branch = $employee->branch;
        $within = $this->isWithinGeofence($branch, $lat, $lng);

        // Self check-in must be inside the geofence; a supervisor may override.
        if ($recordedBy === null && $branch->latitude !== null && ! $within) {
            throw ValidationException::withMessages([
                'location' => 'You are outside the branch location.',
            ]);
        }

        $today = now()->toDateString();
        $record = AttendanceRecord::where('employee_id', $employee->id)
            ->whereDate('work_date', $today)
            ->first();

        if ($record && $record->check_in_at) {
            throw ValidationException::withMessages(['attendance' => 'Already checked in today.']);
        }

        if (! $record) {
            $record = new AttendanceRecord(['employee_id' => $employee->id, 'work_date' => $today]);
        }

        $record->fill([
            'check_in_at' => now(),
            'source' => $recordedBy ? 'supervisor' : 'self',
            'recorded_by_user_id' => $recordedBy?->id,
            'check_in_lat' => $lat,
            'check_in_lng' => $lng,
            'within_geofence' => $within,
            'status' => 'present',
            'late_minutes' => $this->lateMinutes($employee, now()),
        ])->save();

        return $record;
    }

    public function checkOut(Employee $employee, float $lat, float $lng, ?User $recordedBy = null): AttendanceRecord
    {
        $record = AttendanceRecord::where('employee_id', $employee->id)
            ->whereDate('work_date', now()->toDateString())
            ->first();

        if (! $record || ! $record->check_in_at) {
            throw ValidationException::withMessages(['attendance' => 'No check-in found for today.']);
        }
        if ($record->check_out_at) {
            throw ValidationException::withMessages(['attendance' => 'Already checked out today.']);
        }

        $checkOut = now();
        $record->fill([
            'check_out_at' => $checkOut,
            'check_out_lat' => $lat,
            'check_out_lng' => $lng,
            'worked_minutes' => $this->workedMinutes($employee, $record->check_in_at, $checkOut),
            'overtime_minutes' => $this->overtimeMinutes($employee, $checkOut),
        ]);

        if ($recordedBy) {
            $record->source = 'supervisor';
            $record->recorded_by_user_id = $recordedBy->id;
        }
        $record->save();

        return $record;
    }

    /** Great-circle distance check against the branch geofence. */
    public function isWithinGeofence($branch, float $lat, float $lng): bool
    {
        if ($branch->latitude === null || $branch->longitude === null) {
            return true; // branch has no geofence configured
        }

        return $this->haversineMeters($branch->latitude, $branch->longitude, $lat, $lng)
            <= $branch->effectiveRadius();
    }

    public function haversineMeters(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earth = 6371000; // meters
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $earth * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    protected function lateMinutes(Employee $employee, Carbon $checkIn): int
    {
        $shift = $employee->activeShift();
        if (! $shift) {
            return 0;
        }

        $start = Carbon::parse($checkIn->toDateString().' '.$shift->start_time, $employee->branch->timezone);
        $grace = config('hr.attendance.lateness_grace_minutes');
        $diff = $start->diffInMinutes($checkIn, false);

        return $diff > $grace ? (int) $diff : 0;
    }

    protected function workedMinutes(Employee $employee, Carbon $in, Carbon $out): int
    {
        $break = $employee->activeShift()?->break_minutes ?? 0;

        return max(0, (int) $in->diffInMinutes($out) - $break);
    }

    protected function overtimeMinutes(Employee $employee, Carbon $checkOut): int
    {
        $shift = $employee->activeShift();
        if (! $shift) {
            return 0;
        }

        $end = Carbon::parse($checkOut->toDateString().' '.$shift->end_time, $employee->branch->timezone);
        $threshold = config('hr.attendance.overtime_threshold_minutes');
        $diff = $end->diffInMinutes($checkOut, false);

        return $diff > $threshold ? (int) $diff : 0;
    }
}
