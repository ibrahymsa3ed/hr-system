<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CompensationRecordController extends Controller
{
    public function index(Employee $employee): JsonResponse
    {
        $records = $employee->compensationRecords()->latest('effective_date')->get()
            ->each->makeVisible('basic_salary');

        return response()->json($records);
    }

    public function store(Request $request, Employee $employee): JsonResponse
    {
        $data = $request->validate([
            'basic_salary' => ['nullable', 'numeric', 'min:0'],
            'medical_insurance' => ['boolean'],
            'social_insurance' => ['boolean'],
            'medical_insurance_no' => ['nullable', 'string', 'max:100'],
            'social_insurance_no' => ['nullable', 'string', 'max:100'],
            'effective_date' => ['required', 'date'],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $record = $employee->compensationRecords()->create($data);

        // Keep the denormalized "current" values on the employee in sync.
        $employee->update(array_filter([
            'basic_salary' => $data['basic_salary'] ?? null,
            'medical_insurance' => $data['medical_insurance'] ?? false,
            'social_insurance' => $data['social_insurance'] ?? false,
            'medical_insurance_no' => $data['medical_insurance_no'] ?? null,
            'social_insurance_no' => $data['social_insurance_no'] ?? null,
        ], fn ($v) => $v !== null));

        return response()->json($record->makeVisible('basic_salary'), 201);
    }
}
