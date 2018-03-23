defmodule Changelog.CalendarService do
  alias Changelog.CalendarEvent

  def create(_event = %CalendarEvent{}), do: nil
end
