I watched this [practice interview](https://www.youtube.com/watch?v=6s0OVdoo4Q4) with Ben Awad and Clément Mihailescu and decided to try and implement it with Phoenix Liveview.  I wanted to see if the development process would be faster and if the resulting code might be easier to understand.

# See it in action
The app is running on the [Gigalixir](https://gigalixir.com/) free tier: [https://bawad-interview.gigalixirapp.com](https://bawad-interview.gigalixirapp.com)

![demo](https://raw.githubusercontent.com/ryoung786/bawad-interview/main/demo.gif)

# Interview
## Initial prompt
> We want a site that will display "flattened" results from the `randomuser` api endpoint [https://randomuser.me/api/?results=20](https://randomuser.me/api/?results=20).  The endpoint will return user data as nested json.  Each user record returned should be displayed as a single row in a table, with at a minimum the user's `name`, `city`, `street number`, and `street name` visible.

To set things up, I started from a clean `mix phx.new --live` project.  After clearing out the sample liveview and leex template, I was ready to get started.

To test out the shape of the `randomuser` api, I opened up an `iex` session with `$ iex -S mix`.  Then I used `HTTPoison` and `Jason` to fetch the data and see how it looks:
```
iex(1)> response = HTTPoison.get!("https://randomuser.me/api/?results=2")
%HTTPoison.Response{
  body: "{\"results\":[{\"gender\":\"female\",\"name\":{\"title\":\"Mrs\",\" ... ,\"results\":2,\"page\":1,\"version\":\"1.3\"}}",
  headers: [...],
  request: %HTTPoison.Request{ ... },
  request_url: "https://randomuser.me/api/?results=2",
  status_code: 200
}
iex(2)> Jason.decode!(response.body)
%{
  "info" => %{...},
  "results" => [
    %{
      "cell" => "(831)-504-9464",
      "dob" => %{"age" => 67, "date" => "1954-08-10T03:41:18.371Z"},
      "email" => "ornella.vanoort@example.com",
      "gender" => "female",
      "id" => %{"name" => "BSN", "value" => "81884618"},
      "location" => %{
        "city" => "Maarssen",
        "coordinates" => %{"latitude" => "43.2846", "longitude" => "112.5791"},
        "country" => "Netherlands",
        "postcode" => 24645,
        "state" => "Zuid-Holland",
        "street" => %{"name" => "Koudenhorn", "number" => 9388},
        "timezone" => %{
          "description" => "Brazil, Buenos Aires, Georgetown",
          "offset" => "-3:00"
        }
      },
      "login" => %{
        "md5" => "ff011b1da7a832bdd3e468ea6b01093f",
        "password" => "killbill",
        "salt" => "9eIGy6xs",
        "sha1" => "36bea65616574c3c7f3743392e3a8ab092d15f62",
        "sha256" => "8adcf6f4dfeb267e41b8caeb487de6396ad123e9f0b2007f0ebe1e6b4c22f2bf",
        "username" => "bigbird642",
        "uuid" => "bd65ff8f-2f18-486e-9481-192f382e6381"
      },
      "name" => %{"first" => "Ornella", "last" => "Van Oort", "title" => "Mrs"},
      "nat" => "NL",
      "phone" => "(518)-425-1637",
      "picture" => %{
        "large" => "https://randomuser.me/api/portraits/women/22.jpg",
        "medium" => "https://randomuser.me/api/portraits/med/women/22.jpg",
        "thumbnail" => "https://randomuser.me/api/portraits/thumb/women/22.jpg"
      },
      "registered" => %{"age" => 2, "date" => "2019-06-03T13:24:34.791Z"}
    },
    %{ "email" => "susanna.lawrence@example.com", ... }
  ]
}
iex(3)> 
```
So we can see that the data we want, like street name and number, is indeed pretty nested.  That's ok, we can pick it out pretty cleanly just by mapping over the results:
```elixir
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
```
Wrap this in a function and we can now assign this to our socket in `mount`.  
```elixir
def mount(_params, _session, socket) do
  users = if connected?(socket), do: fetch_users(), else: []
  {:ok, assign(socket, users: users)}
end
```
Modify the template to access our new `@users` data so we can see some results when we load the page:
```
<%= for user <- @users do %>
  <tr>
    <td><%= user.name %></td>
    <td><%= user.city %></td>
    <td><%= user.state %></td>
    <td><%= user.country %></td>
    <td><%= user.street_number %></td>
    <td><%= user.street_name %></td>
  </tr>
<% end %>
```
With this, we've retrieved the data and displayed it on our webpage.

## Follow up
> Once the data is properly fetched and displayed on the site, we need to add the ability to sort by a field.  On page load, the table can be in a random order, whatever is returned by the `randomuser` api. The end user should be able to click on a column heading and have it sort the rows by that column, alphanumerically, first by ascending order.  Subsequent clicks of the same column heading toggle the sort order between ascending and descending.  If the end user first sorts column A, then clicks on column B, the site does not need to use column A's sort order to break ties.

To maintain the state of which column to sort by and what direction, we'll need to add them to our socket assigns.
```elixir
def mount(_params, _session, socket) do
  users = if connected?(socket), do: fetch_users(), else: []
  {:ok, 
   assign(socket, 
    users: users, 
    sort: %{field: :name, order: :unsorted}
   )}
end
```
Our table headers now need to be updated so that they trigger a click event, so we can tell which field to sort on.  The template for that looks like this
```
<th phx-click="sort" phx-value-field="<%= @value %>" style="cursor: pointer">
  <%= @field_name %> <%= @arrow %>
</th>
```
The important parts are the `phx-click` and `phx-value-field` attributes, which tell liveview that when clicked to send a "sort" event for the backend to handle.  The `phx-value-field` tells it to include the field name that was clicked on, which we'll need to know what to sort by.

Instead of modifying our `sort` assign right in the event handler, I think it'll be a bit more idiomatic to use `push_patch` to set the url and include the field and direction as url parameters.  This way, links can be shared around and will retain the sorted views.  To make that possible in liveview, we need to add a `handle_params` function, which reads the params, sorts the `users` appropriately, assigns the new values to the socket, and re-renders the output.
```elixir
@impl true
def handle_event("sort", %{"field" => field}, socket) do
  dir =
    if field == Atom.to_string(socket.assigns.sort.field),
      do: toggle_sort_order(socket.assigns.sort.order),
      else: :asc

  # create a url like foo.com?sort=name&dir=asc
  url = BawadWeb.Router.Helpers.page_path(socket, :index, %{sort: field, dir: dir})
  {:noreply, push_patch(socket, to: url)}
end

@impl true
def handle_params(params, _uri, socket) do
  field = sanitize_sort_field_param(params["sort"], socket.assigns.sort.field)
  order = sanitize_sort_order_param(params["dir"], socket.assigns.sort.order)

  {:noreply,
   socket
   |> assign(sort: %{field: field, order: order})
   |> assign(users: sort_users(socket.assigns.users, field, order))
end

defp sort_users(users, _field, :unsorted), do: users

defp sort_users(users, field, dir) do
  Enum.sort_by(users, fn user -> user[field] end, dir)
end
```

At this point, we now have the ability to click on a column and toggle the sort order.  As a bonus, this modifies the url so that we can preserve the state and share links.

## Bonus 1
> When the end user clicks on a column header multiple times, instead of toggling between ascending and descending, it should now cycle between unsorted, then ascending, then descending, and back to unsorted, in that order.

Our implementation makes this pretty straight forward.  Instead of `toggle_sort_order`, we can replace that with something like
```elixir
defp next_sort_order(:unsorted), do: :asc
defp next_sort_order(:asc), do: :desc
defp next_sort_order(:desc), do: :unsorted
```
This will toggle through the complete cycle.  To make the "unsorted" bit work, we'll have to store the original result of the `randomuser` api call as well.

## Bonus 2
> Add a text input field where the end user can type in a search query.  On each change, the results table should only show users where one of the fields contains the search query.  The sort order functionality should continue to behave as before.

This is where Liveview really shines, in my opinion.  We start by adding a text input to the top of our template
```
<form phx-change="filter">
  <input type="text" name="query" value="<%= @query %>">
</form>
```
We're using a new assigns, `@query`, which we'll have to set in `mount`.  `phx-change` fires whenever the text input value changes, so we need to handle that new event.  It needs to filter out any users that don't have any fields that match the query string.
```elixir
@impl true
def handle_event("filter", %{"query" => q}, socket) do
  users =
    socket.assigns.unsorted_users
    |> sort_users(socket.assigns.sort.field, socket.assigns.sort.order)
    |> filter_users(q)

  {:noreply, assign(socket, query: q, users: users)}
end

defp filter_users(users, query) do
  Enum.filter(users, fn user ->
    Enum.any?(Map.values(user), fn field ->
      "#{field}" |> String.downcase() |> String.contains?(query)
    end)
  end)
end
```
Note that elixir's pipes make this logic very straightforward.  You can tell directly that first we want to take our unsorted users and sort them by the sort field and sort order, then take that result and filter it by our query.  The `filter_users` function is a little denser, but essentially it's only keeping users in the collection if any field contains our query.

There are a bit more boilerplate pieces in the final result, like sanitizing the user input and cleaning up the table header template display logic, but that's the main gist of it.  It comes in at a little more than 100 lines (a little more if you include the leex templates), but it's pretty magical to be able to generate this functionality without writing any javascript.  Liveview is a great tool for rapid prototyping and features like this are really in its wheelhouse.
