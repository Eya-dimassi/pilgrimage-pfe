export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [

  ],
  corePlugins: {
    // ✅ Disable Tailwind's preflight reset on buttons.
    // It was setting background-color: transparent on ALL buttons,
    // overriding our custom .nav-cta, .btn-send, .btn-form-submit styles.
    preflight: false,
  },

}