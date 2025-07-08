import { useState } from 'react';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';

import { FullPageContainer, Logo, H2, Card, ErrorMessage, Field } from '../../components';

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
    <FullPageContainer>
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

      <Card>
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
              <Field
                label={
                  !realm.loginWithEmailAllowed
                    ? msg('username')
                    : !realm.registrationEmailAsUsername
                      ? msg('usernameOrEmail')
                      : msg('email')
                }
                name="username"
                id="username"
                type="text"
                autoComplete="username"
                autoFocus
                tabIndex={2}
                defaultValue={login.username ?? ''}
                hasError={messagesPerField.existsError('username', 'password')}
                errorMessage={
                  messagesPerField.existsError('username', 'password')
                    ? messagesPerField.getFirstError('username', 'password')
                    : undefined
                }
              />
            )}

            <Field
              label={msg('password')}
              name="password"
              id="password"
              type="password"
              i18n={i18n}
              autoComplete="current-password"
              tabIndex={3}
              hasError={messagesPerField.existsError('username', 'password')}
            />

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
      </Card>
    </FullPageContainer>
  );
}
