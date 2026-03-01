"use client";

interface LogoProps {
  size?: "sm" | "md" | "lg";
}

export default function Logo({ size = "md" }: LogoProps) {
  const sizeClasses = {
    sm: "text-2xl",
    md: "text-3xl",
    lg: "text-5xl",
  };

  return (
    <span
      className={`font-[var(--font-pacifico)] ${sizeClasses[size]} rope-text`}
      style={{ fontFamily: "var(--font-pacifico)" }}
    >
      Chorin&apos;
    </span>
  );
}
