import { Fragment, useState } from 'react';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';
import { Card, ErrorMessage, Field, FullPageContainer, H2, Logo } from '../../components';


export default function LoginOtp(
  props: PageProps<Extract<KcContext, { pageId: 'login-otp.ftl' }>, I18n>
) {
  const { kcContext, i18n } = props;

  const { otpLogin, url, messagesPerField } = kcContext;

  const { msg, msgStr } = i18n;

  const [isSubmitting, setIsSubmitting] = useState(false);

  return (
    <FullPageContainer>
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <div className="h-24 w-24 flex items-center justify-center">
            <Logo />
          </div>
        </div>
        <H2>{msg('doLogIn')}</H2>
      </div>

      <Card>
        {messagesPerField.existsError('totp') && (
          <ErrorMessage message={messagesPerField.get('totp')} />
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

          <Field
            label={msg('loginOtpOneTime')}
            name="otp"
            id="otp"
            type="text"
            autoComplete="off"
            autoFocus
            hasError={messagesPerField.existsError('totp')}
            errorMessage={
              messagesPerField.existsError('totp')
                ? messagesPerField.get('totp')
                : undefined
            }
            errorId="input-error-otp"
          />

          <div>
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
              {msgStr('doLogIn')}
            </button>
          </div>
        </form>
      </Card>
    </FullPageContainer>
  );
}
