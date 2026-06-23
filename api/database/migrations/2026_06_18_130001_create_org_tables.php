<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Branches (restaurants / locations) with geofence for GPS attendance.
        Schema::create('branches', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('name_ar')->nullable();
            $table->string('code')->unique();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->unsignedInteger('geofence_radius_meters')->nullable();
            $table->string('timezone')->default('UTC');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Sections (departments). main_code is the "main code for sections".
        Schema::create('sections', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('name_ar')->nullable();
            $table->string('main_code')->unique();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Employees. full_code = section.main_code + sub_code (unique per employee).
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('branch_id')->constrained()->cascadeOnDelete();
            $table->foreignId('section_id')->constrained()->cascadeOnDelete();
            $table->string('sub_code');
            $table->string('full_code')->unique();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('first_name_ar')->nullable();
            $table->string('last_name_ar')->nullable();
            $table->string('photo_path')->nullable();
            $table->text('national_id')->nullable();      // encrypted
            $table->date('date_of_birth')->nullable();     // -> age
            $table->date('hire_date')->nullable();
            $table->string('gender')->nullable();
            $table->string('marital_status')->nullable();
            $table->string('phone')->nullable();
            $table->string('email')->nullable();
            $table->boolean('has_mobile')->default(true);  // phoneless => supervisor records attendance
            $table->text('basic_salary')->nullable();      // encrypted
            $table->boolean('medical_insurance')->default(false);
            $table->string('medical_insurance_no')->nullable();
            $table->boolean('social_insurance')->default(false);
            $table->string('social_insurance_no')->nullable();
            $table->string('employment_status')->default('active'); // active|suspended|resigned|terminated
            $table->timestamps();

            $table->unique(['section_id', 'sub_code']);
        });

        // "Remaining papers" — document checklist per employee.
        Schema::create('employee_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('name_ar')->nullable();
            $table->boolean('is_submitted')->default(false);
            $table->string('file_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_documents');
        Schema::dropIfExists('employees');
        Schema::dropIfExists('sections');
        Schema::dropIfExists('branches');
    }
};
