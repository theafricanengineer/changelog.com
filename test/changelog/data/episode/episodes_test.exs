defmodule Changelog.EpisodesTest do
  use Changelog.DataCase

  import Mock
  import ChangelogWeb.TimeView, only: [hours_ago: 1]

  alias Changelog.{CalendarService, CalendarEvent, Episode}
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
      start: episode_params.recorded_at,
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
      with_mock(CalendarService, []) do
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

  describe "when update an episode" do
    test "a calendar event is updated if recording time changes" do
      one_hour_ago = hours_ago(1)
      two_hours_ago = hours_ago(2)
      episode =
        insert(:episode, calendar_event_id: "EVENT_ID", recorded_at: two_hours_ago)
        |> Episode.preload_all
      expected_event =
        CalendarEvent.build_for(episode)
        |> that_starts(one_hour_ago)

      with_mock(CalendarService, [update: fn(_, _) -> {:ok} end]) do
        Episodes.update(%{recorded_at: one_hour_ago}, episode.podcast, episode.slug)

        assert called CalendarService.update("EVENT_ID", expected_event)
      end
    end

    test "a calendar event is updated if hosts and guests changes" do
      guest = insert(:person)
      host = insert(:person)
      episode =
        insert(:episode, calendar_event_id: "EVENT_ID")
        |> Episode.preload_all
      expected_event =
        CalendarEvent.build_for(episode)
        |> with_attendee(host.email)
        |> with_attendee(guest.email)

      with_mock(CalendarService, [update: fn(_, _) -> {:ok} end]) do
        episode_params = %{
          episode_guests: [%{person_id: guest.id, position: 1}],
          episode_hosts: [%{person_id: host.id, position: 1}]
        }
        Episodes.update(episode_params, episode.podcast, episode.slug)

        assert called CalendarService.update("EVENT_ID", expected_event)
      end
    end

    test "a calendar event is updated if hosts changes" do
      host = insert(:person)
      episode =
        insert(:episode, calendar_event_id: "EVENT_ID")
        |> Episode.preload_all
      expected_event =
        CalendarEvent.build_for(episode)
        |> with_attendee(host.email)

      with_mock(CalendarService, [update: fn(_, _) -> {:ok} end]) do
        episode_params = %{
          episode_hosts: [%{person_id: host.id, position: 1}]
        }
        Episodes.update(episode_params, episode.podcast, episode.slug)

        assert called CalendarService.update("EVENT_ID", expected_event)
      end
    end

    test "a calendar event is updated if guests changes" do
      guest = insert(:person)
      episode =
        insert(:episode, calendar_event_id: "EVENT_ID")
        |> Episode.preload_all
      expected_event =
        CalendarEvent.build_for(episode)
        |> with_attendee(guest.email)

      with_mock(CalendarService, [update: fn(_, _) -> {:ok} end]) do
        episode_params = %{
          episode_guests: [%{person_id: guest.id, position: 1}]
        }
        Episodes.update(episode_params, episode.podcast, episode.slug)

        assert called CalendarService.update("EVENT_ID", expected_event)
      end
    end

    test "a calendar event is created if recording time changes and there is no calendar event associated yet" do
      one_hour_ago = hours_ago(1)
      episode =
        insert(:episode, calendar_event_id: nil)
        |> Episode.preload_all
      expected_event =
        CalendarEvent.build_for(episode)
        |> that_starts(one_hour_ago)

      with_mock(CalendarService, [create: fn(_) -> {:ok, "EVENT_ID"} end]) do
        {:ok, episode} = Episodes.update(%{recorded_at: one_hour_ago}, episode.podcast, episode.slug)

        assert called CalendarService.create(expected_event)
        assert episode.calendar_event_id == "EVENT_ID"
      end
    end
  end

  describe "when delete an episode" do
    test "no calendar event is removed if not attached" do
      episode = insert(:episode, calendar_event_id: nil)

      with_mock(CalendarService, []) do
        Episodes.delete(episode.slug, episode.podcast)

        refute called CalendarService.delete(nil)
      end
    end

    test "its calendar event will be also removed" do
      episode = insert(:episode, calendar_event_id: "EVENT_ID")

      with_mock(CalendarService, [delete: fn(_) -> {:ok} end]) do
        Episodes.delete(episode.slug, episode.podcast)

        assert called CalendarService.delete("EVENT_ID")
      end
    end
  end

  defp that_starts(calendar_event, start) do
    %CalendarEvent{calendar_event | start: start}
  end

  defp with_attendee(calendar_event, email) do
    %CalendarEvent{calendar_event | attendees: [%{email: email} | calendar_event.attendees]}
  end
end
