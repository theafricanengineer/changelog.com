defmodule Changelog.Episodes do
  use Changelog.Data

  alias Changelog.Episode
  alias Changelog.{CalendarService, CalendarEvent}

  def create(episode_params, podcast, calendar_service \\ CalendarService) do
    event_start = Map.get(episode_params, :recorded_at)
    {:ok, event_id} = calendar_service.create(CalendarEvent.build_for(podcast, event_start))

    episode_params = add_param_to(episode_params, "calendar_event_id", event_id)

    changeset =
      build_assoc(podcast, :episodes)
      |> Episode.preload_all
      |> Episode.admin_changeset(episode_params)

    Repo.insert(changeset)
  end

  defp add_param_to(params, key, value) do
    [head|_] = Map.keys(params)
    add_param_to(params, key, value, is_atom(head))
  end

  defp add_param_to(params, key, value, is_atom) when is_atom do
    Map.put(params, String.to_atom(key), value)
  end
  defp add_param_to(params, key, value, _is_atom) do
    Map.put(params, key, value)
  end
end
