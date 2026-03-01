/**
 * Returns the Monday of the week containing the given date
 */
export function startOfWeek(date: Date = new Date()): Date {
  const d = new Date(date);
  const day = d.getDay();
  // getDay: 0=Sun, 1=Mon, ... 6=Sat → shift so Monday=0
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Returns the Sunday end-of-day for the week containing the given date
 */
export function endOfWeek(date: Date = new Date()): Date {
  const start = startOfWeek(date);
  const end = new Date(start);
  end.setDate(end.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return end;
}

/**
 * Returns { start, end } date strings (YYYY-MM-DD) for the week containing the given date
 */
export function weekRange(date: Date = new Date()): {
  start: string;
  end: string;
} {
  const start = startOfWeek(date);
  const end = new Date(start);
  end.setDate(end.getDate() + 6);
  return {
    start: formatDate(start),
    end: formatDate(end),
  };
}

/**
 * Formats a date as YYYY-MM-DD
 */
export function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

/**
 * Returns a human-readable label for a week (e.g., "Feb 17 – Feb 23")
 */
export function weekLabel(date: Date = new Date()): string {
  const start = startOfWeek(date);
  const end = new Date(start);
  end.setDate(end.getDate() + 6);

  const fmt = new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric" });
  return `${fmt.format(start)} – ${fmt.format(end)}`;
}

/**
 * Returns the start dates of the last N weeks (most recent first)
 */
export function pastWeekStarts(count: number, from: Date = new Date()): Date[] {
  const weeks: Date[] = [];
  let current = startOfWeek(from);
  for (let i = 0; i < count; i++) {
    weeks.push(new Date(current));
    current.setDate(current.getDate() - 7);
  }
  return weeks;
}

/**
 * Formats today's date for display (e.g., "Saturday, February 21")
 */
export function todayLabel(date: Date = new Date()): string {
  return new Intl.DateTimeFormat("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  }).format(date);
}

/**
 * Formats a currency amount
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
}
