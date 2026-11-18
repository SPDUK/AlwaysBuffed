import { createRoot, hydrateRoot } from 'react-dom/client';
import App from './App';
import './style.css';

const root = document.getElementById('root');
if (!root) throw new Error('AlwaysBuffed root element is missing');

if (root.firstElementChild) {
  hydrateRoot(root, <App />);
} else {
  createRoot(root).render(<App />);
}
