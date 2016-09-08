defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, params, socket) do
    last_seen_order = params["last_seen_order"] || 0
    video = Repo.get!(Rumbl.Video, video_id)

    annotations = Repo.all(
        from a in assoc(video, :annotations),
        where: a.order >= ^last_seen_order,
        order_by: [asc: a.at, asc: a.order],
        limit: 200,
        preload: [:user]
      )
    resp = %{annotations: Phoenix.View.render_many(annotations, Rumbl.AnnotationView, "annotation.json")}
    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast_annotation(annotation, socket)
        Task.start_link(fn -> compute_additional_info(annotation, socket) end)
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(annotation, socket) do
    annotation = Repo.preload(annotation, :user)
    rendered_annotation = Phoenix.View.render(Rumbl.AnnotationView, "annotation.json", %{annotation: annotation})
    broadcast! socket, "new_annotation", rendered_annotation
  end

  defp compute_additional_info(annotation, socket) do
    for result <- InfoSys.compute(annotation.body, limit: 1, timeout: 10_000) do
      attrs = %{url: result.url, body: result.text, at: annotation.at}
      info_changeset =
        Repo.get_by!(Rumbl.User, username: result.backend)
        |> build_assoc(:annotations, video_id: annotation.video_id)
        |> Rumbl.Annotation.changeset(attrs)
      case Repo.insert(info_changeset) do
        {:ok, info_ann} -> broadcast_annotation(info_ann, socket)
        {:error, _changeset} -> :ignore
      end
    end
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}

    {:noreply, assign(socket, :count, count + 1)}
  end
end
