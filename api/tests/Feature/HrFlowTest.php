<?php

namespace Tests\Feature;

use App\Models\Branch;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\LoanRequest;
use App\Models\Section;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class HrFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function userWithRole(string $role, array $attrs = []): User
    {
        $user = User::create(array_merge([
            'name' => ucfirst($role),
            'email' => $role.fake()->unique()->numberBetween(1, 99999).'@hr.test',
            'password' => Hash::make('password'),
        ], $attrs));
        $user->assignRole($role);

        return $user;
    }

    private function org(): array
    {
        $branch = Branch::create([
            'name' => 'Cairo', 'code' => 'BR1',
            'latitude' => 30.0444, 'longitude' => 31.2357,
            'geofence_radius_meters' => 150, 'timezone' => 'Africa/Cairo',
        ]);
        $section = Section::create(['name' => 'Kitchen', 'main_code' => '10']);

        return [$branch, $section];
    }

    public function test_login_returns_token_and_roles(): void
    {
        $this->userWithRole('hr_admin', ['email' => 'admin@hr.test']);

        $res = $this->postJson('/api/login', ['email' => 'admin@hr.test', 'password' => 'password']);

        $res->assertOk()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'roles']])
            ->assertJsonPath('user.roles.0', 'hr_admin');
    }

    public function test_leave_request_runs_full_approval_chain_and_updates_ledger(): void
    {
        [$branch, $section] = $this->org();
        $empUser = $this->userWithRole('employee');
        $employee = Employee::create([
            'user_id' => $empUser->id, 'branch_id' => $branch->id, 'section_id' => $section->id,
            'sub_code' => '0001', 'full_code' => '10-0001',
            'first_name' => 'A', 'last_name' => 'B',
        ]);

        // Employee submits a 3-day annual leave.
        $res = $this->actingAs($empUser, 'sanctum')->postJson('/api/leave-requests', [
            'type' => 'annual', 'start_date' => '2026-07-01', 'end_date' => '2026-07-03',
        ]);
        $res->assertCreated();
        $leave = LeaveRequest::first();
        $this->assertSame(3.0, (float) $leave->days);
        // Chain: supervisor -> section_manager
        $this->assertSame(2, $leave->approvalSteps()->count());

        $supervisor = $this->userWithRole('supervisor');
        $manager = $this->userWithRole('section_manager');

        $step1 = $leave->currentApprovalStep();
        $this->actingAs($supervisor, 'sanctum')
            ->postJson("/api/approvals/{$step1->id}/decide", ['approved' => true])
            ->assertOk();

        $step2 = $leave->fresh()->currentApprovalStep();
        $this->actingAs($manager, 'sanctum')
            ->postJson("/api/approvals/{$step2->id}/decide", ['approved' => true])
            ->assertOk();

        $this->assertSame('approved', $leave->fresh()->status);
        // Ledger drawn down by 3 days.
        $this->assertEquals(3.0, $employee->leaveLedgers()->where('type', 'annual')->first()->used_days);
    }

    public function test_loan_requires_three_approvals_in_order(): void
    {
        [$branch, $section] = $this->org();
        $empUser = $this->userWithRole('employee');
        Employee::create([
            'user_id' => $empUser->id, 'branch_id' => $branch->id, 'section_id' => $section->id,
            'sub_code' => '0002', 'full_code' => '10-0002', 'first_name' => 'C', 'last_name' => 'D',
        ]);

        $this->actingAs($empUser, 'sanctum')->postJson('/api/loan-requests', [
            'type' => 'long_term', 'amount' => 5000, 'installments' => 10,
        ])->assertCreated();

        $loan = LoanRequest::first();
        $this->assertSame(3, $loan->approvalSteps()->count());

        $manager = $this->userWithRole('section_manager');
        $hrDirector = $this->userWithRole('hr_director');
        $finance = $this->userWithRole('finance');

        // Finance cannot jump ahead of the manager's step.
        $first = $loan->currentApprovalStep();
        $this->actingAs($finance, 'sanctum')
            ->postJson("/api/approvals/{$first->id}/decide", ['approved' => true])
            ->assertStatus(422);

        foreach ([$manager, $hrDirector, $finance] as $approver) {
            $step = $loan->fresh()->currentApprovalStep();
            $this->actingAs($approver, 'sanctum')
                ->postJson("/api/approvals/{$step->id}/decide", ['approved' => true])
                ->assertOk();
        }

        $this->assertSame('approved', $loan->fresh()->status);
    }

    public function test_geofence_rejects_checkin_outside_radius(): void
    {
        [$branch, $section] = $this->org();
        $empUser = $this->userWithRole('employee');
        Employee::create([
            'user_id' => $empUser->id, 'branch_id' => $branch->id, 'section_id' => $section->id,
            'sub_code' => '0003', 'full_code' => '10-0003', 'first_name' => 'E', 'last_name' => 'F',
        ]);

        // Far away -> rejected.
        $this->actingAs($empUser, 'sanctum')->postJson('/api/attendance/check-in', [
            'latitude' => 31.5, 'longitude' => 32.5,
        ])->assertStatus(422);

        // At the branch -> accepted.
        $this->actingAs($empUser, 'sanctum')->postJson('/api/attendance/check-in', [
            'latitude' => 30.0444, 'longitude' => 31.2357,
        ])->assertOk();
    }

    public function test_supervisor_can_record_attendance_for_phoneless_employee(): void
    {
        [$branch, $section] = $this->org();
        $phoneless = Employee::create([
            'branch_id' => $branch->id, 'section_id' => $section->id, 'has_mobile' => false,
            'sub_code' => '0004', 'full_code' => '10-0004', 'first_name' => 'G', 'last_name' => 'H',
        ]);
        $supervisor = $this->userWithRole('supervisor');

        $this->actingAs($supervisor, 'sanctum')->postJson('/api/attendance/record', [
            'employee_id' => $phoneless->id, 'action' => 'check_in',
            'latitude' => 30.0444, 'longitude' => 31.2357,
        ])->assertOk()->assertJsonPath('record.source', 'supervisor');
    }

    public function test_employee_cannot_list_all_employees(): void
    {
        $empUser = $this->userWithRole('employee');

        $this->actingAs($empUser, 'sanctum')->getJson('/api/employees')->assertStatus(403);
    }

    public function test_shift_change_approval_auto_applies_schedule(): void
    {
        [$branch, $section] = $this->org();
        $employee = Employee::create([
            'branch_id' => $branch->id, 'section_id' => $section->id,
            'sub_code' => '0005', 'full_code' => '10-0005', 'first_name' => 'I', 'last_name' => 'J',
        ]);
        $supervisor = $this->userWithRole('supervisor');
        $hrDirector = $this->userWithRole('hr_director');

        $this->actingAs($supervisor, 'sanctum')->postJson('/api/shift-change-requests', [
            'employee_id' => $employee->id,
            'proposed_work_days' => [1, 2, 3, 4, 5],
            'proposed_start_time' => '10:00', 'proposed_end_time' => '18:00',
        ])->assertCreated();

        $req = \App\Models\ShiftChangeRequest::first();
        $step = $req->currentApprovalStep();
        $this->actingAs($hrDirector, 'sanctum')
            ->postJson("/api/approvals/{$step->id}/decide", ['approved' => true])
            ->assertOk();

        $shift = $employee->fresh()->activeShift();
        $this->assertNotNull($shift);
        $this->assertSame('10:00', substr($shift->start_time, 0, 5));
    }
}
