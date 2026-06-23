<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\EmployeeDocument;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** "Remaining papers" checklist per employee. */
class EmployeeDocumentController extends Controller
{
    public function index(Employee $employee): JsonResponse
    {
        return response()->json($employee->documents()->orderBy('name')->get());
    }

    public function store(Request $request, Employee $employee): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'name_ar' => ['nullable', 'string', 'max:255'],
            'is_submitted' => ['boolean'],
            'notes' => ['nullable', 'string'],
            'file' => ['nullable', 'file', 'max:10240'],
        ]);

        if ($request->hasFile('file')) {
            $data['file_path'] = $request->file('file')->store('employee-docs', 'public');
        }

        return response()->json($employee->documents()->create($data), 201);
    }

    public function update(Request $request, Employee $employee, EmployeeDocument $document): JsonResponse
    {
        abort_unless($document->employee_id === $employee->id, 404);

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'name_ar' => ['nullable', 'string', 'max:255'],
            'is_submitted' => ['boolean'],
            'notes' => ['nullable', 'string'],
            'file' => ['nullable', 'file', 'max:10240'],
        ]);

        if ($request->hasFile('file')) {
            $data['file_path'] = $request->file('file')->store('employee-docs', 'public');
        }

        $document->update($data);

        return response()->json($document);
    }

    public function destroy(Employee $employee, EmployeeDocument $document): JsonResponse
    {
        abort_unless($document->employee_id === $employee->id, 404);
        $document->delete();

        return response()->json(null, 204);
    }
}
