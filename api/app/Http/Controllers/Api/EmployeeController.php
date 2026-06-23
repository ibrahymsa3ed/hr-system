<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\Section;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Intervention\Image\Laravel\Facades\Image;

class EmployeeController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $employees = Employee::query()
            ->with(['section:id,name,name_ar,main_code', 'branch:id,name,name_ar'])
            ->when($request->section_id, fn ($q, $v) => $q->where('section_id', $v))
            ->when($request->branch_id, fn ($q, $v) => $q->where('branch_id', $v))
            ->when($request->status, fn ($q, $v) => $q->where('employment_status', $v))
            ->when($request->search, fn ($q, $v) => $q->where(fn ($w) => $w
                ->where('first_name', 'like', "%{$v}%")
                ->orWhere('last_name', 'like', "%{$v}%")
                ->orWhere('full_code', 'like', "%{$v}%")))
            ->orderBy('full_code')
            ->paginate($request->integer('per_page', 25));

        return response()->json($employees);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $data['full_code'] = $this->buildFullCode($data['section_id'], $data['sub_code']);

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $this->storeCompressedPhoto($request);
        }

        if (empty($data['user_id'])) {
            $user = $this->createUserForEmployee($data, $request);
            $data['user_id'] = $user->id;
        }

        unset($data['username'], $data['password']);

        $employee = Employee::create($data);

        $result = $this->withSecure($employee)->toArray();
        if (isset($user)) {
            $result['generated_credentials'] = [
                'username' => $user->email,
                'password' => $request->input('password', $data['sub_code']),
            ];
        }

        return response()->json($result, 201);
    }

    public function show(Employee $employee): JsonResponse
    {
        $employee->load(['section', 'branch', 'documents', 'shiftSchedules', 'leaveLedgers']);

        return response()->json($this->withSecure($employee));
    }

    public function update(Request $request, Employee $employee): JsonResponse
    {
        $data = $this->validated($request, $employee);

        if (isset($data['section_id']) || isset($data['sub_code'])) {
            $data['full_code'] = $this->buildFullCode(
                $data['section_id'] ?? $employee->section_id,
                $data['sub_code'] ?? $employee->sub_code,
            );
        }

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $this->storeCompressedPhoto($request);
        }

        $employee->update($data);

        return response()->json($this->withSecure($employee));
    }

    public function destroy(Employee $employee): JsonResponse
    {
        $employee->delete();

        return response()->json(null, 204);
    }

    private function createUserForEmployee(array $data, Request $request): User
    {
        $username = $request->input('username')
            ?? $data['email']
            ?? strtolower($data['first_name'] . '.' . $data['last_name']);

        $password = $request->input('password', $data['sub_code']);

        $user = User::create([
            'name' => trim($data['first_name'] . ' ' . $data['last_name']),
            'email' => $username,
            'password' => Hash::make($password),
        ]);

        $user->assignRole('employee');

        return $user;
    }

    private function buildFullCode(int $sectionId, string $subCode): string
    {
        $mainCode = Section::findOrFail($sectionId)->main_code;

        return "{$mainCode}-{$subCode}";
    }

    /** Reveal salary/national id only to authorized roles. */
    private function withSecure(Employee $employee): Employee
    {
        if (auth()->user()?->hasAnyRole(['hr_admin', 'hr_director', 'finance'])) {
            $employee->makeVisible(['basic_salary', 'national_id']);
        }

        return $employee;
    }

    private function storeCompressedPhoto(Request $request): string
    {
        $path = 'employee-photos/' . uniqid('emp_') . '.jpg';
        $image = Image::read($request->file('photo'))
            ->scaleDown(800, 800)
            ->toJpeg(80);
        \Storage::disk('public')->put($path, (string) $image);

        return $path;
    }

    private function validated(Request $request, ?Employee $employee = null): array
    {
        $id = $employee?->id;

        return $request->validate([
            'user_id' => ['nullable', 'exists:users,id'],
            'username' => ['nullable', 'string', 'max:255', 'unique:users,email'],
            'password' => ['nullable', 'string', 'min:3'],
            'branch_id' => [$id ? 'sometimes' : 'required', 'exists:branches,id'],
            'section_id' => [$id ? 'sometimes' : 'required', 'exists:sections,id'],
            'sub_code' => [$id ? 'sometimes' : 'required', 'string', 'max:50'],
            'first_name' => [$id ? 'sometimes' : 'required', 'string', 'max:255'],
            'last_name' => [$id ? 'sometimes' : 'required', 'string', 'max:255'],
            'first_name_ar' => ['nullable', 'string', 'max:255'],
            'last_name_ar' => ['nullable', 'string', 'max:255'],
            'national_id' => ['nullable', 'string', 'max:50'],
            'date_of_birth' => ['nullable', 'date'],
            'hire_date' => ['nullable', 'date'],
            'gender' => ['nullable', 'in:male,female'],
            'marital_status' => ['nullable', 'string', 'max:30'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:255'],
            'has_mobile' => ['boolean'],
            'basic_salary' => ['nullable', 'numeric', 'min:0'],
            'medical_insurance' => ['boolean'],
            'medical_insurance_no' => ['nullable', 'string', 'max:100'],
            'social_insurance' => ['boolean'],
            'social_insurance_no' => ['nullable', 'string', 'max:100'],
            'employment_status' => ['nullable', 'in:active,suspended,resigned,terminated'],
            'photo' => ['nullable', 'image', 'max:5120'],
        ]);
    }
}
