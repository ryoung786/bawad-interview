defmodule BawadWeb.PageLive do
  use BawadWeb, :live_view

  @fields ~w(name city country state street_name street_number)
  @dirs ~w(asc desc unsorted)

  @impl true
  def mount(_params, _session, socket) do
    users = if connected?(socket), do: fetch_users(), else: []

    {:ok,
     assign(socket,
       query: "",
       results: %{},
       unsorted_users: users,
       users: users,
       sort: %{field: :name, order: :unsorted}
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    field = sanitize_sort_field_param(params["sort"], socket.assigns.sort.field)
    order = sanitize_sort_order_param(params["dir"], socket.assigns.sort.order)

    users =
      socket.assigns.unsorted_users
      |> sort_users(field, order)
      |> filter_users(socket.assigns.query)

    {:noreply,
     socket
     |> assign(sort: %{field: field, order: order})
     |> assign(users: users)}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    dir =
      if field == Atom.to_string(socket.assigns.sort.field),
        do: next_sort_order(socket.assigns.sort.order),
        else: next_sort_order(:unsorted)

    url = BawadWeb.Router.Helpers.page_path(socket, :index, %{sort: field, dir: dir})
    {:noreply, push_patch(socket, to: url)}
  end

  @impl true
  def handle_event("filter", %{"query" => q}, socket) do
    users =
      socket.assigns.unsorted_users
      |> sort_users(socket.assigns.sort.field, socket.assigns.sort.order)
      |> filter_users(q)

    {:noreply, assign(socket, query: q, users: users)}
  end

  defp next_sort_order(:unsorted), do: :asc
  defp next_sort_order(:asc), do: :desc
  defp next_sort_order(:desc), do: :unsorted

  defp sanitize_sort_field_param(param, _default) when param in @fields, do: String.to_atom(param)
  defp sanitize_sort_field_param(_param, default), do: default

  defp sanitize_sort_order_param(param, _default) when param in @dirs, do: String.to_atom(param)
  defp sanitize_sort_order_param(_param, default), do: default

  defp sort_users(users, _field, :unsorted), do: users

  defp sort_users(users, field, dir) do
    Enum.sort_by(users, fn user -> user[field] end, dir)
  end

  defp filter_users(users, query) do
    Enum.filter(users, fn user ->
      Enum.any?(Map.values(user), fn field ->
        "#{field}" |> String.downcase() |> String.contains?(query)
      end)
    end)
  end

  defp fetch_users() do
    response = HTTPoison.get!("https://randomuser.me/api/?results=20")
    %{"results" => users} = Jason.decode!(response.body)

    Enum.map(users, fn user ->
      %{
        name: "#{user["name"]["first"]} #{user["name"]["last"]}",
        city: user["location"]["city"],
        country: user["location"]["country"],
        state: user["location"]["state"],
        street_name: user["location"]["street"]["name"],
        street_number: user["location"]["street"]["number"]
      }
    end)
  end

  # template helper
  def th(field, %{field: sort_field, order: sort_order}) do
    assigns = %{
      value: Atom.to_string(field),
      field_name: field |> Atom.to_string() |> String.capitalize() |> String.replace("_", " "),
      arrow:
        case {field, sort_order} do
          {^sort_field, :asc} -> "▼"
          {^sort_field, :desc} -> "▲"
          _ -> ""
        end
    }

    render(BawadWeb.DefaultView, "table_header.html", assigns)
  end
end
