<?php

/*
|--------------------------------------------------------------------------
| HR System domain configuration
|--------------------------------------------------------------------------
| Central place for roles, approval chains, leave types and attendance rules
| so business rules are not hardcoded across controllers/models.
*/

return [

    // Application roles (also seeded into spatie/laravel-permission).
    'roles' => [
        'employee',        // self-service
        'supervisor',      // restaurant manager / branch supervisor
        'section_manager', // department/section manager
        'hr_director',
        'finance',
        'hr_admin',        // super admin
    ],

    // Ordered approval chains by request type. Each entry is the role that must
    // approve, in sequence. The generic ApprovalService walks these in order.
    'approval_chains' => [
        // Loans & salary advances: manager -> HR director -> finance
        'loan'        => ['section_manager', 'hr_director', 'finance'],
        'advance'     => ['section_manager', 'hr_director', 'finance'],
        // Leave / permission / vacation: section manager (+ branch supervisor)
        'leave'       => ['supervisor', 'section_manager'],
        'permission'  => ['supervisor'],
        // Shift change: requested by supervisor, approved by HR
        'shift_change'=> ['hr_director'],
        // Resignation: manager -> HR
        'resignation' => ['section_manager', 'hr_director'],
    ],

    // Leave ledger categories tracked per employee per year.
    'leave_types' => [
        'annual',
        'unpaid',
        'sick',
        'day_off',
    ],

    // Default annual entitlements (days) used when opening a yearly ledger.
    'leave_entitlements' => [
        'annual'  => 21,
        'sick'    => 7,
        'day_off' => 52, // weekly day-off allowance
        'unpaid'  => 0,  // no cap; tracked for reporting only
    ],

    'attendance' => [
        // Geofence radius (meters) when a branch does not define its own.
        'default_radius_meters' => (int) env('GEOFENCE_DEFAULT_RADIUS_METERS', 150),
        // Minutes after shift start before a check-in counts as "late".
        'lateness_grace_minutes' => 10,
        // Minutes after shift end/start before we push a "you forgot to punch" reminder.
        'missing_punch_grace_minutes' => (int) env('ATTENDANCE_MISSING_PUNCH_GRACE_MINUTES', 30),
        // Minutes worked beyond scheduled end that count as overtime.
        'overtime_threshold_minutes' => 15,
    ],
];
