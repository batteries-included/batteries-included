export function Logo() {
  return (
    <svg
      aria-label="Batteries Included Logo, a cloud with charged ends"
      viewBox="0 0 145 92">
      <path
        className={'fill-primary'}
        d="M36.54,38.3h-4.68c-11.73,0-21.32,9.59-21.32,21.32h0c0,11.73,9.6,21.32,21.32,21.32h27.17c1.4,0,2.76-.14,4.09-.4h-.06c7.83-1.54,14.16-7.4,16.38-14.97-2.83-1.96-4.68-5.23-4.68-8.94,0-6,4.87-10.87,10.87-10.87s10.87,4.87,10.87,10.87c0,4.42-2.64,8.23-6.44,9.93-.05,.21-.09,.41-.14,.61h.06c-3.42,13.85-15.98,24.2-30.84,24.2H31.76C14.29,91.37,0,77.08,0,59.62H0c0-15.85,11.77-29.09,27.01-31.4l-.07-.07C33.69-2.39,69.77-8.99,89.27,12.83,57.24,1.93,38.52,9.66,36.54,38.3h0Zm47.66,12.24v4.68h-4.68v2.84h4.68v4.68h2.84v-4.68h4.68v-2.84h-4.68v-4.68h-2.84Z"
      />
      <path
        className={'fill-gray-dark dark:fill-white'}
        d="M118.42,35.8c14.48,.15,26.28,12.04,26.28,26.55h0c0,14.61-11.95,26.56-26.56,26.56-10.12,0-17.43-2.12-25.23-9.31h24.02c9.49,0,17.25-7.76,17.25-17.25h0c0-9.49-7.76-17.25-17.25-17.25h-5.27c-3.86-9.35-13.07-15.93-23.81-15.93-11.57,0-21.37,7.64-24.61,18.14,3.16,1.9,5.27,5.36,5.27,9.32,0,6-4.87,10.87-10.87,10.87s-10.87-4.87-10.87-10.87c0-4.22,2.4-7.87,5.91-9.67,3.63-16.08,18-28.09,35.17-28.09,12.88,0,24.19,6.76,30.56,16.92h0Zm-54.68,19.42h-12.19v2.84h12.19v-2.84Z"
      />
    </svg>
  );
}

export function Eye() {
  return (
    <svg
      className="h-5 w-5 text-gray-400 hover:text-gray-500"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
      />
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
      />
    </svg>
  );
}

export function EyeOff() {
  return (
    <svg
      className="h-5 w-5 text-gray-400 hover:text-gray-500"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L8.464 8.464M14.121 14.121l1.415 1.415M14.121 14.121L8.464 8.464M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
  );
}
