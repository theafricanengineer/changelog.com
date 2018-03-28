defmodule Changelog.Episodes do
  use Changelog.Data

  alias Changelog.Episode
  alias Changelog.{CalendarService, CalendarEvent}

  def create(episode_params, podcast, calendar_service \\ CalendarService) do
    event_start = Map.get(episode_params, :recorded_at) || Map.get(episode_params, "recorded_at")

    event_id = case calendar_service.create(CalendarEvent.build_for(podcast, event_start)) do
      {:ok, event_id} -> event_id
      {:error, _message} -> nil
    end

    build_assoc(podcast, :episodes)
    |> Episode.add_calendar_event_id(event_id)
    |> Episode.preload_all
    |> Episode.admin_changeset(episode_params)
    |> Repo.insert
  end
end
