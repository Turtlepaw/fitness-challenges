cronAdd("Mark challenges as ended", "@midnight", () => {
  const { jsDateToString } = require(`${__hooks}/dateUtil.js`);
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(0, 0, 0, 0);
  const sevenDaysLater = new Date(midnight);
  sevenDaysLater.setDate(midnight.getDate() + 14);

  const records = $app.findRecordsByFilter(
    "challenges", // collection
    "endDate = {:endDate}", // filter
    undefined, // sort
    Infinity, // limit
    0, // offset
    { endDate: jsDateToString(midnight) } // optional filter params
  );

  for (const record of records) {
    record.set("ended", true);
    record.set("deleteDate", sevenDaysLater);
    $app.save(record);
  }
});

cronAdd("Delete old challenges", "@midnight", () => {
  const { jsDateToString } = require(`${__hooks}/dateUtil.js`);
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(0, 0, 0, 0);

  const records = $app.findRecordsByFilter(
    "challenges", // collection
    "deleteDate = {:deleteDate}", // filter
    undefined, // sort
    Infinity, // limit
    0, // offset
    { deleteDate: jsDateToString(midnight) } // optional filter params
  );

  for (const record of records) {
    console.log(`Deleting ${JSON.stringify(record)}`)
    $app.delete(record);
  }
});

routerAdd("GET", "/api/hooks/job", (c) => {
  const { jsDateToString } = require(`${__hooks}/dateUtil.js`);
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(0, 0, 0, 0);

  const records = $app.findRecordsByFilter(
    "challenges", // collection
    "deleteDate = {:deleteDate}", // filter
    undefined, // sort
    Infinity, // limit
    0, // offset
    { deleteDate: jsDateToString(midnight) } // optional filter params
  );

  try {
    for (const record of records) {
      $app.delete(record);
    }
  } catch (error) {
    return c.json(200, {
      success: false,
      error,
    });
  }
  // For debugging
  return c.json(200, {
    success: true,
    date: jsDateToString(midnight),
    records,
  });
});
