"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import IconPicker from "./IconPicker";
import type { Chore } from "@/lib/types";

interface ChoreFormProps {
  householdId: string;
  chore?: Chore; // If provided, we're editing
  canApprove?: boolean;
  onClose: () => void;
  onSaved: () => void;
}

export default function ChoreForm({
  householdId,
  chore,
  canApprove = false,
  onClose,
  onSaved,
}: ChoreFormProps) {
  const [name, setName] = useState(chore?.name ?? "");
  const [value, setValue] = useState(chore?.value?.toString() ?? "");
  const [icon, setIcon] = useState(chore?.icon ?? "✅");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const supabase = createClient();
  const isEditing = !!chore;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");

    const trimmedName = name.trim().slice(0, 100);
    const parsedValue = parseFloat(value);
    if (!trimmedName) {
      setError("Please enter a chore name.");
      return;
    }
    if (isNaN(parsedValue) || parsedValue <= 0 || parsedValue > 999.99) {
      setError("Please enter a valid dollar amount ($0.01 – $999.99).");
      return;
    }

    setLoading(true);

    if (isEditing) {
      const updatePayload: {
        name: string;
        value: number;
        icon: string;
        validation_status?: "valid";
      } = { name: trimmedName, value: parsedValue, icon };

      if (canApprove) {
        updatePayload.validation_status = "valid";
      }

      const { error: err } = await supabase
        .from("chores")
        .update(updatePayload)
        .eq("id", chore.id);

      if (err) {
        setError(err.message);
        setLoading(false);
        return;
      }
    } else {
      const insertPayload: {
        household_id: string;
        name: string;
        value: number;
        icon: string;
        validation_status?: "valid";
      } = {
        household_id: householdId,
        name: trimmedName,
        value: parsedValue,
        icon,
      };

      if (canApprove) {
        insertPayload.validation_status = "valid";
      }

      const { error: err } = await supabase.from("chores").insert(insertPayload);

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
            {isEditing ? "Edit Chore" : "New Chore"}
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
              Chore Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="e.g. Make bed"
              autoFocus
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Dollar Value
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-gray-500">$</span>
              <input
                type="number"
                step="0.25"
                min="0"
                value={value}
                onChange={(e) => setValue(e.target.value)}
                className="w-full pl-7 pr-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="1.00"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Icon
            </label>
            <IconPicker selected={icon} onSelect={setIcon} />
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
