"use client";

import { formatCurrency } from "@/lib/week-helpers";
import type { GoalWithProgress } from "@/lib/types";

interface GoalCardProps {
  goal: GoalWithProgress;
  onContribute: (goal: GoalWithProgress) => void;
  onEdit: (goal: GoalWithProgress) => void;
  onArchive: (goal: GoalWithProgress) => void;
}

export default function GoalCard({
  goal,
  onContribute,
  onEdit,
  onArchive,
}: GoalCardProps) {
  return (
    <div className="bg-gray-900 rounded-xl border border-gray-800 p-4">
      {/* Top row: icon, name, action buttons */}
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2 flex-1 min-w-0">
          <span className="text-2xl flex-shrink-0">{goal.icon}</span>
          <span className="font-medium text-white truncate">{goal.name}</span>
        </div>
        <div className="flex gap-1 flex-shrink-0">
          <button
            onClick={() => onEdit(goal)}
            className="p-1 text-gray-500 hover:text-orange-400"
            title="Edit"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
              />
            </svg>
          </button>
          <button
            onClick={() => onArchive(goal)}
            className="p-1 text-gray-500 hover:text-red-400"
            title="Archive"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </button>
        </div>
      </div>

      {/* Progress bar or complete state */}
      {goal.isComplete ? (
        <p className="text-green-400 font-medium mt-2 text-sm">
          Goal reached! 🎉
        </p>
      ) : (
        <div className="w-full bg-gray-700 rounded-full h-2 mt-3">
          <div
            className="bg-green-500 h-2 rounded-full transition-all duration-300"
            style={{ width: `${goal.progressPercent}%` }}
          />
        </div>
      )}

      {/* Dollar amounts + auto badge + contribute button */}
      <div className="flex items-center justify-between mt-2">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-sm text-gray-300">
            {formatCurrency(goal.totalSaved)} / {formatCurrency(goal.target_amount)}
          </span>
          {goal.auto_percent > 0 && (
            <span className="text-xs bg-blue-900/40 text-blue-300 px-2 py-0.5 rounded-full border border-blue-800">
              {goal.auto_percent}% auto
            </span>
          )}
        </div>
        {!goal.isComplete && (
          <button
            onClick={() => onContribute(goal)}
            className="text-xs bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-lg transition-colors"
          >
            + Add Money
          </button>
        )}
      </div>
    </div>
  );
}
