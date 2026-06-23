<?php

use App\Http\Controllers\Api\ApprovalController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BranchController;
use App\Http\Controllers\Api\CompensationRecordController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeeDocumentController;
use App\Http\Controllers\Api\LeaveRequestController;
use App\Http\Controllers\Api\LoanRequestController;
use App\Http\Controllers\Api\PerformanceReviewController;
use App\Http\Controllers\Api\Recruitment\CandidateController;
use App\Http\Controllers\Api\Recruitment\CandidateEvaluationController;
use App\Http\Controllers\Api\Recruitment\InterviewController;
use App\Http\Controllers\Api\Recruitment\JobVacancyController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ResignationRequestController;
use App\Http\Controllers\Api\SectionController;
use App\Http\Controllers\Api\SelfServiceController;
use App\Http\Controllers\Api\ShiftChangeRequestController;
use App\Http\Controllers\Api\ShiftScheduleController;
use Illuminate\Support\Facades\Route;

// Role groupings.
$MANAGE = 'hr.role:hr_admin,hr_director';                                   // HR back-office
$STAFF = 'hr.role:hr_admin,hr_director,section_manager,supervisor,finance'; // any manager
$SUPERVISE = 'hr.role:hr_admin,hr_director,supervisor';                     // can record attendance
$REVIEW = 'hr.role:hr_admin,hr_director,section_manager';                   // performance & recruitment

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function () use ($MANAGE, $STAFF, $SUPERVISE, $REVIEW) {
    // Account
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/devices', [AuthController::class, 'registerDevice']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Employee self-service ("Allowed for employees")
    Route::get('/me/monthly-report', [SelfServiceController::class, 'monthlyReport']);
    Route::get('/me/salary', [SelfServiceController::class, 'salary']);
    Route::get('/me/leave-balances', [SelfServiceController::class, 'leaveBalances']);

    // Attendance — self check-in/out (GPS validated), supervisor records for others
    Route::post('/attendance/check-in', [AttendanceController::class, 'checkIn']);
    Route::post('/attendance/check-out', [AttendanceController::class, 'checkOut']);
    Route::post('/attendance/record', [AttendanceController::class, 'recordForEmployee'])->middleware($SUPERVISE);
    Route::get('/attendance', [AttendanceController::class, 'index'])->middleware($STAFF);

    // Requests — employees submit; listings are role-filtered inside controllers
    Route::apiResource('leave-requests', LeaveRequestController::class)->only(['index', 'store', 'show']);
    Route::apiResource('loan-requests', LoanRequestController::class)->only(['index', 'store', 'show']);
    Route::apiResource('resignation-requests', ResignationRequestController::class)->only(['index', 'store']);
    Route::get('/shift-change-requests', [ShiftChangeRequestController::class, 'index'])->middleware($STAFF);
    Route::post('/shift-change-requests', [ShiftChangeRequestController::class, 'store'])->middleware($SUPERVISE);

    // Approvals (chain enforces the required role on each step)
    Route::get('/approvals/pending', [ApprovalController::class, 'pending']);
    Route::post('/approvals/{step}/decide', [ApprovalController::class, 'decide']);

    // Performance appraisal (employees see their own via index filter)
    Route::get('/performance-reviews', [PerformanceReviewController::class, 'index']);
    Route::get('/performance-reviews/{performanceReview}', [PerformanceReviewController::class, 'show']);
    Route::post('/performance-reviews', [PerformanceReviewController::class, 'store'])->middleware($REVIEW);
    Route::put('/performance-reviews/{performanceReview}', [PerformanceReviewController::class, 'update'])->middleware($REVIEW);

    // Reports
    Route::get('/reports/daily', [ReportController::class, 'daily'])->middleware($STAFF);
    Route::get('/reports/period', [ReportController::class, 'period'])->middleware($STAFF);

    // --- Org & employee administration (read for managers, writes for HR) ---
    Route::middleware($STAFF)->group(function () {
        Route::get('/branches', [BranchController::class, 'index']);
        Route::get('/branches/{branch}', [BranchController::class, 'show']);
        Route::get('/sections', [SectionController::class, 'index']);
        Route::get('/sections/{section}', [SectionController::class, 'show']);
        Route::get('/employees', [EmployeeController::class, 'index']);
        Route::get('/employees/{employee}', [EmployeeController::class, 'show']);
        Route::get('/employees/{employee}/shifts', [ShiftScheduleController::class, 'index']);
        Route::get('/employees/{employee}/documents', [EmployeeDocumentController::class, 'index']);
    });

    Route::middleware($MANAGE)->group(function () {
        Route::apiResource('branches', BranchController::class)->except(['index', 'show']);
        Route::apiResource('sections', SectionController::class)->except(['index', 'show']);
        Route::apiResource('employees', EmployeeController::class)->except(['index', 'show']);

        // Shift schedules
        Route::post('/employees/{employee}/shifts', [ShiftScheduleController::class, 'store']);
        Route::delete('/employees/{employee}/shifts/{shift}', [ShiftScheduleController::class, 'destroy']);

        // Remaining papers
        Route::post('/employees/{employee}/documents', [EmployeeDocumentController::class, 'store']);
        Route::put('/employees/{employee}/documents/{document}', [EmployeeDocumentController::class, 'update']);
        Route::delete('/employees/{employee}/documents/{document}', [EmployeeDocumentController::class, 'destroy']);

        // Compensation (salary + insurance)
        Route::get('/employees/{employee}/compensation', [CompensationRecordController::class, 'index']);
        Route::post('/employees/{employee}/compensation', [CompensationRecordController::class, 'store']);
    });

    // --- Recruitment ---
    Route::middleware($REVIEW)->group(function () {
        Route::apiResource('job-vacancies', JobVacancyController::class);
        Route::apiResource('candidates', CandidateController::class)->only(['index', 'store', 'show', 'update']);
        Route::post('/candidates/{candidate}/interviews', [InterviewController::class, 'store']);
        Route::put('/interviews/{interview}', [InterviewController::class, 'update']);
        Route::post('/candidates/{candidate}/evaluations', [CandidateEvaluationController::class, 'store']);
        Route::post('/candidates/{candidate}/hire', [CandidateController::class, 'hire']);
    });
});
