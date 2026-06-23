<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ResignationRequest;
use App\Services\ApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ResignationRequestController extends Controller
{
    public function __construct(private readonly ApprovalService $approvals) {}

    public function index(Request $request): JsonResponse
    {
        $query = ResignationRequest::with('employee:id,full_code,first_name,last_name', 'approvalSteps');

        if ($request->user()->hasRole('employee') && ! $request->user()->hasAnyRole(['hr_admin', 'hr_director'])) {
            $query->where('employee_id', optional($request->user()->employee)->id);
        }

        return response()->json($query->latest()->paginate($request->integer('per_page', 25)));
    }

    public function store(Request $request): JsonResponse
    {
        $employee = $request->user()->employee ?? abort(422, __('messages.not_an_employee'));

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:1000'],
            'last_working_day' => ['nullable', 'date', 'after:today'],
        ]);
        $data['employee_id'] = $employee->id;

        $req = ResignationRequest::create($data);
        $this->approvals->start($req, ResignationRequest::APPROVAL_TYPE);

        return response()->json([
            'message' => __('messages.request_submitted'),
            'request' => $req->load('approvalSteps'),
        ], 201);
    }
}
