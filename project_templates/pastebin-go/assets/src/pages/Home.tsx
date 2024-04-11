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
            className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-pink-500 focus:border-pink-500 block w-full p-2.5 min-h-40"
            placeholder="Some Paste Content"
            required
          />

          <input
            type="text"
            name="title"
            onChange={handleChange}
            value={formData.title}
            className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-pink-500 focus:border-pink-500 block w-full p-2.5"
            placeholder="(Optional) Paste Title"
          />

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={formData.loading}
              className="bg-pink-500 hover:bg-pink-600 text-white font-bold py-2 px-4 rounded shadow-lg">
              Create Paste
            </button>
            <button
              type="button"
              disabled={formData.loading}
              className="bg-gray-300 hover:bg-gray-400 text-gray-900 font-bold py-2 px-4 rounded"
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
              className="text-pink-500 hover:underline cursor-pointer">
              {paste.title}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default Home;
