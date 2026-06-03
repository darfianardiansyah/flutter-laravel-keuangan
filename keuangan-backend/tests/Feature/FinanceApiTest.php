<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FinanceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_creates_user_and_returns_token(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Budi',
            'email' => 'budi@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response
            ->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']])
            ->assertJsonPath('user.email', 'budi@example.com');
    }

    public function test_login_returns_token_and_rejects_wrong_password(): void
    {
        User::factory()->create([
            'email' => 'budi@example.com',
            'password' => 'password123',
        ]);

        $this->postJson('/api/login', [
            'email' => 'budi@example.com',
            'password' => 'salah',
        ])->assertUnprocessable();

        $this->postJson('/api/login', [
            'email' => 'budi@example.com',
            'password' => 'password123',
        ])->assertOk()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);
    }

    public function test_protected_endpoints_require_token(): void
    {
        $this->getJson('/api/transactions')->assertUnauthorized();
        $this->getJson('/api/transactions/summary')->assertUnauthorized();
        $this->getJson('/api/transactions/statistics')->assertUnauthorized();
        $this->postJson('/api/logout')->assertUnauthorized();
    }

    public function test_user_can_create_list_filter_and_summarize_own_transactions(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/transactions', [
            'title' => 'Gaji',
            'amount' => 5000000,
            'type' => 'income',
            'category' => 'Gaji',
            'date' => '2026-06-01',
            'note' => 'Gaji bulanan',
        ])->assertCreated()
            ->assertJsonPath('data.title', 'Gaji');

        $this->postJson('/api/transactions', [
            'title' => 'Makan siang',
            'amount' => 25000,
            'type' => 'expense',
            'category' => 'Makanan',
            'date' => '2026-06-03',
        ])->assertCreated();

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Transaksi bulan lain',
            'amount' => 100000,
            'type' => 'expense',
            'category' => 'Lainnya',
            'date' => '2026-05-20',
        ]);

        $this->getJson('/api/transactions?month=2026-06')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonFragment(['title' => 'Gaji'])
            ->assertJsonFragment(['title' => 'Makan siang'])
            ->assertJsonMissing(['title' => 'Transaksi bulan lain']);

        $this->getJson('/api/transactions/summary?month=2026-06')
            ->assertOk()
            ->assertJsonPath('data.income', 5000000)
            ->assertJsonPath('data.expense', 25000)
            ->assertJsonPath('data.balance', 4975000);
    }

    public function test_user_can_update_and_delete_only_own_transactions(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        Sanctum::actingAs($user);

        $ownTransaction = Transaction::create([
            'user_id' => $user->id,
            'title' => 'Belanja',
            'amount' => 150000,
            'type' => 'expense',
            'category' => 'Belanja',
            'date' => '2026-06-02',
        ]);

        $otherTransaction = Transaction::create([
            'user_id' => $otherUser->id,
            'title' => 'Rahasia user lain',
            'amount' => 999000,
            'type' => 'expense',
            'category' => 'Lainnya',
            'date' => '2026-06-02',
        ]);

        $this->putJson("/api/transactions/{$ownTransaction->id}", [
            'title' => 'Belanja bulanan',
            'amount' => 175000,
            'type' => 'expense',
            'category' => 'Belanja',
            'date' => '2026-06-04',
            'note' => 'Diskon',
        ])->assertOk()
            ->assertJsonPath('data.title', 'Belanja bulanan');

        $this->putJson("/api/transactions/{$otherTransaction->id}", [
            'title' => 'Ambil alih',
            'amount' => 1,
            'type' => 'income',
            'category' => 'Lainnya',
            'date' => '2026-06-04',
        ])->assertForbidden();

        $this->deleteJson("/api/transactions/{$otherTransaction->id}")
            ->assertForbidden();

        $this->deleteJson("/api/transactions/{$ownTransaction->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Transaksi berhasil dihapus');
    }

    public function test_user_can_see_monthly_statistics_grouped_by_category(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        Sanctum::actingAs($user);

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Gaji utama',
            'amount' => 5000000,
            'type' => 'income',
            'category' => 'Gaji',
            'date' => '2026-06-01',
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Bonus project',
            'amount' => 1000000,
            'type' => 'income',
            'category' => 'Bonus',
            'date' => '2026-06-05',
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Sarapan',
            'amount' => 250000,
            'type' => 'expense',
            'category' => 'Makanan',
            'date' => '2026-06-03',
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Makan malam',
            'amount' => 500000,
            'type' => 'expense',
            'category' => 'Makanan',
            'date' => '2026-06-10',
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Bensin',
            'amount' => 500000,
            'type' => 'expense',
            'category' => 'Transportasi',
            'date' => '2026-06-11',
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'title' => 'Bulan lain',
            'amount' => 999000,
            'type' => 'expense',
            'category' => 'Lainnya',
            'date' => '2026-05-11',
        ]);

        Transaction::create([
            'user_id' => $otherUser->id,
            'title' => 'Data user lain',
            'amount' => 888000,
            'type' => 'income',
            'category' => 'Gaji',
            'date' => '2026-06-01',
        ]);

        $this->getJson('/api/transactions/statistics?month=2026-06')
            ->assertOk()
            ->assertJsonPath('data.month', '2026-06')
            ->assertJsonPath('data.income.total', 6000000)
            ->assertJsonPath('data.income.categories.0.category', 'Gaji')
            ->assertJsonPath('data.income.categories.0.total', 5000000)
            ->assertJsonPath('data.income.categories.0.count', 1)
            ->assertJsonPath('data.income.categories.0.percentage', 83.33)
            ->assertJsonPath('data.income.categories.1.category', 'Bonus')
            ->assertJsonPath('data.income.categories.1.percentage', 16.67)
            ->assertJsonPath('data.expense.total', 1250000)
            ->assertJsonPath('data.expense.categories.0.category', 'Makanan')
            ->assertJsonPath('data.expense.categories.0.total', 750000)
            ->assertJsonPath('data.expense.categories.0.count', 2)
            ->assertJsonPath('data.expense.categories.0.percentage', 60)
            ->assertJsonPath('data.expense.categories.1.category', 'Transportasi')
            ->assertJsonPath('data.expense.categories.1.percentage', 40)
            ->assertJsonMissing(['title' => 'Bulan lain'])
            ->assertJsonMissing(['title' => 'Data user lain']);
    }

    public function test_statistics_return_empty_categories_when_month_has_no_data(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/transactions/statistics?month=2026-12')
            ->assertOk()
            ->assertJsonPath('data.income.total', 0)
            ->assertJsonPath('data.income.categories', [])
            ->assertJsonPath('data.expense.total', 0)
            ->assertJsonPath('data.expense.categories', []);
    }
}
