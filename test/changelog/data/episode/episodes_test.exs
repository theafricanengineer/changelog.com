defmodule Changelog.EpisodesTest do
  use Changelog.DataCase

  import Mock
  import ChangelogWeb.TimeView, only: [hours_ago: 1]

  alias Changelog.{CalendarService, CalendarEvent}
  alias Changelog.Episodes

  setup do
    podcast = insert(:podcast)
    guest = insert(:person)
    episode_params = %{
      slug: "181",
      title: "some content",
      recorded_at: hours_ago(1),
      episode_guests: [
        %{
          person_id: guest.id,
          position: 1
        }
      ]
    }
    expected_event = %CalendarEvent{
      name: "Recording '#{podcast.name}'",
      start: Map.get(episode_params, :recorded_at),
      duration: 90,
      location: "Skype",
      notes: "Setup guide: https://changelog.com/guest/#{podcast.slug}",
      attendees: [
        %{email: guest.email}
      ]
    }

    %{
      episode_params: episode_params,
      podcast: podcast,
      expected_event: expected_event
    }
  end

  describe "when create an episode" do
    test "without a recording time a calendar event is not created", context do
      with_mock(CalendarService, [create: fn(_) -> {:ok, "EVENT_ID"} end]) do
        episode_params = %{context.episode_params | recorded_at: nil}

        {:ok, episode} = Episodes.create(episode_params, context.podcast)

        refute called CalendarService.create(%CalendarEvent{context.expected_event | start: nil})
        assert episode.calendar_event_id == nil
      end
    end

    test "and a calendar event is successfully created a calendar event id is saved", context do
      with_mock(CalendarService, [create: fn(_) -> {:ok, "EVENT_ID"} end]) do
        {:ok, episode} = Episodes.create(context.episode_params, context.podcast)

        assert called CalendarService.create(context.expected_event)
        assert episode.calendar_event_id == "EVENT_ID"
      end
    end

    test "and a calendar event is not created a calendar event id is not saved", context do
      with_mock(CalendarService, [create: fn(_) -> {:error, "unable to create the event"} end]) do
        {:ok, episode} = Episodes.create(context.episode_params, context.podcast)

        assert called CalendarService.create(context.expected_event)
        assert episode.calendar_event_id == nil
      end
    end
  end

  describe "when delete an episode" do
    test "with an attached calendar event it will be also removed" do
      episode = insert(:episode, calendar_event_id: "EVENT_ID")

      with_mock(CalendarService, [delete: fn(_) -> {:ok} end]) do
        Episodes.delete(episode.slug, episode.podcast)

        assert called CalendarService.delete("EVENT_ID")
      end
    end
  end
end
