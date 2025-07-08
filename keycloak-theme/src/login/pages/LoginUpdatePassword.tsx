import { useState } from 'react';
import { kcSanitize } from 'keycloakify/lib/kcSanitize';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';
import { Logo } from '../../components/icons';
import { PasswordInput } from '../../components/passwordInput';
import { H2 } from '../../components/typography';

export default function LoginUpdatePassword(
  props: PageProps<
    Extract<KcContext, { pageId: 'login-update-password.ftl' }>,
    I18n
  >
) {
  const { kcContext, i18n } = props;

  const { msg, msgStr } = i18n;

  const { url, messagesPerField, isAppInitiatedAction } = kcContext;

  const [isSubmitButtonDisabled, setIsSubmitButtonDisabled] = useState(false);

  return (
    <div className="min-h-screen bg-gray-lightest dark:bg-gray-darker flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <div className="h-24 w-24 flex items-center justify-center">
            <Logo />
          </div>
        </div>
        <H2>{msg('updatePasswordTitle')}</H2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white dark:bg-gray-darker dark:text-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {messagesPerField.existsError('password', 'password-confirm') && (
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
                      messagesPerField.getFirstError(
                        'password',
                        'password-confirm'
                      )
                    )}
                  </h3>
                </div>
              </div>
            </div>
          )}

          <form
            id="kc-passwd-update-form"
            className="space-y-6"
            onSubmit={() => {
              setIsSubmitButtonDisabled(true);
              return true;
            }}
            action={url.loginAction}
            method="post">
            <div>
              <label
                htmlFor="password-new"
                className="block text-sm font-medium text-gray-700 dark:text-gray-lighter">
                {msg('passwordNew')}
              </label>
              <div className="mt-1">
                <PasswordInput
                  i18n={i18n}
                  passwordInputId="password-new"
                  hasError={messagesPerField.existsError(
                    'password',
                    'password-confirm'
                  )}
                  autoComplete="new-password"
                  autoFocus
                />
                {messagesPerField.existsError('password') && (
                  <p
                    className="mt-2 text-sm text-red-600"
                    id="input-error-password">
                    {kcSanitize(messagesPerField.get('password'))}
                  </p>
                )}
              </div>
            </div>

            <div>
              <label
                htmlFor="password-confirm"
                className="block text-sm font-medium text-gray-700 dark:text-gray-lighter">
                {msg('passwordConfirm')}
              </label>
              <div className="mt-1">
                <PasswordInput
                  i18n={i18n}
                  passwordInputId="password-confirm"
                  hasError={messagesPerField.existsError(
                    'password',
                    'password-confirm'
                  )}
                  autoComplete="new-password"
                />
                {messagesPerField.existsError('password-confirm') && (
                  <p
                    className="mt-2 text-sm text-red-600"
                    id="input-error-password-confirm">
                    {kcSanitize(messagesPerField.get('password-confirm'))}
                  </p>
                )}
              </div>
            </div>

            <LogoutOtherSessions i18n={i18n} />

            <div className="flex space-x-4">
              <button
                type="submit"
                disabled={isSubmitButtonDisabled}
                className="flex-1 flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
                {msgStr('doSubmit')}
              </button>
              {isAppInitiatedAction && (
                <button
                  type="submit"
                  name="cancel-aia"
                  value="true"
                  className="flex-1 flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-colors">
                  {msg('doCancel')}
                </button>
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

function LogoutOtherSessions(props: { i18n: I18n }) {
  const { i18n } = props;

  const { msg } = i18n;

  return (
    <div className="flex items-center">
      <input
        type="checkbox"
        id="logout-sessions"
        name="logout-sessions"
        value="on"
        defaultChecked={true}
        className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
      />
      <label
        htmlFor="logout-sessions"
        className="ml-2 block text-sm text-gray-900 dark:text-gray-lighter">
        {msg('logoutOtherSessions')}
      </label>
    </div>
  );
}
