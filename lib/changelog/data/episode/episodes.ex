defmodule Changelog.Episodes do
  use Changelog.Data

  @calendar_service Application.get_env(:changelog, Changelog.CalendarService)[:adapter]

  alias Changelog.Episode
  alias Changelog.CalendarEvent

  def create(episode_params, podcast) do
    build_assoc(podcast, :episodes)
      |> Episode.preload_all
      |> Episode.admin_changeset(episode_params)
      |> Repo.insert
      |> create_calendar_event
  end

  def delete(slug, podcast) do
    assoc(podcast, :episodes)
      |> Episode.unpublished
      |> Repo.get_by!(slug: slug)
      |> Repo.delete
      |> delete_calendar_event
  end

  defp create_calendar_event({:ok, episode = %Changelog.Episode{recorded_at: recorded_at}}) when not is_nil(recorded_at) do
    calendar_event = episode
      |> Episode.preload_all
      |> CalendarEvent.build_for

    case @calendar_service.create(calendar_event) do
      {:ok, event_id} -> Episode.update_calendar_event_id(episode, event_id)
      {:error, _reason} -> {:ok, episode}
    end
  end
  defp create_calendar_event(result), do: result

  defp delete_calendar_event({:ok, episode = %Changelog.Episode{calendar_event_id: calendar_event_id}}) when not is_nil(calendar_event_id) do
    @calendar_service.delete(episode.calendar_event_id)
    {:ok, episode}
  end
  defp delete_calendar_event(result), do: result
end
