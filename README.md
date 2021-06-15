I watched this [practice interview](https://www.youtube.com/watch?v=6s0OVdoo4Q4) with Ben Awad and Clément Mihailescu and decided to try and implement it with Phoenix Liveview.  I wanted to see if the development process would be faster and if the resulting code might be easier to understand.

# Demo solution
The app is running on the [Gigalixir](https://gigalixir.com/) free tier: [https://bawad-interview.gigalixirapp.com](https://bawad-interview.gigalixirapp.com)

# Interview
## Initial prompt
We want a site that will display "flattened" results from the `randomuser` api endpoint [https://randomuser.me/api/?results=20](https://randomuser.me/api/?results=20).  The endpoint will return user data as nested json.  Each user record returned should be displayed as a single row in a table, with at a minimum the user's `name`, `city`, `street number`, and `street name` visible.

## Follow up
Once the data is properly fetched and displayed on the site, we need to add the ability to sort by a field.  On page load, the table can be in a random order, whatever is returned by the `randomuser` api. The end user should be able to click on a column heading and have it sort the rows by that column, alphanumerically, first by ascending order.  Subsequent clicks of the same column heading toggle the sort order between ascending and descending.  If the end user first sorts column A, then clicks on column B, the site does not need to use column A's sort order to break ties.

## Bonus 1
When the end user clicks on a column header multiple times, instead of toggling between ascending and descending, it should now cycle between unsorted, then ascending, then descending, and back to unsorted, in that order.

## Bonus 2
Add a text input field where the end user can type in a search query.  On each change, the results table should only show users where one of the fields contains the search query.  The sort order functionality should continue to behave as before.
