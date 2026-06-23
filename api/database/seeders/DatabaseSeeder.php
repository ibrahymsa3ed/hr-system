<?php

namespace Database\Seeders;

use App\Models\Branch;
use App\Models\Employee;
use App\Models\Section;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(RoleSeeder::class);

        // One demo user per role so every approval step can be exercised.
        $roleUsers = [];
        foreach (config('hr.roles') as $role) {
            $user = User::firstOrCreate(
                ['email' => "{$role}@hr.test"],
                ['name' => ucwords(str_replace('_', ' ', $role)), 'password' => Hash::make('password')],
            );
            $user->syncRoles([$role]);
            $roleUsers[$role] = $user;
        }

        // Geofence intentionally left null on the demo branch so self check-in
        // works from any location during local testing. Set latitude/longitude
        // + geofence_radius_meters on a branch to enforce a geofence.
        $branch = Branch::firstOrCreate(
            ['code' => 'BR-CAIRO'],
            [
                'name' => 'Cairo Branch', 'name_ar' => 'فرع القاهرة',
                'timezone' => 'Africa/Cairo',
            ],
        );

        $kitchen = Section::firstOrCreate(['main_code' => '10'], ['name' => 'Kitchen', 'name_ar' => 'المطبخ']);
        Section::firstOrCreate(['main_code' => '20'], ['name' => 'Service', 'name_ar' => 'الخدمة']);

        $employee = Employee::firstOrCreate(
            ['full_code' => '10-0001'],
            [
                'user_id' => $roleUsers['employee']->id,
                'branch_id' => $branch->id,
                'section_id' => $kitchen->id,
                'sub_code' => '0001',
                'first_name' => 'Ahmed', 'last_name' => 'Hassan',
                'first_name_ar' => 'أحمد', 'last_name_ar' => 'حسن',
                'date_of_birth' => '1995-04-12', 'hire_date' => '2023-01-15',
                'has_mobile' => true, 'basic_salary' => '8000',
                'medical_insurance' => true, 'social_insurance' => true,
            ],
        );

        $employee->shiftSchedules()->firstOrCreate(
            ['name' => 'Default'],
            [
                'work_days' => [0, 1, 2, 3, 4], 'start_time' => '09:00',
                'end_time' => '17:00', 'break_minutes' => 60,
                'effective_from' => now()->toDateString(), 'is_active' => true,
            ],
        );

        // A phoneless employee whose attendance the supervisor records.
        Employee::firstOrCreate(
            ['full_code' => '10-0002'],
            [
                'branch_id' => $branch->id, 'section_id' => $kitchen->id,
                'sub_code' => '0002', 'first_name' => 'Mona', 'last_name' => 'Ali',
                'first_name_ar' => 'منى', 'last_name_ar' => 'علي',
                'has_mobile' => false, 'basic_salary' => '6000',
            ],
        );
    }
}
