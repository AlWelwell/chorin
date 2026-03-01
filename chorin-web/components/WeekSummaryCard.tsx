"use client";

import { formatCurrency, weekLabel } from "@/lib/week-helpers";

interface WeekSummaryCardProps {
  total: number;
  date?: Date;
  label?: string;
}

export default function WeekSummaryCard({
  total,
  date = new Date(),
  label,
}: WeekSummaryCardProps) {
  return (
    <div className="bg-gray-900 rounded-xl p-6 text-center border border-gray-800">
      <p className="text-sm text-gray-400">{label ?? "This Week"}</p>
      <p className="text-4xl font-bold text-green-400 mt-2">
        {formatCurrency(total)}
      </p>
      <p className="text-xs text-gray-500 mt-1">{weekLabel(date)}</p>
    </div>
  );
}
