import type { ReactNode } from 'react';

const glyphs = {
  download: (
    <>
      <path d="M12 3v12m-5-5 5 5 5-5" />
      <path d="M4 15v5h16v-5" />
    </>
  ),
  external: <path d="M6 18 18 6M7 6h11v11" />,
  arrow: <path d="M4 12h15m-6-6 6 6-6 6" />,
  left: <path d="m15 5-7 7 7 7" />,
  right: <path d="m9 5 7 7-7 7" />,
  plus: <path d="M12 5v14M5 12h14" />,
  pin: (
    <>
      <path d="M19 9c0 5-7 12-7 12S5 14 5 9a7 7 0 1 1 14 0Z" />
      <circle cx="12" cy="9" r="2.1" />
    </>
  ),
  compass: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m16.7 7.3-3.2 6.2-6.2 3.2 3.2-6.2z" />
    </>
  ),
  book: (
    <>
      <path d="M12 6c-3-2-6-2-10-1v14c4-1 7-1 10 1 3-2 6-2 10-1V5c-4-1-7-1-10 1Zm0 0v14" />
    </>
  ),
  layers: (
    <>
      <path d="m12 2 10 5.5L12 13 2 7.5 12 2Zm-10 10L12 18l10-6m-20 5 10 5 10-5" />
    </>
  ),
  menu: <path d="M3 7h18M3 12h18M3 17h18" />,
  forge: (
    <path
      fill="currentColor"
      stroke="none"
      d="M1 4.5h19.8l1.8 3.2-4.1 2.6-1.3 3.1-3.6.8-1.9 2.3 5.1 1.4 1.4 2.6H6.1l1.1-2.6 3-.9-.4-2.6-4.6-2.2L1 7.6h6l1.2-1.1H2.2z"
    />
  ),
  wago: (
    <g fill="currentColor" stroke="none">
      <path d="M0 5h3.8l3 8.7L10.4 5h3.2L8 19H5.4zM12 9.5l1.8-4.4 3.2 8.6L20.4 5H24l-5.7 14h-2.8z" />
    </g>
  ),
} satisfies Record<string, ReactNode>;

export function Icon({
  name,
  size = 20,
  className,
}: {
  name: keyof typeof glyphs;
  size?: number;
  className?: string;
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      className={className}
    >
      {glyphs[name]}
    </svg>
  );
}
