import { useState } from 'react';
import { kcSanitize } from 'keycloakify/lib/kcSanitize';
import { useIsPasswordRevealed } from 'keycloakify/tools/useIsPasswordRevealed';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';
import Logo from '../../logo';

export default function Login(
  props: PageProps<Extract<KcContext, { pageId: 'login.ftl' }>, I18n>
) {
  const { kcContext, i18n } = props;

  const {
    realm,
    url,
    usernameHidden,
    login,
    auth,
    registrationDisabled,
    messagesPerField,
  } = kcContext;

  const { msg, msgStr } = i18n;

  const [isLoginButtonDisabled, setIsLoginButtonDisabled] = useState(false);

  return (
    <div className="min-h-screen bg-gray-lightest dark:bg-gray-darker flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <div className="h-24 w-24 flex items-center justify-center">
            <Logo />
          </div>
        </div>
        <h2 className="mt-6 text-center text-3xl font-bold tracking-tight text-gray-darkest dark:text-white">
          {msg('loginAccountTitle')}
        </h2>
        {realm.password &&
          realm.registrationAllowed &&
          !registrationDisabled && (
            <p className="mt-2 text-center text-sm text-gray-darkest dark:text-gray-lighter">
              {msg('noAccount')}{' '}
              <a
                href={url.registrationUrl}
                tabIndex={8}
                className="font-medium text-primary hover:text-primary-dark transition-colors">
                {msg('doRegister')}
              </a>
            </p>
          )}
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white dark:bg-gray-darker dark:text-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {messagesPerField.existsError('username', 'password') && (
            <div className="mb-4 rounded-md bg-red-50 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg
                    className="h-5 w-5 text-red-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true">
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-red-800">
                    {kcSanitize(
                      messagesPerField.getFirstError('username', 'password')
                    )}
                  </h3>
                </div>
              </div>
            </div>
          )}

          {realm.password && (
            <form
              className="space-y-6"
              onSubmit={() => {
                setIsLoginButtonDisabled(true);
                return true;
              }}
              action={url.loginAction}
              method="post">
              {!usernameHidden && (
                <div>
                  <label
                    htmlFor="username"
                    className="block text-sm font-medium text-gray-700">
                    {!realm.loginWithEmailAllowed
                      ? msg('username')
                      : !realm.registrationEmailAsUsername
                        ? msg('usernameOrEmail')
                        : msg('email')}
                  </label>
                  <div className="mt-1">
                    <input
                      id="username"
                      name="username"
                      type="text"
                      autoComplete="username"
                      autoFocus
                      tabIndex={2}
                      defaultValue={login.username ?? ''}
                      aria-invalid={messagesPerField.existsError(
                        'username',
                        'password'
                      )}
                      className={[
                        'px-3 py-2 w-full rounded-lg focus:ring-0',
                        'text-sm text-gray-darkest dark:text-gray-lighter',
                        'placeholder:text-gray-light dark:placeholder:text-gray-dark',
                        'border border-gray-lighter dark:border-gray-darker-tint',
                        'enabled:hover:border-primary enabled:dark:hover:border-gray',
                        'focus:border-primary dark:focus:border-gray',
                        'bg-gray-lightest dark:bg-gray-darkest-tint',
                        'disabled:opacity-50',
                        messagesPerField.existsError(
                          'username',
                          'password'
                        ) && [
                          'bg-red-50 dark:bg-red-950',
                          'border-red-200 dark:border-red-900',
                        ],
                      ]
                        .flat()
                        .filter(Boolean)
                        .join(' ')}
                    />
                  </div>
                </div>
              )}

              <div>
                <label
                  htmlFor="password"
                  className="block text-sm font-medium text-gray-700">
                  {msg('password')}
                </label>
                <div className="mt-1">
                  <PasswordInput
                    i18n={i18n}
                    passwordInputId="password"
                    hasError={messagesPerField.existsError(
                      'username',
                      'password'
                    )}
                  />
                </div>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  {realm.rememberMe && !usernameHidden && (
                    <div className="flex items-center">
                      <input
                        id="rememberMe"
                        name="rememberMe"
                        type="checkbox"
                        tabIndex={5}
                        defaultChecked={!!login.rememberMe}
                        className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                      />
                      <label
                        htmlFor="rememberMe"
                        className="ml-2 block text-sm text-gray-900">
                        {msg('rememberMe')}
                      </label>
                    </div>
                  )}
                </div>

                <div className="text-sm">
                  {realm.resetPasswordAllowed && (
                    <a
                      href={url.loginResetCredentialsUrl}
                      tabIndex={6}
                      className="font-medium text-primary hover:text-primary-dark transition-colors">
                      {msg('doForgotPassword')}
                    </a>
                  )}
                </div>
              </div>

              <div>
                <input
                  type="hidden"
                  name="credentialId"
                  value={auth.selectedCredential}
                />
                <button
                  type="submit"
                  tabIndex={7}
                  disabled={isLoginButtonDisabled}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
                  {msgStr('doLogIn')}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}

function PasswordInput(props: {
  i18n: I18n;
  passwordInputId: string;
  hasError: boolean;
}) {
  const { i18n, passwordInputId, hasError } = props;

  const { msgStr } = i18n;

  const { isPasswordRevealed, toggleIsPasswordRevealed } =
    useIsPasswordRevealed({ passwordInputId });

  return (
    <div className="relative">
      <input
        id={passwordInputId}
        name="password"
        type={isPasswordRevealed ? 'text' : 'password'}
        autoComplete="current-password"
        tabIndex={3}
        aria-invalid={hasError}
        className={[
          'px-3 py-2 w-full rounded-lg focus:ring-0',
          'text-sm text-gray-darkest dark:text-gray-lighter',
          'placeholder:text-gray-light dark:placeholder:text-gray-dark',
          'border border-gray-lighter dark:border-gray-darker-tint',
          'enabled:hover:border-primary enabled:dark:hover:border-gray',
          'focus:border-primary dark:focus:border-gray',
          'bg-gray-lightest dark:bg-gray-darkest-tint',
          'disabled:opacity-50',
          'pr-10',
          hasError && [
            'bg-red-50 dark:bg-red-950',
            'border-red-200 dark:border-red-900',
          ],
        ]
          .flat()
          .filter(Boolean)
          .join(' ')}
      />
      <button
        type="button"
        className="absolute inset-y-0 right-0 pr-3 flex items-center"
        aria-label={msgStr(
          isPasswordRevealed ? 'hidePassword' : 'showPassword'
        )}
        aria-controls={passwordInputId}
        onClick={toggleIsPasswordRevealed}>
        {isPasswordRevealed ? (
          <svg
            className="h-5 w-5 text-gray-400 hover:text-gray-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L8.464 8.464M14.121 14.121l1.415 1.415M14.121 14.121L8.464 8.464M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        ) : (
          <svg
            className="h-5 w-5 text-gray-400 hover:text-gray-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg">
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
        )}
      </button>
    </div>
  );
}
