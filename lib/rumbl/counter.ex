defmodule Rumbl.Counter do
  # API
  def inc(pid), do: send(pid, :inc)
  def dec(pid), do: send(pid, :dec)
  def val(pid, timeout \\ 5000) do
    ref = make_ref()
    send(pid, {:val, self(), ref})
    receive do
      {^ref, val} -> val
    after timeout -> exit(:timeout)
    end
  end

  # SERVER
  def start_link(initial_val) do
    {:ok, spawn_link(fn -> listen(initial_val) end)}
  end

  # tail recursive function
  defp listen(val) do
    receive do
      :inc -> listen(val + 1)
      :dec -> listen(val - 1)
      {:val, sender, ref} ->
        send sender, {ref, val}
        listen(val)
    end
  end
end
