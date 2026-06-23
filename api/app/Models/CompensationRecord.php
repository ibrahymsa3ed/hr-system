<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CompensationRecord extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'basic_salary' => 'encrypted',
            'medical_insurance' => 'boolean',
            'social_insurance' => 'boolean',
            'effective_date' => 'date',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
