import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        ink: '#0b1f33',
        paper: '#eef3f8',
        mist: '#d5e2ef',
        signal: '#0077c8',
        flare: '#ff6b35',
        moss: '#1f6f5b',
      },
      fontFamily: {
        display: ['var(--font-display)', 'system-ui', 'sans-serif'],
        body: ['var(--font-body)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'ui-monospace', 'monospace'],
      },
      backgroundImage: {
        blueprint:
          'linear-gradient(rgba(11,31,51,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(11,31,51,0.05) 1px, transparent 1px)',
      },
      backgroundSize: {
        blueprint: '28px 28px',
      },
      keyframes: {
        rise: {
          '0%': { opacity: '0', transform: 'translateY(18px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        draw: {
          '0%': { strokeDashoffset: '240' },
          '100%': { strokeDashoffset: '0' },
        },
        pulseBar: {
          '0%, 100%': { transform: 'scaleX(0.92)' },
          '50%': { transform: 'scaleX(1)' },
        },
      },
      animation: {
        rise: 'rise 0.7s ease-out both',
        draw: 'draw 1.4s ease-out both',
        'pulse-bar': 'pulseBar 2.4s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};

export default config;
