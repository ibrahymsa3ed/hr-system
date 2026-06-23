<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_vacancies', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('title_ar')->nullable();
            $table->foreignId('branch_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('section_id')->nullable()->constrained()->nullOnDelete();
            $table->text('description')->nullable();
            $table->unsignedInteger('openings')->default(1);
            $table->string('status')->default('open'); // open|closed
            $table->timestamps();
        });

        Schema::create('candidates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('job_vacancy_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('cv_path')->nullable();
            // applied|interview|evaluated|hired|rejected
            $table->string('stage')->default('applied');
            $table->timestamps();
        });

        Schema::create('interviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('candidate_id')->constrained()->cascadeOnDelete();
            $table->foreignId('interviewer_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->dateTime('scheduled_at')->nullable();
            $table->string('mode')->nullable(); // onsite|phone|video
            $table->text('notes')->nullable();
            $table->string('status')->default('scheduled'); // scheduled|done|cancelled
            $table->timestamps();
        });

        Schema::create('candidate_evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('candidate_id')->constrained()->cascadeOnDelete();
            $table->foreignId('evaluator_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->json('criteria')->nullable(); // [{name, score}]
            $table->decimal('score', 5, 2)->nullable();
            $table->string('recommendation')->nullable(); // hire|hold|reject
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('candidate_evaluations');
        Schema::dropIfExists('interviews');
        Schema::dropIfExists('candidates');
        Schema::dropIfExists('job_vacancies');
    }
};
