/// <reference path="./types.d.ts" />

routerAdd("GET", "/api/hooks/join/type", (c) => {
  try {
    let code = c.queryParam("code");

    const records = $app.dao().findRecordsByFilter(
      "challenges", // collection
      "code = {:code}", // filter
      undefined, // sort
      1, // limit
      0, // offset
      { code: code ?? "" } // optional filter params
    );

    if (records.length == 0) throw Error("Invalid Code");

    const record = records[0];

    return c.json(200, {
      success: false,
      type: record.getInt("type"),
    });
  } catch (error) {
    return c.json(500, {
      success: false,
      message: error.message,
    });
  }
});

routerAdd("POST", "/api/hooks/join", (c) => {
  try {
    let code = c.queryParam("code");
    //let data = c.queryParam("data");
    let id = c.queryParam("id");

    const records = $app.dao().findRecordsByFilter(
      "challenges", // collection
      "joinCode = {:code}", // filter
      undefined, // sort
      1, // limit
      0, // offset
      { code: code ?? "" } // optional filter params
    );

    if (records.length == 0) throw Error("Invalid Code");

    const record = records[0];
    const users = record.get("users") || [];

    if (!users.includes(id)) {
      // Add the user's ID to the users field
      users.push(id);
      record.set("users", users);
    }

    $app.dao().saveRecord(record);

    return c.json(200, {
      success: true,
      record: record,
      type: record.getInt("type"),
      data: record.get("data"),
      id: record.id,
    });
  } catch (error) {
    return c.json(500, {
      success: false,
      message: error.message,
    });
  }
});

routerAdd("POST", "/api/hooks/regenerate_code", (c) => {
  function getUniqueCode() {
    const generateUniqueCode = () => {
      return Math.random().toString(36).substring(2, 8).toUpperCase();
    };

    let isUnique = false;
    let uniqueCode = "";

    while (!isUnique) {
      // Generate a code
      uniqueCode = generateUniqueCode();

      // Search for existing records with the generated code
      const records = $app.dao().findRecordsByFilter(
        "challenges", // collection name
        "joinCode = {:joinCode}", // filter
        undefined, // sort
        10, // limit
        0, // offset
        { joinCode: uniqueCode } // optional filter params
      );

      // If no records found, the code is unique
      if (!records || records.length === 0) {
        isUnique = true;
      }
    }

    return uniqueCode;
  }

  try {
    let id = c.queryParam("id");
    const uniqueCode = getUniqueCode();

    const record = $app.dao().findRecordById("challenges", id);

    if (record == null) throw Error("Unknown challenge");

    record.set("joinCode", uniqueCode);
    $app.dao().saveRecord(record);

    return c.json(200, {
      success: true,
      uniqueCode: uniqueCode,
    });
  } catch (error) {
    return c.json(500, {
      success: false,
      message: error.message,
    });
  }
});
