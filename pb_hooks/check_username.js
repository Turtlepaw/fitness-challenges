routerAdd("GET", "/api/hooks/check_username", (c) => {
  let username = c.queryParam("username");

  const records = $app.dao().findRecordsByFilter(
    "users", // collection
    "username = {:username}", // filter
    undefined, // sort
    10, // limit
    0, // offset
    { username: username ?? "" } // optional filter params
  );
  let isTaken = records?.length > 0;

  return c.json(200, {
    taken: isTaken,
    message: isTaken ? "Username is taken" : "Username is available",
    username: username ?? "",
  });
});
