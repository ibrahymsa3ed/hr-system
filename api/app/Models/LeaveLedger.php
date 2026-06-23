<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LeaveLedger extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'entitled_days' => 'float',
            'used_days' => 'float',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function remainingDays(): float
    {
        return round($this->entitled_days - $this->used_days, 1);
    }
}
