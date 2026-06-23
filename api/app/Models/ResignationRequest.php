<?php

namespace App\Models;

use App\Models\Concerns\Approvable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ResignationRequest extends Model
{
    use Approvable;

    protected $guarded = [];

    public const APPROVAL_TYPE = 'resignation';

    protected function casts(): array
    {
        return ['last_working_day' => 'date'];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function onApproved(): void
    {
        $this->employee->forceFill(['employment_status' => 'resigned'])->save();
    }
}
