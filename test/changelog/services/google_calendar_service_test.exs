defmodule Changelog.Services.GoogleCalendarServiceTest do
  use Changelog.DataCase

  alias Changelog.{Episode, CalendarEvent}

  alias Changelog.Services.GoogleCalendarService

  @google_calendar_id "bdo60t3hcbpqsgkehhef8j9sqo@group.calendar.google.com"
  @google_calendar_timezone "Europe/Rome"

  test "#create" do
    recorded_at = Timex.to_datetime({{2018, 4, 1}, {11, 00, 00}}, @google_calendar_timezone)
    calendar_event = insert(:episode, recorded_at: recorded_at)
      |> with_episode_host
      |> with_episode_guest
      |> Episode.preload_all
      |> CalendarEvent.build_for

    {:ok, event_id} = GoogleCalendarService.create(calendar_event)

    assert has_been_created(calendar_event, {:with, event_id})
  end

  defp has_been_created(calendar_event, {:with, event_id}) do
    {:ok, google_calendar_event} = google_api_connection()
      |> GoogleApi.Calendar.V3.Api.Events.calendar_events_get(@google_calendar_id, event_id)

    %GoogleApi.Calendar.V3.Model.Event{id: ^event_id} = google_calendar_event

    assert google_calendar_event.summary == calendar_event.name
    assert google_calendar_event.description == calendar_event.notes
    assert google_calendar_event.location == calendar_event.location
    assert google_calendar_event.start.dateTime == Timex.format!(calendar_event.start, "{ISO:Extended}")
    assert google_calendar_event.end.dateTime == Timex.format!(Timex.add(calendar_event.start, Timex.Duration.from_minutes(calendar_event.duration)), "{ISO:Extended}")
  end

  defp google_api_connection do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/calendar")
    GoogleApi.Calendar.V3.Connection.new(token.token)
  end

  defp with_episode_host(episode) do
    insert(:episode_host, episode: episode)
    episode
  end

  defp with_episode_guest(episode) do
    insert(:episode_guest, episode: episode)
    episode
  end
end
