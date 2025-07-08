import { useState } from 'react';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';
import { Logo } from '../../components/icons';
import { PasswordInput } from '../../components/passwordInput';
import { H2 } from '../../components/typography';
import { ErrorMessage } from '../../components/errorMessage';

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
        <H2>{msg('loginAccountTitle')}</H2>
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
            <ErrorMessage
              message={messagesPerField.getFirstError('username', 'password')}
            />
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
                    name="password"
                    hasError={messagesPerField.existsError(
                      'username',
                      'password'
                    )}
                    autoComplete="current-password"
                    tabIndex={3}
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
