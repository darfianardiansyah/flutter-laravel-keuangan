<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->transactions()
            ->orderByDesc('date')
            ->orderByDesc('id');

        if ($request->filled('month')) {
            $query->forMonth($request->string('month')->toString());
        }

        return response()->json(['data' => $query->get()]);
    }

    public function summary(Request $request): JsonResponse
    {
        $query = $request->user()->transactions();

        if ($request->filled('month')) {
            $query->forMonth($request->string('month')->toString());
        }

        $transactions = $query->get();
        $income = $transactions->where('type', 'income')->sum('amount');
        $expense = $transactions->where('type', 'expense')->sum('amount');

        return response()->json([
            'data' => [
                'income' => (float) $income,
                'expense' => (float) $expense,
                'balance' => (float) ($income - $expense),
            ],
        ]);
    }

    public function statistics(Request $request): JsonResponse
    {
        $query = $request->user()->transactions();

        if ($request->filled('month')) {
            $query->forMonth($request->string('month')->toString());
        }

        $transactions = $query->get();

        return response()->json([
            'data' => [
                'month' => $request->string('month')->toString() ?: null,
                'income' => $this->categoryStatistics($transactions, 'income'),
                'expense' => $this->categoryStatistics($transactions, 'expense'),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $transaction = $request->user()
            ->transactions()
            ->create($this->validated($request));

        return response()->json(['data' => $transaction], 201);
    }

    public function show(Request $request, Transaction $transaction): JsonResponse
    {
        if ($transaction->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return response()->json(['data' => $transaction]);
    }

    public function update(Request $request, Transaction $transaction): JsonResponse
    {
        if ($transaction->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $transaction->update($this->validated($request));

        return response()->json(['data' => $transaction->fresh()]);
    }

    public function destroy(Request $request, Transaction $transaction): JsonResponse
    {
        if ($transaction->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $transaction->delete();

        return response()->json(['message' => 'Transaksi berhasil dihapus']);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'type' => ['required', 'in:income,expense'],
            'category' => ['required', 'string', 'max:100'],
            'date' => ['required', 'date'],
            'note' => ['nullable', 'string'],
        ]);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Transaction>  $transactions
     * @return array{total: float, categories: array<int, array{category: string, total: float, count: int, percentage: float}>}
     */
    private function categoryStatistics($transactions, string $type): array
    {
        $filtered = $transactions->where('type', $type);
        $total = (float) $filtered->sum('amount');

        if ($total <= 0) {
            return [
                'total' => 0.0,
                'categories' => [],
            ];
        }

        $categories = $filtered
            ->groupBy('category')
            ->map(function ($items, string $category) use ($total): array {
                $categoryTotal = (float) $items->sum('amount');

                return [
                    'category' => $category,
                    'total' => $categoryTotal,
                    'count' => $items->count(),
                    'percentage' => round(($categoryTotal / $total) * 100, 2),
                ];
            })
            ->sortByDesc('total')
            ->values()
            ->all();

        return [
            'total' => $total,
            'categories' => $categories,
        ];
    }
}
