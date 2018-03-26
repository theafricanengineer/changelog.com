defmodule Changelog.EpisodesTest do
  use Changelog.DataCase

  import Mock
  import ChangelogWeb.TimeView, only: [hours_ago: 1]

  alias Changelog.Episodes
  alias Changelog.{CalendarEvent, CalendarService}

  describe "when create an episode" do
    test "and a calendar event is successfully created a calendar event id is saved" do
      with_mock(CalendarService, [create: fn(_) -> {:ok, "EVENT_ID"} end]) do
        episode_params = %{slug: "181", title: "some content", recorded_at: hours_ago(1)}
        podcast = build(:podcast)

        expected_event = %CalendarEvent{
          name: "Recording '#{podcast.name}'",
          start: Map.get(episode_params, :recorded_at),
          duration: 90,
          location: "Skype",
          notes: "Setup guide: https://changelog.com/guest/#{podcast.slug}"
        }

        {:ok, episode} = Episodes.create(episode_params, podcast)

        assert called CalendarService.create(expected_event)
        assert episode.calendar_event_id == "EVENT_ID"
      end
    end

    test "and a calendar event is not created a calendar event id is not saved" do
      with_mock(CalendarService, [create: fn(_) -> {:error, "unable to create the event"} end]) do
        episode_params = %{slug: "181", title: "some content", recorded_at: hours_ago(1)}
        podcast = build(:podcast)

        expected_event = %CalendarEvent{
          name: "Recording '#{podcast.name}'",
          start: Map.get(episode_params, :recorded_at),
          duration: 90,
          location: "Skype",
          notes: "Setup guide: https://changelog.com/guest/#{podcast.slug}"
        }

        {:ok, episode} = Episodes.create(episode_params, podcast)

        assert called CalendarService.create(expected_event)
        assert episode.calendar_event_id == nil
      end
    end
  end
end
