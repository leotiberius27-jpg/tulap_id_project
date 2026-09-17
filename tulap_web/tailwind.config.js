/**
 * Tailwind Config - Tulap.id Web Dashboard
 * ----------------------------------------------------------------------
 * Memetakan CSS custom properties di design-tokens.css menjadi utility
 * class Tailwind (mis. `bg-primary`, `text-danger`, `rounded-card`).
 *
 * Import 'styles/design-tokens.css' SEBELUM stylesheet Tailwind di
 * entry point aplikasi (mis. _app.tsx atau main.tsx) agar variabel
 * CSS tersedia lebih dulu.
 * ----------------------------------------------------------------------
 */

/**
 * design-tokens.css stores each color as "R G B" channels (not #hex) so
 * this can wrap it in rgba(var(--color-x), <alpha>) - that's what lets
 * Tailwind's opacity modifiers (bg-primary/10, border-danger/20, ...)
 * actually compute a color instead of silently rendering transparent.
 */
function withOpacity(variableName) {
  return ({ opacityValue }) =>
    opacityValue === undefined
      ? `rgb(var(${variableName}))`
      : `rgb(var(${variableName}) / ${opacityValue})`;
}

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{js,ts,jsx,tsx}',
    './pages/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: withOpacity('--color-primary'),
          hover: withOpacity('--color-primary-hover'),
        },
        action: withOpacity('--color-action'),
        success: {
          DEFAULT: withOpacity('--color-success'),
          soft: withOpacity('--color-success-soft'),
        },
        warning: {
          DEFAULT: withOpacity('--color-warning'),
          soft: withOpacity('--color-warning-soft'),
        },
        danger: {
          DEFAULT: withOpacity('--color-danger'),
          soft: withOpacity('--color-danger-soft'),
        },
        background: withOpacity('--color-background'),
        surface: withOpacity('--color-surface'),
        border: withOpacity('--color-border'),
        text: {
          primary: withOpacity('--color-text-primary'),
          secondary: withOpacity('--color-text-secondary'),
        },
      },
      fontFamily: {
        sans: ['var(--font-family-base)'],
      },
      fontSize: {
        display: ['var(--font-size-display)', { fontWeight: '700' }],
        'page-title': ['var(--font-size-page-title)', { fontWeight: '700' }],
        'section-title': [
          'var(--font-size-section-title)',
          { fontWeight: '600' },
        ],
        body: ['var(--font-size-body)', { fontWeight: '400' }],
        small: ['var(--font-size-small)', { fontWeight: '500' }],
      },
      borderRadius: {
        small: 'var(--radius-small)',
        button: 'var(--radius-button)',
        card: 'var(--radius-card)',
        'sheet-top': 'var(--radius-sheet-top)',
      },
      boxShadow: {
        card: 'var(--shadow-card)',
        dropdown: 'var(--shadow-dropdown)',
      },
    },
  },
  plugins: [],
};
