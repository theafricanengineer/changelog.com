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
      {:ok, episode} -> publish_calendar_event_for(episode, calendar_service)
      _ -> result
    end
  end

  defp publish_calendar_event_for(episode, calendar_service) do
    case calendar_service.create(CalendarEvent.build_for(episode)) do
      {:ok, event_id} -> Episode.update_calendar_event_id(episode, event_id)
      {:error, _reason} -> {:ok, episode}
    end
  end
end
