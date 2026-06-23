<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Generic, append-only approval trail for any approvable model
        // (loan_requests, leave_requests, shift_change_requests, resignation_requests).
        Schema::create('approval_steps', function (Blueprint $table) {
            $table->id();
            $table->morphs('approvable');
            $table->unsignedSmallInteger('sequence');
            $table->string('role'); // role required to act on this step
            $table->string('status')->default('pending'); // pending|approved|rejected
            $table->foreignId('approver_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->dateTime('decided_at')->nullable();
            $table->text('note')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('approval_steps');
    }
};
