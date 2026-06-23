<?php

namespace App\Http\Controllers\Api\Recruitment;

use App\Http\Controllers\Controller;
use App\Models\Candidate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CandidateEvaluationController extends Controller
{
    public function store(Request $request, Candidate $candidate): JsonResponse
    {
        $data = $request->validate([
            'criteria' => ['nullable', 'array'],
            'score' => ['nullable', 'numeric', 'between:0,100'],
            'recommendation' => ['nullable', 'in:hire,hold,reject'],
            'notes' => ['nullable', 'string'],
        ]);
        $data['evaluator_user_id'] = $request->user()->id;

        $evaluation = $candidate->evaluations()->create($data);
        $candidate->update(['stage' => 'evaluated']);

        return response()->json($evaluation, 201);
    }
}
