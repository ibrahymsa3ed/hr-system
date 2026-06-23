<?php

namespace App\Http\Controllers\Api\Recruitment;

use App\Http\Controllers\Controller;
use App\Models\Candidate;
use App\Models\Employee;
use App\Models\Section;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CandidateController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Candidate::with('jobVacancy:id,title')
                ->when($request->job_vacancy_id, fn ($q, $v) => $q->where('job_vacancy_id', $v))
                ->when($request->stage, fn ($q, $v) => $q->where('stage', $v))
                ->latest()->paginate($request->integer('per_page', 25))
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'job_vacancy_id' => ['required', 'exists:job_vacancies,id'],
            'name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'email'],
            'phone' => ['nullable', 'string', 'max:30'],
        ]);

        return response()->json(Candidate::create($data), 201);
    }

    public function show(Candidate $candidate): JsonResponse
    {
        return response()->json($candidate->load('jobVacancy', 'interviews', 'evaluations.evaluator:id,name'));
    }

    public function update(Request $request, Candidate $candidate): JsonResponse
    {
        $candidate->update($request->validate([
            'stage' => ['required', 'in:applied,interview,evaluated,hired,rejected'],
        ]));

        return response()->json($candidate);
    }

    /** Convert an accepted candidate into an Employee. */
    public function hire(Request $request, Candidate $candidate): JsonResponse
    {
        $data = $request->validate([
            'branch_id' => ['required', 'exists:branches,id'],
            'section_id' => ['required', 'exists:sections,id'],
            'sub_code' => ['required', 'string', 'max:50'],
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'hire_date' => ['nullable', 'date'],
            'basic_salary' => ['nullable', 'numeric', 'min:0'],
        ]);

        return DB::transaction(function () use ($candidate, $data) {
            $mainCode = Section::findOrFail($data['section_id'])->main_code;
            $data['full_code'] = "{$mainCode}-{$data['sub_code']}";
            $data['email'] = $candidate->email;
            $data['phone'] = $candidate->phone;

            $employee = Employee::create($data);
            $candidate->update(['stage' => 'hired']);

            return response()->json(['employee' => $employee, 'candidate' => $candidate], 201);
        });
    }
}
