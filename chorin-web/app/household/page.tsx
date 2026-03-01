"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import BottomNav from "@/components/BottomNav";
import type { Household, HouseholdMember } from "@/lib/types";

export default function HouseholdPage() {
  const [household, setHousehold] = useState<Household | null>(null);
  const [members, setMembers] = useState<HouseholdMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);
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

    const { data: membership } = await supabase
      .from("household_members")
      .select("household_id")
      .eq("user_id", user.id)
      .single();

    if (!membership) {
      router.push("/onboarding");
      return;
    }

    const { data: householdData } = await supabase
      .from("households")
      .select("*")
      .eq("id", membership.household_id)
      .single();

    setHousehold(householdData);

    const { data: membersData } = await supabase
      .from("household_members")
      .select("*")
      .eq("household_id", membership.household_id)
      .order("created_at", { ascending: true });

    setMembers(membersData ?? []);
    setLoading(false);
  }, [supabase, router]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  function copyInviteCode() {
    if (household?.invite_code) {
      navigator.clipboard.writeText(household.invite_code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
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
        <h1 className="text-2xl font-bold text-white">Household</h1>
      </div>

      {/* Household Info */}
      {household && (
        <div className="bg-gray-900 mt-2 p-4">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-blue-900/40 rounded-full flex items-center justify-center text-2xl">
              🏠
            </div>
            <div>
              <h2 className="text-lg font-semibold text-white">{household.name}</h2>
              <p className="text-sm text-gray-400">
                {members.length} member{members.length === 1 ? "" : "s"}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Invite Code */}
      {household && (
        <div className="bg-gray-900 mt-2 p-4">
          <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide mb-3">
            Invite Code
          </h3>
          <div className="flex items-center gap-3">
            <code className="flex-1 bg-gray-800 rounded-lg px-4 py-3 text-center text-2xl tracking-[0.3em] font-mono font-bold text-white">
              {household.invite_code}
            </code>
            <button
              onClick={copyInviteCode}
              className="px-4 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors text-sm"
            >
              {copied ? "Copied!" : "Copy"}
            </button>
          </div>
          <p className="text-xs text-gray-500 mt-2">
            Share this code with your child so they can join your household.
          </p>
        </div>
      )}

      {/* Members */}
      <div className="bg-gray-900 mt-2">
        <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
          Members
        </h3>
        <div className="divide-y divide-gray-800">
          {members.map((member) => (
            <div
              key={member.id}
              className="px-4 py-3 flex items-center gap-3"
            >
              <div className="w-8 h-8 bg-green-900/40 rounded-full flex items-center justify-center">
                {member.role === "parent" ? "👤" : "🧒"}
              </div>
              <div className="flex-1">
                <span className="text-gray-300 capitalize">{member.role}</span>
              </div>
              <span className="text-xs text-gray-400 bg-gray-800 px-2 py-1 rounded-full">
                {member.role}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Sign Out */}
      <div className="bg-gray-900 mt-2 p-4">
        <button
          onClick={handleSignOut}
          className="w-full py-2 text-red-400 border border-red-900 rounded-lg hover:bg-red-900/20 transition-colors font-medium"
        >
          Sign Out
        </button>
      </div>

      <BottomNav />
    </div>
  );
}
