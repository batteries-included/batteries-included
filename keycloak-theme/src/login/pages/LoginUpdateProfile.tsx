import type { JSX } from 'keycloakify/tools/JSX';
import { useState } from 'react';
import type { LazyOrNot } from 'keycloakify/tools/LazyOrNot';
import type { UserProfileFormFieldsProps } from 'keycloakify/login/UserProfileFormFieldsProps';
import type { PageProps } from 'keycloakify/login/pages/PageProps';
import type { KcContext } from '../KcContext';
import type { I18n } from '../i18n';
import {
  FullPageContainer,
  Logo,
  H2,
  Card,
  ErrorMessage,
} from '../components';

type LoginUpdateProfileProps = PageProps<
  Extract<KcContext, { pageId: 'login-update-profile.ftl' }>,
  I18n
> & {
  UserProfileFormFields: LazyOrNot<
    (props: UserProfileFormFieldsProps) => JSX.Element
  >;
  doMakeUserConfirmPassword: boolean;
};

export default function LoginUpdateProfile(props: LoginUpdateProfileProps) {
  const { kcContext, i18n, UserProfileFormFields, doMakeUserConfirmPassword } =
    props;

  const { messagesPerField, url, isAppInitiatedAction } = kcContext;

  const { msg, msgStr } = i18n;

  const [isFormSubmittable, setIsFormSubmittable] = useState(false);

  return (
    <FullPageContainer>
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <div className="h-24 w-24 flex items-center justify-center">
            <Logo />
          </div>
        </div>
        <H2>{msg('loginProfileTitle')}</H2>
      </div>

      <Card>
        {messagesPerField.exists('global') && (
          <ErrorMessage message={messagesPerField.get('global')} />
        )}

        <form
          id="kc-update-profile-form"
          className="space-y-6"
          action={url.loginAction}
          method="post">
          <UserProfileFormFields
            kcContext={kcContext}
            i18n={i18n}
            kcClsx={() => ''}
            onIsFormSubmittableValueChange={setIsFormSubmittable}
            doMakeUserConfirmPassword={doMakeUserConfirmPassword}
          />

          <div className="flex gap-4">
            <button
              disabled={!isFormSubmittable}
              className="flex-1 flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              type="submit">
              {msgStr('doSubmit')}
            </button>
            {isAppInitiatedAction && (
              <button
                className="flex-1 flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-colors"
                type="submit"
                name="cancel-aia"
                value="true"
                formNoValidate>
                {msg('doCancel')}
              </button>
            )}
          </div>
        </form>
      </Card>
    </FullPageContainer>
  );
}
