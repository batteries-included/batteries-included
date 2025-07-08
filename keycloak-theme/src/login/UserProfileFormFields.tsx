import { useEffect, Fragment } from 'react';
import { useUserProfileForm } from 'keycloakify/login/lib/useUserProfileForm';
import type { UserProfileFormFieldsProps } from 'keycloakify/login/UserProfileFormFieldsProps';
import type { Attribute } from 'keycloakify/login/KcContext';
import type { KcContext } from './KcContext';
import type { I18n } from './i18n';
import { Field } from './components/field';

// Helper function to convert attribute input type to Field component type
function getFieldType(
  attribute: Attribute
):
  | 'text'
  | 'email'
  | 'tel'
  | 'url'
  | 'password'
  | 'select'
  | 'textarea'
  | 'multiselect'
  | 'hidden' {
  const inputType = attribute.annotations.inputType;

  if (inputType === 'hidden') return 'hidden';
  if (inputType === 'textarea') return 'textarea';
  if (inputType === 'select') return 'select';
  if (inputType === 'multiselect') return 'multiselect';
  if (inputType?.startsWith('html5-')) {
    const htmlType = inputType.slice(6);
    if (htmlType === 'email') return 'email';
    if (htmlType === 'tel') return 'tel';
    if (htmlType === 'url') return 'url';
  }
  if (attribute.name === 'password' || attribute.name === 'password-confirm') {
    return 'password';
  }

  return 'text';
}

export default function UserProfileFormFields(
  props: UserProfileFormFieldsProps<KcContext, I18n>
) {
  const {
    kcContext,
    i18n,
    kcClsx,
    onIsFormSubmittableValueChange,
    doMakeUserConfirmPassword,
    BeforeField,
    AfterField,
  } = props;

  const { advancedMsg } = i18n;

  const {
    formState: { formFieldStates, isFormSubmittable },
    dispatchFormAction,
  } = useUserProfileForm({
    kcContext,
    i18n,
    doMakeUserConfirmPassword,
  });

  useEffect(() => {
    onIsFormSubmittableValueChange(isFormSubmittable);
  }, [isFormSubmittable]);

  return (
    <>
      {formFieldStates.map(
        ({ attribute, displayableErrors, valueOrValues }) => {
          // Convert displayableErrors to error strings
          const errorStrings = displayableErrors.map(
            (error) => error.errorMessageStr
          );

          // Skip hidden fields and password-confirm when not needed
          if (
            attribute.annotations.inputType === 'hidden' ||
            (attribute.name === 'password-confirm' &&
              !doMakeUserConfirmPassword)
          ) {
            return null;
          }

          return (
            <Fragment key={attribute.name}>
              {BeforeField !== undefined && (
                <BeforeField
                  attribute={attribute}
                  dispatchFormAction={dispatchFormAction}
                  displayableErrors={displayableErrors}
                  valueOrValues={valueOrValues}
                  kcClsx={kcClsx}
                  i18n={i18n}
                />
              )}

              <Field
                label={
                  <>
                    {advancedMsg(attribute.displayName ?? '')}
                    {attribute.required && <> *</>}
                  </>
                }
                labelId={`label-${attribute.name}`}
                name={attribute.name}
                id={attribute.name}
                type={getFieldType(attribute)}
                value={
                  typeof valueOrValues === 'string'
                    ? valueOrValues
                    : valueOrValues[0] || ''
                }
                placeholder={
                  attribute.annotations.inputTypePlaceholder
                    ? i18n.advancedMsgStr(
                        attribute.annotations.inputTypePlaceholder
                      )
                    : undefined
                }
                autoComplete={attribute.autocomplete}
                required={attribute.required}
                disabled={attribute.readOnly}
                errors={errorStrings}
                i18n={i18n}
                className={kcClsx('kcFormGroupClass')}
                inputClassName={kcClsx('kcInputClass')}
                {...(attribute.annotations.inputTypePattern && {
                  pattern: attribute.annotations.inputTypePattern,
                })}
                {...(attribute.annotations.inputTypeMaxlength && {
                  maxLength: parseInt(
                    `${attribute.annotations.inputTypeMaxlength}`
                  ),
                })}
                {...(attribute.annotations.inputTypeMinlength && {
                  minLength: parseInt(
                    `${attribute.annotations.inputTypeMinlength}`
                  ),
                })}
                {...(attribute.annotations.inputTypeMax && {
                  max: attribute.annotations.inputTypeMax,
                })}
                {...(attribute.annotations.inputTypeMin && {
                  min: attribute.annotations.inputTypeMin,
                })}
                {...(attribute.annotations.inputTypeStep && {
                  step: attribute.annotations.inputTypeStep,
                })}
                {...(attribute.annotations.inputTypeSize && {
                  size: parseInt(`${attribute.annotations.inputTypeSize}`),
                })}
                onChange={(
                  event: React.ChangeEvent<
                    HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
                  >
                ) => {
                  dispatchFormAction({
                    action: 'update',
                    name: attribute.name,
                    valueOrValues: event.target.value,
                  });
                }}
                onBlur={() => {
                  dispatchFormAction({
                    action: 'focus lost',
                    name: attribute.name,
                    fieldIndex: undefined,
                  });
                }}
              />

              {AfterField !== undefined && (
                <AfterField
                  attribute={attribute}
                  dispatchFormAction={dispatchFormAction}
                  displayableErrors={displayableErrors}
                  valueOrValues={valueOrValues}
                  kcClsx={kcClsx}
                  i18n={i18n}
                />
              )}
            </Fragment>
          );
        }
      )}
    </>
  );
}
