"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { formatCurrency } from "@/lib/week-helpers";
import type { GoalWithProgress } from "@/lib/types";

interface ContributeFormProps {
  goal: GoalWithProgress;
  userId: string;
  onClose: () => void;
  onSaved: () => void;
}

export default function ContributeForm({
  goal,
  userId,
  onClose,
  onSaved,
}: ContributeFormProps) {
  const [amount, setAmount] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const supabase = createClient();

  const remaining = Math.max(0, goal.target_amount - goal.totalSaved);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");

    const parsedAmount = parseFloat(amount);

    if (isNaN(parsedAmount) || parsedAmount < 0.01) {
      setError("Please enter an amount of at least $0.01.");
      return;
    }
    if (parsedAmount > remaining) {
      setError(
        `Max contribution is ${formatCurrency(remaining)} (remaining to goal).`
      );
      return;
    }

    setLoading(true);

    const { error: err } = await supabase
      .from("savings_contributions")
      .insert({
        goal_id: goal.id,
        user_id: userId,
        amount: parsedAmount,
        source: "manual",
        completion_id: null,
      });

    if (err) {
      setError(err.message);
      setLoading(false);
      return;
    }

    onSaved();
  }

  return (
    <div className="fixed inset-0 bg-black/70 flex items-end sm:items-center justify-center z-50">
      <div className="bg-gray-900 w-full sm:max-w-md sm:rounded-xl rounded-t-xl p-6 max-h-[90vh] overflow-y-auto border border-gray-800">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Add Money</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-300 text-2xl leading-none"
          >
            &times;
          </button>
        </div>

        <div className="mb-4 text-center">
          <span className="text-3xl">{goal.icon}</span>
          <p className="text-white font-medium mt-1">{goal.name}</p>
          <p className="text-gray-400 text-sm">
            {formatCurrency(goal.totalSaved)} of{" "}
            {formatCurrency(goal.target_amount)} saved
          </p>
        </div>

        {error && (
          <div className="bg-red-900/30 text-red-400 text-sm p-3 rounded-lg mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Amount
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-gray-500">$</span>
              <input
                type="number"
                step="0.01"
                min="0.01"
                max={remaining}
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full pl-7 pr-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder={remaining.toFixed(2)}
                autoFocus
              />
            </div>
            <p className="text-xs text-gray-500 mt-1">
              {formatCurrency(remaining)} remaining to goal
            </p>
          </div>

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 border border-gray-700 rounded-lg text-gray-300 hover:bg-gray-800 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 py-2 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 transition-colors"
            >
              {loading ? "Adding..." : "Contribute"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
