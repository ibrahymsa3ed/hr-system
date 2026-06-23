<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Employee extends Model
{
    protected $guarded = [];

    protected $appends = ['full_name', 'age'];

    // Sensitive; revealed explicitly via ->makeVisible() on authorized endpoints.
    protected $hidden = ['national_id', 'basic_salary'];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'hire_date' => 'date',
            'has_mobile' => 'boolean',
            'medical_insurance' => 'boolean',
            'social_insurance' => 'boolean',
            'national_id' => 'encrypted',
            'basic_salary' => 'encrypted',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    public function section(): BelongsTo
    {
        return $this->belongsTo(Section::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(EmployeeDocument::class);
    }

    public function shiftSchedules(): HasMany
    {
        return $this->hasMany(ShiftSchedule::class);
    }

    public function attendanceRecords(): HasMany
    {
        return $this->hasMany(AttendanceRecord::class);
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class);
    }

    public function leaveLedgers(): HasMany
    {
        return $this->hasMany(LeaveLedger::class);
    }

    public function loanRequests(): HasMany
    {
        return $this->hasMany(LoanRequest::class);
    }

    public function compensationRecords(): HasMany
    {
        return $this->hasMany(CompensationRecord::class);
    }

    public function performanceReviews(): HasMany
    {
        return $this->hasMany(PerformanceReview::class);
    }

    /** Most recent active shift schedule, if any. */
    public function activeShift(): ?ShiftSchedule
    {
        return $this->shiftSchedules()
            ->where('is_active', true)
            ->latest('effective_from')
            ->first();
    }

    protected function fullName(): Attribute
    {
        return Attribute::get(fn () => trim("{$this->first_name} {$this->last_name}"));
    }

    protected function age(): Attribute
    {
        return Attribute::get(fn () => $this->date_of_birth?->age);
    }
}
