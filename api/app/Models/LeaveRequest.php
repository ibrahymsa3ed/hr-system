<?php

namespace App\Models;

use App\Models\Concerns\Approvable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LeaveRequest extends Model
{
    use Approvable;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'days' => 'float',
        ];
    }

    /** Map the leave type to the right approval chain key. */
    public function approvalType(): string
    {
        return $this->type === 'permission' ? 'permission' : 'leave';
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    /** On approval, draw down the matching yearly leave ledger. */
    public function onApproved(): void
    {
        if (! in_array($this->type, config('hr.leave_types'), true)) {
            return; // e.g. hourly "permission" requests are not day-balance tracked
        }

        $ledger = $this->employee->leaveLedgers()->firstOrCreate(
            ['year' => $this->start_date->year, 'type' => $this->type],
            ['entitled_days' => config("hr.leave_entitlements.{$this->type}", 0)],
        );

        $ledger->increment('used_days', $this->days);
    }
}
