defmodule Changelog.Episodes do
  use Changelog.Data

  alias Changelog.Episode
  alias Changelog.{CalendarService, CalendarEvent}

  def create(episode_params, podcast, calendar_service \\ CalendarService) do
    result = build_assoc(podcast, :episodes)
      |> Episode.preload_all
      |> Episode.admin_changeset(episode_params)
      |> Repo.insert

    case result do
      {:ok, episode} ->
        publish_calendar_event_for(episode, calendar_service)
      _ ->
        result
    end
  end

  defp publish_calendar_event_for(episode, calendar_service) do
    event_id = case calendar_service.create(CalendarEvent.build_for(episode)) do
      {:ok, event_id} -> event_id
      {:error, _reason} -> nil
    end

    Repo.get!(Episode, episode.id)
      |> Episode.add_calendar_event_id(event_id)
      |> Repo.update
  end
end
