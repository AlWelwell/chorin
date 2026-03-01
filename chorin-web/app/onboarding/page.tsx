"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import Logo from "@/components/Logo";

export default function OnboardingPage() {
  const [mode, setMode] = useState<"choose" | "create" | "join">("choose");
  const [householdName, setHouseholdName] = useState("");
  const [inviteCode, setInviteCode] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setError("Not authenticated");
      setLoading(false);
      return;
    }

    const { data: households, error: hError } = await supabase.rpc(
      "create_household_with_parent",
      { p_household_name: (householdName.trim().slice(0, 50)) || "My Family" }
    );
    const household = households?.[0];

    if (hError || !household) {
      setError(hError?.message ?? "Failed to create household.");
      setLoading(false);
      return;
    }

    router.push("/chores");
    router.refresh();
  }

  async function handleJoin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setError("Not authenticated");
      setLoading(false);
      return;
    }

    // Sanitize: only allow alphanumeric invite codes
    const sanitizedCode = inviteCode.trim().toLowerCase().replace(/[^a-z0-9]/g, "");
    if (sanitizedCode.length !== 6) {
      setError("Invite code must be exactly 6 characters.");
      setLoading(false);
      return;
    }

    const { data: households, error: hError } = await supabase.rpc(
      "lookup_household_by_invite_code",
      { p_invite_code: sanitizedCode }
    );
    const household = households?.[0];

    if (hError || !household) {
      setError("Invalid invite code. Please check and try again.");
      setLoading(false);
      return;
    }

    const { error: mError } = await supabase.from("household_members").insert({
      household_id: household.id,
      user_id: user.id,
      role: "child",
    });

    if (mError) {
      setError(
        mError.code === "23505"
          ? "You're already a member of this household."
          : mError.message
      );
      setLoading(false);
      return;
    }

    router.push("/chores");
    router.refresh();
  }

  if (mode === "choose") {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-950 px-4">
        <div className="w-full max-w-sm text-center">
          <div className="text-6xl mb-4">🏠</div>
          <h1 className="mb-2">Welcome to <Logo size="md" /></h1>
          <p className="text-gray-400 mb-8">
            Set up your household to get started
          </p>

          <div className="space-y-3">
            <button
              onClick={() => setMode("create")}
              className="w-full bg-blue-600 text-white py-3 rounded-xl font-medium hover:bg-blue-700 transition-colors"
            >
              Create Household
            </button>
            <button
              onClick={() => setMode("join")}
              className="w-full bg-gray-800 text-gray-200 py-3 rounded-xl font-medium border border-gray-700 hover:bg-gray-700 transition-colors"
            >
              Join with Invite Code
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-950 px-4">
      <div className="w-full max-w-sm">
        <button
          onClick={() => {
            setMode("choose");
            setError("");
          }}
          className="text-blue-400 mb-4 text-sm hover:underline"
        >
          ← Back
        </button>

        <div className="bg-gray-900 rounded-xl border border-gray-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">
            {mode === "create" ? "Create Household" : "Join Household"}
          </h2>

          {error && (
            <div className="bg-red-900/30 text-red-400 text-sm p-3 rounded-lg mb-4">
              {error}
            </div>
          )}

          {mode === "create" ? (
            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Household Name
                </label>
                <input
                  type="text"
                  value={householdName}
                  onChange={(e) => setHouseholdName(e.target.value)}
                  className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="e.g. The Smiths"
                />
              </div>
              <p className="text-xs text-gray-500">
                After creating, you&apos;ll get an invite code to share with
                your child.
              </p>
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 text-white py-2 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                {loading ? "Creating..." : "Create"}
              </button>
            </form>
          ) : (
            <form onSubmit={handleJoin} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Invite Code
                </label>
                <input
                  type="text"
                  value={inviteCode}
                  onChange={(e) => setInviteCode(e.target.value)}
                  required
                  className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 text-center text-lg tracking-widest"
                  placeholder="abc123"
                  maxLength={6}
                />
              </div>
              <p className="text-xs text-gray-500">
                Ask your parent for the 6-character invite code.
              </p>
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 text-white py-2 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                {loading ? "Joining..." : "Join Household"}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
