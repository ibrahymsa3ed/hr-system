<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\ShiftSchedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftScheduleController extends Controller
{
    public function index(Employee $employee): JsonResponse
    {
        return response()->json($employee->shiftSchedules()->orderByDesc('effective_from')->get());
    }

    public function store(Request $request, Employee $employee): JsonResponse
    {
        $data = $request->validate([
            'name' => ['nullable', 'string', 'max:100'],
            'work_days' => ['required', 'array'],
            'work_days.*' => ['integer', 'between:0,6'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i'],
            'break_minutes' => ['nullable', 'integer', 'min:0'],
            'effective_from' => ['nullable', 'date'],
            'is_active' => ['boolean'],
        ]);

        // A newly activated schedule supersedes prior active ones.
        if ($data['is_active'] ?? true) {
            $employee->shiftSchedules()->update(['is_active' => false]);
        }

        $schedule = $employee->shiftSchedules()->create($data);

        return response()->json($schedule, 201);
    }

    public function destroy(Employee $employee, ShiftSchedule $shift): JsonResponse
    {
        abort_unless($shift->employee_id === $employee->id, 404);
        $shift->delete();

        return response()->json(null, 204);
    }
}
