"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import IconPicker from "./IconPicker";
import type { SavingsGoal } from "@/lib/types";

const SAVINGS_ICONS = [
  "🎯", "🎮", "🚲", "✈️", "👟", "🎸",
  "📱", "🏀", "⚽", "🎨", "🎭", "🏖️",
  "🐕", "📷", "🎹", "🚀", "🎠", "💎",
  "🏕️", "🎁", "🌈", "🦄", "🤖", "⭐",
];

interface GoalFormProps {
  householdId: string;
  userId: string;
  goal?: SavingsGoal;
  onClose: () => void;
  onSaved: () => void;
}

export default function GoalForm({
  householdId,
  userId,
  goal,
  onClose,
  onSaved,
}: GoalFormProps) {
  const [name, setName] = useState(goal?.name ?? "");
  const [targetAmount, setTargetAmount] = useState(
    goal?.target_amount?.toString() ?? ""
  );
  const [autoPercent, setAutoPercent] = useState(
    goal?.auto_percent?.toString() ?? "0"
  );
  const [icon, setIcon] = useState(goal?.icon ?? "🎯");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const supabase = createClient();
  const isEditing = !!goal;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");

    const trimmedName = name.trim().slice(0, 100);
    const parsedTarget = parseFloat(targetAmount);
    const parsedPercent = parseInt(autoPercent, 10);

    if (!trimmedName) {
      setError("Please enter a goal name.");
      return;
    }
    if (isNaN(parsedTarget) || parsedTarget < 0.01 || parsedTarget > 9999.99) {
      setError("Please enter a valid target amount ($0.01 – $9,999.99).");
      return;
    }
    if (isNaN(parsedPercent) || parsedPercent < 0 || parsedPercent > 100) {
      setError("Auto-save must be 0–100%.");
      return;
    }

    setLoading(true);

    if (isEditing) {
      const { error: err } = await supabase
        .from("savings_goals")
        .update({
          name: trimmedName,
          target_amount: parsedTarget,
          icon,
          auto_percent: parsedPercent,
        })
        .eq("id", goal.id);

      if (err) {
        setError(err.message);
        setLoading(false);
        return;
      }
    } else {
      const { error: err } = await supabase.from("savings_goals").insert({
        household_id: householdId,
        user_id: userId,
        name: trimmedName,
        target_amount: parsedTarget,
        icon,
        auto_percent: parsedPercent,
      });

      if (err) {
        setError(err.message);
        setLoading(false);
        return;
      }
    }

    onSaved();
    onClose();
  }

  return (
    <div className="fixed inset-0 bg-black/70 flex items-end sm:items-center justify-center z-50">
      <div className="bg-gray-900 w-full sm:max-w-md sm:rounded-xl rounded-t-xl p-6 max-h-[90vh] overflow-y-auto border border-gray-800">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">
            {isEditing ? "Edit Goal" : "New Savings Goal"}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-300 text-2xl leading-none"
          >
            &times;
          </button>
        </div>

        {error && (
          <div className="bg-red-900/30 text-red-400 text-sm p-3 rounded-lg mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Goal Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="e.g. New bike"
              autoFocus
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Target Amount
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-gray-500">$</span>
              <input
                type="number"
                step="0.01"
                min="0.01"
                max="9999.99"
                value={targetAmount}
                onChange={(e) => setTargetAmount(e.target.value)}
                className="w-full pl-7 pr-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="40.00"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Auto-Save %
            </label>
            <p className="text-xs text-gray-500 mb-1">
              Percentage of each chore earned that goes here automatically
            </p>
            <div className="relative">
              <input
                type="number"
                step="1"
                min="0"
                max="100"
                value={autoPercent}
                onChange={(e) => setAutoPercent(e.target.value)}
                className="w-full pr-8 px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="0"
              />
              <span className="absolute right-3 top-2 text-gray-500">%</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Icon
            </label>
            <IconPicker selected={icon} onSelect={setIcon} icons={SAVINGS_ICONS} />
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
              className="flex-1 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
            >
              {loading ? "Saving..." : "Save"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
