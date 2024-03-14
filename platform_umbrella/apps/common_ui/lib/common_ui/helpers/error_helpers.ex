defmodule CommonUI.ErrorHelpers do
  @moduledoc false

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Translates an error message using gettext.

  When using gettext, we typically pass the strings we want
  to translate as a static argument:

     # Translate "is invalid" in the "errors" domain
     dgettext("errors", "is invalid")

     # Translate the number of files with plural rules
     dngettext("errors", "1 file", "%{count} files", count)

  Because the error messages we show in our forms and APIs
  are defined inside Ecto, we need to translate them dynamically.
  This requires us to call the Gettext module passing our gettext
  backend as first argument.

  Note we use the "errors" domain, which means translations
  should be written to the errors.po file. The :count option is
  set by Ecto and indicates we should also apply plural rules.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(CommonUI.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CommonUI.Gettext, "errors", msg, opts)
    end
  end
end
