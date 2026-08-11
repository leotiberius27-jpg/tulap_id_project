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
          DEFAULT: 'var(--color-primary)',
          hover: 'var(--color-primary-hover)',
        },
        action: 'var(--color-action)',
        success: {
          DEFAULT: 'var(--color-success)',
          soft: 'var(--color-success-soft)',
        },
        warning: {
          DEFAULT: 'var(--color-warning)',
          soft: 'var(--color-warning-soft)',
        },
        danger: {
          DEFAULT: 'var(--color-danger)',
          soft: 'var(--color-danger-soft)',
        },
        background: 'var(--color-background)',
        surface: 'var(--color-surface)',
        border: 'var(--color-border)',
        text: {
          primary: 'var(--color-text-primary)',
          secondary: 'var(--color-text-secondary)',
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
      spacing: {
        4: 'var(--spacing-4)',
        8: 'var(--spacing-8)',
        12: 'var(--spacing-12)',
        16: 'var(--spacing-16)',
        24: 'var(--spacing-24)',
        32: 'var(--spacing-32)',
        40: 'var(--spacing-40)',
        48: 'var(--spacing-48)',
        64: 'var(--spacing-64)',
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
