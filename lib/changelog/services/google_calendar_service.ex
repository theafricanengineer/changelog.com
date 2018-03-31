defmodule Changelog.Services.GoogleCalendarService do
  alias Changelog.CalendarEvent

  @google_calendar_id "bdo60t3hcbpqsgkehhef8j9sqo@group.calendar.google.com"

  def create(event = %CalendarEvent{}) do
    {:ok, %GoogleApi.Calendar.V3.Model.Event{id: event_id}} = google_connection()
      |> GoogleApi.Calendar.V3.Api.Events.calendar_events_insert(@google_calendar_id, body: payload_for(event))

    {:ok, event_id}
  end

  defp google_connection do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/calendar")
    GoogleApi.Calendar.V3.Connection.new(token.token)
  end

  defp payload_for(event) do
    %{
      summary: event.name,
      location: event.location,
      description: event.notes,
      start: %{
        dateTime: Timex.format!(event.start, "{ISO:Extended}"),
      },
      end: %{
        dateTime: add_minutes_to(event.start, event.duration) |> Timex.format!("{ISO:Extended}"),
      },
      attendees: [
        %{email: "joebew42@gmail.com"}
      ],
      reminders: %{
        useDefault: true
      }
    }
  end

  defp add_minutes_to(datetime, minutes) do
    Timex.add(datetime, Timex.Duration.from_minutes(minutes))
  end
end

# This will patch the default Poison.Decoder for the `EventDateTime` structure
# Since the default one seems to parse ONLY the `date` field
# See: https://github.com/GoogleCloudPlatform/elixir-google-api/blob/master/clients/calendar/lib/google_api/calendar/v3/model/event_date_time.ex#L42
defimpl Poison.Decoder, for: GoogleApi.Calendar.V3.Model.EventDateTime do
  import GoogleApi.Calendar.V3.Deserializer
  def decode(value, options) do
    value
    |> deserialize(:"dateTime", :date, nil, options)
  end
end
