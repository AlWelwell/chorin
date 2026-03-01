"use client";

import { formatCurrency } from "@/lib/week-helpers";
import type { ChoreWithCompletion } from "@/lib/types";

interface ChoreRowProps {
  chore: ChoreWithCompletion;
  onToggle: (chore: ChoreWithCompletion) => void;
  onEdit: (chore: ChoreWithCompletion) => void;
  onDelete: (chore: ChoreWithCompletion) => void;
  canManage?: boolean;
  toggleDisabled?: boolean;
}

export default function ChoreRow({
  chore,
  onToggle,
  onEdit,
  onDelete,
  canManage = true,
  toggleDisabled = false,
}: ChoreRowProps) {
  return (
    <div className="flex items-center gap-3 py-3 px-4 group">
      {/* Checkbox */}
      <button
        onClick={() => onToggle(chore)}
        disabled={toggleDisabled}
        className={`flex-shrink-0 transition-transform ${
          toggleDisabled ? "opacity-40 cursor-not-allowed" : "active:scale-90"
        }`}
      >
        {chore.completedToday ? (
          <div className="w-7 h-7 rounded-full bg-green-500 flex items-center justify-center">
            <svg
              className="w-4 h-4 text-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={3}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
        ) : (
          <div className="w-7 h-7 rounded-full border-2 border-gray-600" />
        )}
      </button>

      {/* Icon */}
      <span className="text-xl flex-shrink-0">{chore.icon}</span>

      {/* Name */}
      <div className="flex-1 min-w-0">
        <span
          className={`block truncate ${
            chore.completedToday ? "line-through text-gray-500" : "text-gray-100"
          }`}
        >
          {chore.name}
        </span>
        {chore.validation_status === "pending" && (
          <span className="inline-block mt-1 text-[11px] px-2 py-0.5 rounded-full bg-amber-900/40 text-amber-300 border border-amber-700/50">
            Pending approval
          </span>
        )}
      </div>

      {/* Value */}
      <span
        className={`text-sm font-medium ${
          chore.completedToday ? "text-green-400" : "text-gray-500"
        }`}
      >
        {formatCurrency(chore.value)}
      </span>

      {/* Actions (visible on hover/focus) */}
      {canManage && (
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={() => onEdit(chore)}
            className="p-1 text-gray-500 hover:text-orange-400"
            title="Edit"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
            </svg>
          </button>
          <button
            onClick={() => onDelete(chore)}
            className="p-1 text-gray-500 hover:text-red-400"
            title="Delete"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </div>
      )}
    </div>
  );
}
