<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PerformanceReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PerformanceReviewController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = PerformanceReview::with('employee:id,full_code,first_name,last_name', 'reviewer:id,name');

        // Employees see only their own reviews.
        if ($request->user()->hasRole('employee') && ! $request->user()->hasAnyRole(['hr_admin', 'hr_director', 'section_manager'])) {
            $query->where('employee_id', optional($request->user()->employee)->id);
        }
        $query->when($request->employee_id, fn ($q, $v) => $q->where('employee_id', $v));

        return response()->json($query->latest()->paginate($request->integer('per_page', 25)));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $data['reviewer_user_id'] = $request->user()->id;

        return response()->json(PerformanceReview::create($data), 201);
    }

    public function show(PerformanceReview $performanceReview): JsonResponse
    {
        return response()->json($performanceReview->load('employee', 'reviewer:id,name'));
    }

    public function update(Request $request, PerformanceReview $performanceReview): JsonResponse
    {
        $performanceReview->update($this->validated($request, true));

        return response()->json($performanceReview);
    }

    private function validated(Request $request, bool $partial = false): array
    {
        $req = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'employee_id' => [$req, 'exists:employees,id'],
            'period' => [$req, 'string', 'max:20'],
            'kpis' => ['nullable', 'array'],
            'goals' => ['nullable', 'array'],
            'manager_evaluation' => ['nullable', 'string'],
            'score' => ['nullable', 'numeric', 'between:0,100'],
            'turnover_risk' => ['nullable', 'in:low,medium,high'],
            'status' => ['nullable', 'in:draft,submitted,acknowledged'],
        ]);
    }
}
