<?php

namespace App\Http\Controllers\Api\Recruitment;

use App\Http\Controllers\Controller;
use App\Models\Candidate;
use App\Models\Interview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InterviewController extends Controller
{
    public function store(Request $request, Candidate $candidate): JsonResponse
    {
        $data = $request->validate([
            'scheduled_at' => ['nullable', 'date'],
            'interviewer_user_id' => ['nullable', 'exists:users,id'],
            'mode' => ['nullable', 'in:onsite,phone,video'],
            'notes' => ['nullable', 'string'],
            'status' => ['nullable', 'in:scheduled,done,cancelled'],
        ]);

        $interview = $candidate->interviews()->create($data);
        $candidate->update(['stage' => 'interview']);

        return response()->json($interview, 201);
    }

    public function update(Request $request, Interview $interview): JsonResponse
    {
        $interview->update($request->validate([
            'scheduled_at' => ['nullable', 'date'],
            'interviewer_user_id' => ['nullable', 'exists:users,id'],
            'mode' => ['nullable', 'in:onsite,phone,video'],
            'notes' => ['nullable', 'string'],
            'status' => ['nullable', 'in:scheduled,done,cancelled'],
        ]));

        return response()->json($interview);
    }
}
