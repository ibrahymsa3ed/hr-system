<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Per-employee, per-year leave balances.
        Schema::create('leave_ledgers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('year');
            $table->string('type'); // annual|unpaid|sick|day_off
            $table->decimal('entitled_days', 5, 1)->default(0);
            $table->decimal('used_days', 5, 1)->default(0);
            $table->timestamps();

            $table->unique(['employee_id', 'year', 'type']);
        });

        // Leave / permission / vacation requests (approval chain via approval_steps).
        Schema::create('leave_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // annual|unpaid|sick|day_off|permission
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->time('start_time')->nullable(); // permissions (hourly)
            $table->time('end_time')->nullable();
            $table->decimal('days', 5, 1)->default(0);
            $table->text('reason')->nullable();
            $table->string('status')->default('pending'); // pending|approved|rejected|cancelled
            $table->timestamps();
        });

        // Compensation history: basic salary + insurance, effective-dated.
        Schema::create('compensation_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->text('basic_salary')->nullable(); // encrypted
            $table->boolean('medical_insurance')->default(false);
            $table->boolean('social_insurance')->default(false);
            $table->string('medical_insurance_no')->nullable();
            $table->string('social_insurance_no')->nullable();
            $table->date('effective_date');
            $table->text('note')->nullable();
            $table->timestamps();
        });

        // Loans & advances: 3-step approval (manager -> HR director -> finance).
        Schema::create('loan_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // advance | long_term
            $table->decimal('amount', 12, 2);
            $table->unsignedInteger('installments')->default(1);
            $table->text('reason')->nullable();
            $table->string('status')->default('pending'); // pending|approved|rejected
            $table->timestamps();
        });

        Schema::create('resignation_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->text('reason')->nullable();
            $table->date('last_working_day')->nullable();
            $table->string('status')->default('pending');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('resignation_requests');
        Schema::dropIfExists('loan_requests');
        Schema::dropIfExists('compensation_records');
        Schema::dropIfExists('leave_requests');
        Schema::dropIfExists('leave_ledgers');
    }
};
