<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Shift schedules assigned to an employee. work_days = [0..6] (Sun..Sat).
        Schema::create('shift_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('name')->nullable();
            $table->json('work_days');
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('break_minutes')->default(0);
            $table->date('effective_from')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('attendance_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->date('work_date');
            $table->dateTime('check_in_at')->nullable();
            $table->dateTime('check_out_at')->nullable();
            $table->string('source')->default('self'); // self | supervisor
            $table->foreignId('recorded_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('check_in_lat', 10, 7)->nullable();
            $table->decimal('check_in_lng', 10, 7)->nullable();
            $table->decimal('check_out_lat', 10, 7)->nullable();
            $table->decimal('check_out_lng', 10, 7)->nullable();
            $table->boolean('within_geofence')->nullable();
            $table->unsignedInteger('late_minutes')->default(0);
            $table->unsignedInteger('overtime_minutes')->default(0);
            $table->unsignedInteger('worked_minutes')->default(0);
            $table->string('status')->default('present'); // present|absent|day_off|leave
            $table->text('note')->nullable();
            $table->timestamps();

            $table->unique(['employee_id', 'work_date']);
        });

        // Shift change requested by a supervisor; on HR approval the schedule auto-applies.
        Schema::create('shift_change_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->foreignId('requested_by_user_id')->constrained('users')->cascadeOnDelete();
            $table->json('proposed_work_days');
            $table->time('proposed_start_time');
            $table->time('proposed_end_time');
            $table->unsignedInteger('proposed_break_minutes')->default(0);
            $table->date('effective_from')->nullable();
            $table->string('status')->default('pending'); // pending|approved|rejected
            $table->text('reason')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shift_change_requests');
        Schema::dropIfExists('attendance_records');
        Schema::dropIfExists('shift_schedules');
    }
};
