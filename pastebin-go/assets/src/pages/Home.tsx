import { ChangeEvent, FormEvent, useState } from 'react';
import { generateSlug } from 'random-word-slugs';
import { H1, H2 } from '../components/Typography';
import { Paste } from '../types';
import { Link, useLoaderData } from 'react-router-dom';

interface RecentResponse {
  data: Paste[];
}

function Home() {
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    loading: false,
  });

  const handleChange = (
    event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = event.target;
    setFormData((prevState) => ({ ...prevState, [name]: value }));
  };

  const resetForm = () => {
    setFormData({
      title: '',
      content: '',
      loading: false,
    });
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (formData.loading) return;

    const content = formData.content;
    let title = formData.title;

    // Even if they never entered a title, we'll generate one for them
    if (title == '' || title == null) {
      title = generateSlug(4, { format: 'title' });
    }
    // Set loading to true
    // also set the title to the generated title just in case
    setFormData((prevState) => ({ ...prevState, loading: true, title: title }));

    // Make the request to the server post to /api/paste
    fetch('/api/paste', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        title: title,
        content: content,
      }),
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error('Failed to create paste');
        }
        return response.json();
      })
      .then((data) => {
        // Redirect to the new paste
        window.location.href = `/paste/${data.id}`;
      })
      .catch((error) => {
        console.error(error);
        setFormData((prevState) => ({ ...prevState, loading: false }));
      });
  };

  const recent: RecentResponse = useLoaderData() as RecentResponse;

  return (
    <div className="flex flex-col gap-8">
      <H1>Create Paste</H1>
      <form onSubmit={handleSubmit}>
        <div className="flex flex-col gap-4">
          <textarea
            name="content"
            onChange={handleChange}
            value={formData.content}
            className="block min-h-40 w-full rounded-lg border border-gray-light bg-gray-lightest p-2.5 text-sm text-gray-darker focus:border-pink-500 focus:ring-pink-500"
            placeholder="Some Paste Content"
            required
          />

          <input
            type="text"
            name="title"
            onChange={handleChange}
            value={formData.title}
            className="block w-full rounded-lg border border-gray-light bg-gray-lightest p-2.5 text-sm text-gray-darker focus:border-pink-500 focus:ring-pink-500"
            placeholder="(Optional) Paste Title"
          />

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={formData.loading}
              className="rounded bg-pink-500 px-4 py-2 font-bold text-white shadow-lg hover:bg-pink-600">
              Create Paste
            </button>
            <button
              type="button"
              disabled={formData.loading}
              className="rounded bg-gray-lighter px-4 py-2 font-bold text-gray-darker hover:bg-gray-light"
              onClick={resetForm}>
              Cancel
            </button>
          </div>
        </div>
      </form>

      <H2>Recent Pastes</H2>
      <ul className="flex flex-col gap-4">
        {recent.data.map((paste) => (
          <li key={paste.id} className="">
            <Link
              to={`/paste/${paste.id}`}
              className="cursor-pointer text-pink-500 hover:underline">
              {paste.title}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default Home;
