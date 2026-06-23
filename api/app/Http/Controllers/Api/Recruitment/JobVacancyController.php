<?php

namespace App\Http\Controllers\Api\Recruitment;

use App\Http\Controllers\Controller;
use App\Models\JobVacancy;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobVacancyController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            JobVacancy::with('branch:id,name', 'section:id,name')
                ->withCount('candidates')
                ->when($request->status, fn ($q, $v) => $q->where('status', $v))
                ->latest()->paginate($request->integer('per_page', 25))
        );
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(JobVacancy::create($this->validated($request)), 201);
    }

    public function show(JobVacancy $jobVacancy): JsonResponse
    {
        return response()->json($jobVacancy->load('candidates', 'branch:id,name', 'section:id,name'));
    }

    public function update(Request $request, JobVacancy $jobVacancy): JsonResponse
    {
        $jobVacancy->update($this->validated($request, true));

        return response()->json($jobVacancy);
    }

    public function destroy(JobVacancy $jobVacancy): JsonResponse
    {
        $jobVacancy->delete();

        return response()->json(null, 204);
    }

    private function validated(Request $request, bool $partial = false): array
    {
        $req = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'title' => [$req, 'string', 'max:255'],
            'title_ar' => ['nullable', 'string', 'max:255'],
            'branch_id' => ['nullable', 'exists:branches,id'],
            'section_id' => ['nullable', 'exists:sections,id'],
            'description' => ['nullable', 'string'],
            'openings' => ['nullable', 'integer', 'min:1'],
            'status' => ['nullable', 'in:open,closed'],
        ]);
    }
}
