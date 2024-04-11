import React from 'react';
import ReactDOM from 'react-dom/client';
import Home from './pages/Home.tsx';
import PastePage from './pages/Paste.tsx';
import './index.css';

import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import Layout from './components/Layout.tsx';

const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    loader: async () => {
      return fetch('/api/motd');
    },
    children: [
      {
        path: '/',
        element: <Home />,
        index: true,
        loader: async () => {
          return fetch('/api/paste/recent');
        },
      },
      {
        path: 'paste/:id',
        element: <PastePage />,
        loader: async ({ params }) => {
          return fetch(`/api/paste/${params.id}`);
        },
      },
    ],
  },
]);

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
