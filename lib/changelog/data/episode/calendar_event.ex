defmodule Changelog.CalendarEvent do
  defstruct name: nil, start: nil, duration: 90, location: "Skype", notes: nil

  def build_for(episode) do
    %__MODULE__{
      name: "Recording '#{episode.podcast.name}'",
      start: episode.recorded_at,
      duration: 90,
      location: "Skype",
      notes: "Setup guide: https://changelog.com/guest/#{episode.podcast.slug}"
    }
  end
end
