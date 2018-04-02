defmodule Changelog.Episodes do
  use Changelog.Data

  @calendar_service Application.get_env(:changelog, Changelog.CalendarService)[:adapter]

  alias Changelog.Episode
  alias Changelog.CalendarEvent

  def create(episode_params, podcast, calendar_service \\ @calendar_service) do
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
    calendar_event = episode
      |> Episode.preload_all
      |> CalendarEvent.build_for

    case calendar_service.create(calendar_event) do
      {:ok, event_id} -> Episode.update_calendar_event_id(episode, event_id)
      {:error, _reason} -> {:ok, episode}
    end
  end
end
