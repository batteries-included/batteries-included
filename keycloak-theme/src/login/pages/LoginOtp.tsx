import { Fragment, useState } from 'react';
import { kcSanitize } from 'keycloakify/lib/kcSanitize';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';
import { Logo } from '../../components/icons';
import { H2 } from '../../components/typography';

export default function LoginOtp(
  props: PageProps<Extract<KcContext, { pageId: 'login-otp.ftl' }>, I18n>
) {
  const { kcContext, i18n } = props;

  const { otpLogin, url, messagesPerField } = kcContext;

  const { msg, msgStr } = i18n;

  const [isSubmitting, setIsSubmitting] = useState(false);

  return (
    <div className="min-h-screen bg-gray-lightest dark:bg-gray-darker flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <div className="h-24 w-24 flex items-center justify-center">
            <Logo />
          </div>
        </div>
        <H2>{msg('doLogIn')}</H2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white dark:bg-gray-darker dark:text-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {messagesPerField.existsError('totp') && (
            <div className="mb-4 rounded-md bg-red-50 dark:bg-red-950 p-4">
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
                  <h3 className="text-sm font-medium text-red-800 dark:text-red-400">
                    {kcSanitize(messagesPerField.get('totp'))}
                  </h3>
                </div>
              </div>
            </div>
          )}

          <form
            id="kc-otp-login-form"
            className="space-y-6"
            action={url.loginAction}
            onSubmit={() => {
              setIsSubmitting(true);
              return true;
            }}
            method="post">
            {otpLogin.userOtpCredentials.length > 1 && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                  Choose authenticator
                </label>
                <div className="space-y-2">
                  {otpLogin.userOtpCredentials.map(
                    (
                      otpCredential: { id: string; userLabel: string },
                      index: number
                    ) => (
                      <Fragment key={index}>
                        <label
                          htmlFor={`kc-otp-credential-${index}`}
                          className="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-darkest-tint border-gray-lighter dark:border-gray-darker-tint">
                          <input
                            id={`kc-otp-credential-${index}`}
                            className="h-4 w-4 text-primary focus:ring-primary border-gray-300 dark:border-gray-darker"
                            type="radio"
                            name="selectedCredentialId"
                            value={otpCredential.id}
                            defaultChecked={
                              otpCredential.id === otpLogin.selectedCredentialId
                            }
                          />
                          <div className="ml-3 flex items-center">
                            <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center mr-3">
                              <svg
                                className="w-4 h-4 text-primary"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24">
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
                                />
                              </svg>
                            </div>
                            <span className="text-sm font-medium text-gray-darkest dark:text-gray-lighter">
                              {otpCredential.userLabel}
                            </span>
                          </div>
                        </label>
                      </Fragment>
                    )
                  )}
                </div>
              </div>
            )}

            <div>
              <label
                htmlFor="otp"
                className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                {msg('loginOtpOneTime')}
              </label>
              <div className="mt-1">
                <input
                  id="otp"
                  name="otp"
                  autoComplete="off"
                  type="text"
                  autoFocus
                  aria-invalid={messagesPerField.existsError('totp')}
                  className={[
                    'px-3 py-2 w-full rounded-lg focus:ring-0',
                    'text-sm text-gray-darkest dark:text-gray-lighter',
                    'placeholder:text-gray-light dark:placeholder:text-gray-dark',
                    'border border-gray-lighter dark:border-gray-darker-tint',
                    'enabled:hover:border-primary enabled:dark:hover:border-gray',
                    'focus:border-primary dark:focus:border-gray',
                    'bg-gray-lightest dark:bg-gray-darkest-tint',
                    'disabled:opacity-50',
                    messagesPerField.existsError('totp') && [
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

            <div>
              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
                {msgStr('doLogIn')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
