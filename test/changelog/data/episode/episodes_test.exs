defmodule Changelog.EpisodesTest do
  use Changelog.DataCase

  import Mock
  import ChangelogWeb.TimeView, only: [hours_ago: 1]

  alias Changelog.Episodes
  alias Changelog.{CalendarEvent, CalendarService}

  test "when create an episode a calendar event is created" do
    with_mock(CalendarService, [create: fn(_) -> {:ok} end]) do
      episode_params = %{slug: "181", title: "some content", recorded_at: hours_ago(1)}
      podcast = build(:podcast)

      expected_event = %CalendarEvent{
        name: "Recording '#{podcast.name}'",
        start: Map.get(episode_params, :recorded_at),
        duration: 90,
        location: "Skype",
        notes: "Setup guide: https://changelog.com/guest/#{podcast.slug}"
      }

      Episodes.create(episode_params, podcast)

      assert called CalendarService.create(expected_event)
    end
  end
end
