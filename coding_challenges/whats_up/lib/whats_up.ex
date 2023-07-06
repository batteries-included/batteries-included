defmodule WhatsUp do
  @moduledoc """
  """
  alias WhatsUp.Detector

  @doc """
  This is the main entry point into the WhatsUp application. Calling in
  will return the sites that are up and down currently. No site will
  be in up and down at the same time. Every site is in one of the
  two lists.

  @returns `%{up: list_of_sites_with_up_urls, down: the_inverse}`
  """
  @spec status :: %{:down => list(), :up => list()}
  def status do
    # TODO: This whole thing needs to be done
    # Fill me in here
    #
    #
    # Right no this code will pull from the database all sites to detect.
    # Randomly assign each site to :up or :down
    # Then create a map with those as the keys and the list of sites as the values.
    random_choice = Enum.group_by(Detector.list_sites(), fn _ -> Enum.random([:up, :down]) end)

    # Merge the result into an empty map just in case
    # there are no sites that are up or down.
    Map.merge(%{up: [], down: []}, random_choice)
  end
end
