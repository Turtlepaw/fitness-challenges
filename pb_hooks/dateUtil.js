module.exports = {
  stringToJsDate: (dateString) => {
    const isoString = dateString.replace(" ", "T") + "Z";
    return new Date(isoString);
  },
  hasDatePassed: (date) => {
    const now = new Date();
    return date < now;
  },
  jsDateToString: (date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    const seconds = String(date.getSeconds()).padStart(2, "0");
    const milliseconds = String(date.getMilliseconds()).padStart(3, "0");

    //2022-01-01 00:00:00.000Z
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}Z`;
  },
};
