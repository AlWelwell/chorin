"use client";

const CHORE_ICONS = [
  "✅", "🛏️", "🍽️", "🗑️", "👕", "🌿",
  "🐾", "📚", "🎒", "🚿", "🧹", "🛒",
  "✨", "🏠", "🚗", "📬", "🧺", "🍳",
  "🪥", "📝", "🐶", "🌸", "💪", "⭐",
];

interface IconPickerProps {
  selected: string;
  onSelect: (icon: string) => void;
  icons?: string[];
}

export default function IconPicker({ selected, onSelect, icons }: IconPickerProps) {
  const iconList = icons ?? CHORE_ICONS;
  return (
    <div className="grid grid-cols-6 gap-2">
      {iconList.map((icon) => (
        <button
          key={icon}
          type="button"
          onClick={() => onSelect(icon)}
          className={`text-2xl p-2 rounded-lg transition-colors ${
            selected === icon
              ? "bg-blue-900/40 ring-2 ring-blue-500"
              : "hover:bg-gray-800"
          }`}
        >
          {icon}
        </button>
      ))}
    </div>
  );
}
