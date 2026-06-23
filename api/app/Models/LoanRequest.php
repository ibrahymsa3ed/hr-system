<?php

namespace App\Models;

use App\Models\Concerns\Approvable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LoanRequest extends Model
{
    use Approvable;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'installments' => 'integer',
        ];
    }

    /** advance and long_term share the manager -> HR director -> finance chain. */
    public function approvalType(): string
    {
        return $this->type === 'advance' ? 'advance' : 'loan';
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
