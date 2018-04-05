defmodule Changelog.CalendarService do
  alias Changelog.CalendarEvent

  def create(_event = %CalendarEvent{}), do: {:ok, nil}
  def delete(_event_id), do: {:ok}
end
