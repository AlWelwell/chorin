"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import {
  weekRange,
  weekLabel,
  formatCurrency,
} from "@/lib/week-helpers";
import WeekSummaryCard from "@/components/WeekSummaryCard";
import BottomNav from "@/components/BottomNav";
import type { ChoreCompletion, Chore } from "@/lib/types";

export default function WeekDetailPage() {
  const params = useParams();
  const weekStartStr = params.weekStart as string;
  const weekStartDate = new Date(weekStartStr + "T12:00:00");
  const range = weekRange(weekStartDate);

  const [completions, setCompletions] = useState<ChoreCompletion[]>([]);
  const [chores, setChores] = useState<Chore[]>([]);
  const [userId, setUserId] = useState<string | null>(null);
  const [actionError, setActionError] = useState("");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const supabase = createClient();
  const router = useRouter();

  const loadData = useCallback(async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      router.push("/login");
      return;
    }
    setUserId(user.id);

    const { data: membership } = await supabase
      .from("household_members")
      .select("household_id")
      .eq("user_id", user.id)
      .single();

    if (!membership) {
      router.push("/onboarding");
      return;
    }

    const { data: choresData } = await supabase
      .from("chores")
      .select("*")
      .eq("household_id", membership.household_id);

    setChores(choresData ?? []);

    const choreIds = (choresData ?? []).map((c) => c.id);
    if (choreIds.length > 0) {
      const { data: completionsData } = await supabase
        .from("chore_completions")
        .select("*")
        .in("chore_id", choreIds)
        .gte("date", range.start)
        .lte("date", range.end)
        .order("date", { ascending: true });

      setCompletions(completionsData ?? []);
    } else {
      setCompletions([]);
    }

    setLoading(false);
  }, [supabase, router, range.start, range.end]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const weekTotal = completions.reduce(
    (sum, c) => sum + Number(c.earned_amount),
    0
  );

  const dailyBreakdown = new Map<string, number>();
  completions.forEach((c) => {
    dailyBreakdown.set(
      c.date,
      (dailyBreakdown.get(c.date) ?? 0) + Number(c.earned_amount)
    );
  });

  const choreBreakdown = chores
    .map((chore) => {
      const choreCompletions = completions.filter(
        (c) => c.chore_id === chore.id
      );
      const total = choreCompletions.reduce(
        (sum, c) => sum + Number(c.earned_amount),
        0
      );
      return { name: chore.name, total, count: choreCompletions.length };
    })
    .filter((item) => item.total > 0)
    .sort((a, b) => b.total - a.total);

  const choreNameById = new Map(chores.map((chore) => [chore.id, chore.name]));
  const entries = [...completions].sort((a, b) => {
    if (a.date !== b.date) return b.date.localeCompare(a.date);
    return (b.created_at ?? "").localeCompare(a.created_at ?? "");
  });

  async function deleteCompletion(completion: ChoreCompletion) {
    if (!userId || completion.user_id !== userId) {
      setActionError("You can only delete your own earnings.");
      return;
    }

    if (!window.confirm("Delete this earning entry?")) {
      return;
    }

    setDeletingId(completion.id);
    const { error } = await supabase
      .from("chore_completions")
      .delete()
      .eq("id", completion.id);

    if (error) {
      setActionError(error.message);
      setDeletingId(null);
      return;
    }

    setActionError("");
    setDeletingId(null);
    loadData();
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-950">
        <div className="text-gray-500">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-950 pb-20">
      {/* Header */}
      <div className="bg-gray-900 border-b border-gray-800 px-4 pt-6 pb-4">
        <button
          onClick={() => router.push("/earnings")}
          className="text-blue-400 text-sm mb-2 hover:underline"
        >
          ← Back to Earnings
        </button>
        <h1 className="text-2xl font-bold text-white">Week Detail</h1>
      </div>

      {/* Week Total */}
      <div className="p-4">
        <WeekSummaryCard
          total={weekTotal}
          date={weekStartDate}
          label={weekLabel(weekStartDate)}
        />
      </div>

      {/* Daily Breakdown */}
      {dailyBreakdown.size > 0 && (
        <div className="bg-gray-900 mt-2">
          <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
            By Day
          </h3>
          <div className="divide-y divide-gray-800">
            {Array.from(dailyBreakdown.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([date, total]) => {
                const d = new Date(date + "T12:00:00");
                return (
                  <div
                    key={date}
                    className="px-4 py-3 flex justify-between items-center"
                  >
                    <span className="text-gray-300">
                      {new Intl.DateTimeFormat("en-US", {
                        weekday: "long",
                        month: "short",
                        day: "numeric",
                      }).format(d)}
                    </span>
                    <span className="text-green-400 font-medium">
                      {formatCurrency(total)}
                    </span>
                  </div>
                );
              })}
          </div>
        </div>
      )}

      {/* Per-Chore Breakdown */}
      {choreBreakdown.length > 0 && (
        <div className="bg-gray-900 mt-2">
          <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
            By Chore
          </h3>
          <div className="divide-y divide-gray-800">
            {choreBreakdown.map((item) => (
              <div
                key={item.name}
                className="px-4 py-3 flex justify-between items-center"
              >
                <div>
                  <span className="text-gray-300">{item.name}</span>
                  <span className="text-xs text-gray-500 ml-2">
                    {item.count} time{item.count === 1 ? "" : "s"}
                  </span>
                </div>
                <span className="text-gray-400">
                  {formatCurrency(item.total)}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Individual Entries */}
      {entries.length > 0 && (
        <div className="bg-gray-900 mt-2">
          <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
            Entries
          </h3>
          {actionError && (
            <div className="mx-4 mb-3 rounded-lg bg-red-900/30 text-red-300 text-sm px-3 py-2">
              {actionError}
            </div>
          )}
          <div className="divide-y divide-gray-800">
            {entries.map((completion) => {
              const canDelete = userId === completion.user_id;
              const d = new Date(completion.date + "T12:00:00");
              return (
                <div
                  key={completion.id}
                  className="px-4 py-3 flex items-center justify-between gap-3"
                >
                  <div className="min-w-0">
                    <p className="text-gray-200 truncate">
                      {choreNameById.get(completion.chore_id) ?? "Chore"}
                    </p>
                    <p className="text-xs text-gray-500">
                      {new Intl.DateTimeFormat("en-US", {
                        weekday: "short",
                        month: "short",
                        day: "numeric",
                      }).format(d)}
                      {!canDelete ? " • other member" : ""}
                    </p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-green-400 font-medium">
                      {formatCurrency(Number(completion.earned_amount))}
                    </span>
                    {canDelete && (
                      <button
                        onClick={() => deleteCompletion(completion)}
                        disabled={deletingId === completion.id}
                        className="text-xs text-red-400 hover:text-red-300 disabled:opacity-50"
                      >
                        {deletingId === completion.id ? "Deleting..." : "Delete"}
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Empty state */}
      {completions.length === 0 && (
        <div className="bg-gray-900 mt-2 py-16 text-center text-gray-500">
          <div className="text-4xl mb-3">💰</div>
          <p className="font-medium">No Earnings</p>
          <p className="text-sm mt-1">No chores were completed this week</p>
        </div>
      )}

      <BottomNav />
    </div>
  );
}
