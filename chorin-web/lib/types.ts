export interface Household {
  id: string;
  name: string;
  invite_code: string;
  created_at: string;
}

export interface HouseholdMember {
  id: string;
  household_id: string;
  user_id: string;
  role: "parent" | "child";
  created_at: string;
}

export interface Chore {
  id: string;
  household_id: string;
  created_by_user_id?: string | null;
  name: string;
  value: number;
  icon: string;
  validation_status?: "pending" | "valid" | "invalid";
  validated_by_user_id?: string | null;
  validated_at?: string | null;
  is_active: boolean;
  created_at: string;
}

export interface ChoreCompletion {
  id: string;
  chore_id: string;
  user_id: string;
  date: string;
  earned_amount: number;
  created_at: string;
}

export interface ChoreWithCompletion extends Chore {
  completedToday: boolean;
  todayCompletionId?: string;
}

export interface SavingsGoal {
  id: string;
  household_id: string;
  user_id: string;
  name: string;
  target_amount: number;
  icon: string;
  auto_percent: number;
  is_active: boolean;
  created_at: string;
}

export interface SavingsContribution {
  id: string;
  goal_id: string;
  user_id: string;
  amount: number;
  source: "auto" | "manual";
  completion_id: string | null;
  created_at: string;
}

export interface GoalWithProgress extends SavingsGoal {
  totalSaved: number;
  progressPercent: number;
  isComplete: boolean;
}
