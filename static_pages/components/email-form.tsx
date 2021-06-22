const EmailForm = () => {
  return (
    <form
      method="POST"
      className="mt-3 sm:flex"
      name="launch_email"
      data-netlify="true"
      action="/success"
    >
      <input type="hidden" name="form-name" value="launch_email" />
      <label htmlFor="email" className="sr-only">
        Email
      </label>
      <input
        type="text"
        name="email"
        id="email"
        className="block w-full py-3 text-base placeholder-gray-500 border-gray-300 rounded-md shadow-sm focus:ring-pink-500 focus:border-pink-500 sm:flex-1"
        placeholder="Enter your email"
      />
      <button
        type="submit"
        className="w-full px-6 py-3 mt-3 text-base font-medium text-white bg-gray-800 border border-transparent rounded-md shadow-sm hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500 sm:mt-0 sm:ml-3 sm:flex-shrink-0 sm:inline-flex sm:items-center sm:w-auto"
      >
        Notify me
      </button>
    </form>
  );
};

export default EmailForm;
