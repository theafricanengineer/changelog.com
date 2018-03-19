defmodule Changelog.Episodes do
  use Changelog.Data

  alias Changelog.Episode

  def create(episode_params, podcast) do
    changeset =
      build_assoc(podcast, :episodes)
      |> Episode.preload_all
      |> Episode.admin_changeset(episode_params)

    Repo.insert(changeset)
  end
end
