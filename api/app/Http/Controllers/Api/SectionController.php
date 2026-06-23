<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Section;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SectionController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(Section::withCount('employees')->orderBy('main_code')->get());
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(Section::create($this->validated($request)), 201);
    }

    public function show(Section $section): JsonResponse
    {
        return response()->json($section->loadCount('employees'));
    }

    public function update(Request $request, Section $section): JsonResponse
    {
        $section->update($this->validated($request, $section->id));

        return response()->json($section);
    }

    public function destroy(Section $section): JsonResponse
    {
        $section->delete();

        return response()->json(null, 204);
    }

    private function validated(Request $request, ?int $id = null): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'name_ar' => ['nullable', 'string', 'max:255'],
            'main_code' => ['required', 'string', 'max:20', 'unique:sections,main_code'.($id ? ",{$id}" : '')],
            'description' => ['nullable', 'string'],
            'is_active' => ['boolean'],
        ]);
    }
}
