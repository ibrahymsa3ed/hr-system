<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BranchController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(Branch::withCount('employees')->orderBy('name')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $branch = Branch::create($this->validated($request));

        return response()->json($branch, 201);
    }

    public function show(Branch $branch): JsonResponse
    {
        return response()->json($branch->loadCount('employees'));
    }

    public function update(Request $request, Branch $branch): JsonResponse
    {
        $branch->update($this->validated($request, $branch->id));

        return response()->json($branch);
    }

    public function destroy(Branch $branch): JsonResponse
    {
        $branch->delete();

        return response()->json(null, 204);
    }

    private function validated(Request $request, ?int $id = null): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'name_ar' => ['nullable', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:50', 'unique:branches,code'.($id ? ",{$id}" : '')],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'geofence_radius_meters' => ['nullable', 'integer', 'min:10', 'max:5000'],
            'timezone' => ['nullable', 'string', 'max:64'],
            'is_active' => ['boolean'],
        ]);
    }
}
