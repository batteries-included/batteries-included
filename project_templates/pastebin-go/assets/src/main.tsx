import React from 'react';
import ReactDOM from 'react-dom/client';
import Home from './pages/Home.tsx';
import PastePage from './pages/Paste.tsx';
import './index.css';

import { createBrowserRouter, RouterProvider } from 'react-router-dom';

const router = createBrowserRouter([
  {
    path: '/paste/:id',
    element: <PastePage />,
    loader: async ({ params }) => {
      return fetch(`/api/paste/${params.id}`);
    },
  },
  {
    path: '/',
    element: <Home />,
  },
]);

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
