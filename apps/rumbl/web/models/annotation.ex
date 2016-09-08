defmodule Rumbl.Annotation do
  use Rumbl.Web, :model

  schema "annotations" do
    field :body, :string
    field :at, :integer
    field :order, :integer, default: 0
    belongs_to :user, Rumbl.User
    belongs_to :video, Rumbl.Video

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :at, :order], [])
    |> put_order()
  end

  defp put_order(changeset) do
    count = length Rumbl.Repo.all(Rumbl.Annotation)
    put_change(changeset, :order, count)
  end
end
