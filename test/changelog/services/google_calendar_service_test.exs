defmodule Changelog.Services.GoogleCalendarServiceTest do
  use ExUnit.Case, async: true
  @moduletag :external

  @google_calendar_id Application.get_env(:changelog, Changelog.CalendarService)[:google_calendar_id]

  alias Changelog.CalendarEvent
  alias Changelog.Services.GoogleCalendarService

  describe "#create" do
    test "should return the event_id when success" do
      calendar_event = %CalendarEvent{
        name: "A calendar event name",
        start: an_event_date(),
        notes: "Some notes",
        attendees: [
          %{email: "an.attendee@somewhere.abc"},
          %{email: "another.attendee@somewhere.abc"}
        ]
      }

      {:ok, event_id} = GoogleCalendarService.create(calendar_event)

      assert has_been_created(calendar_event, {:with, event_id})
    end

    test "should return an error when fails" do
      result = GoogleCalendarService.create(%CalendarEvent{})

      assert result == {:error, "Unable to create the calendar event"}
    end
  end

  describe "#delete" do
    test "should remove an existing calendar event" do
      {:ok, event_id} = GoogleCalendarService.create(%CalendarEvent{
        name: "A calendar event name",
        start: an_event_date()
      })

      {:ok} = GoogleCalendarService.delete(event_id)

      has_been_deleted(event_id)
    end

    test "should return an error when fails" do
      result = GoogleCalendarService.delete("NOT EXISTING ID")

      assert result == {:error, "Unable to delete the calendar event"}
    end
  end

  defp has_been_created(calendar_event, {:with, event_id}) do
    {:ok, google_calendar_event} = google_calendar_event(event_id)

    %GoogleApi.Calendar.V3.Model.Event{id: ^event_id} = google_calendar_event

    assert google_calendar_event.summary == calendar_event.name
    assert google_calendar_event.description == calendar_event.notes
    assert google_calendar_event.location == calendar_event.location
    assert parse_as_utc_datetime(google_calendar_event.start.dateTime) == calendar_event.start
    assert parse_as_utc_datetime(google_calendar_event.end.dateTime) == Timex.add(calendar_event.start, Timex.Duration.from_minutes(calendar_event.duration))

    Enum.map(google_calendar_event.attendees, & &1.email)
    |> Enum.each(& assert Enum.member?(calendar_event.attendees, %{email: &1}))
  end

  defp has_been_deleted(event_id) do
    {:ok, google_calendar_event} = google_calendar_event(event_id)

    assert google_calendar_event.status == "cancelled"
  end

  defp google_calendar_event(id) do
    google_api_connection()
    |> GoogleApi.Calendar.V3.Api.Events.calendar_events_get(@google_calendar_id, id)
  end

  defp google_api_connection do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/calendar")
    GoogleApi.Calendar.V3.Connection.new(token.token)
  end

  defp parse_as_utc_datetime(iso_date) do
    Timex.parse!(iso_date, "{ISO:Extended}")
    |> Timex.Timezone.convert("UTC")
  end

  defp an_event_date, do: Timex.to_datetime({{2018, 4, 1}, {11, 00, 00}}, "UTC")
end
