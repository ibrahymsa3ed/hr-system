<?php

namespace App\Models;

use App\Models\Concerns\Approvable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShiftChangeRequest extends Model
{
    use Approvable;

    protected $guarded = [];

    public const APPROVAL_TYPE = 'shift_change';

    protected function casts(): array
    {
        return [
            'proposed_work_days' => 'array',
            'proposed_break_minutes' => 'integer',
            'effective_from' => 'date',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by_user_id');
    }

    /** On HR approval the employee's working hours change automatically. */
    public function onApproved(): void
    {
        $this->employee->shiftSchedules()->update(['is_active' => false]);

        $this->employee->shiftSchedules()->create([
            'name' => 'Shift change #'.$this->id,
            'work_days' => $this->proposed_work_days,
            'start_time' => $this->proposed_start_time,
            'end_time' => $this->proposed_end_time,
            'break_minutes' => $this->proposed_break_minutes,
            'effective_from' => $this->effective_from ?? now()->toDateString(),
            'is_active' => true,
        ]);
    }
}
