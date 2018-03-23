defmodule Changelog.CalendarEvent do
  defstruct name: nil, start: nil, duration: 90, location: "Skype", notes: nil

  def build_for(podcast, start) do
    %__MODULE__{
      name: "Recording '#{podcast.name}'",
      start: start,
      duration: 90,
      location: "Skype",
      notes: "Setup guide: https://changelog.com/guest/#{podcast.slug}"
    }
  end
end
