import Reveal from 'reveal.js';

// Core styles and fonts
import 'reveal.js/dist/reveal.css';
import 'reveal.js/plugin/highlight/monokai.css';
import '@fontsource-variable/inter';
import '@fontsource-variable/jetbrains-mono';
import './theme/bi-theme.css';

const deck = new Reveal({
  hash: true,
  plugins: [],
  slideNumber: 'c/t',
  progress: true,
  center: true,
  mouseWheel: true,
});

deck.initialize({
  markdown: {
    smartypants: true,
  },
});
