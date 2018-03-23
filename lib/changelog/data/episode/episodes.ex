defmodule Changelog.Episodes do
  use Changelog.Data

  alias Changelog.Episode
  alias Changelog.{CalendarService, CalendarEvent}

  def create(episode_params, podcast, calendar_service \\ CalendarService) do
    event_start = Map.get(episode_params, :recorded_at)
    calendar_service.create(CalendarEvent.build_for(podcast, event_start))

    changeset =
      build_assoc(podcast, :episodes)
      |> Episode.preload_all
      |> Episode.admin_changeset(episode_params)

    Repo.insert(changeset)
  end
end
