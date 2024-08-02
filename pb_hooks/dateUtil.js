module.exports = {
  stringToJsDate: (dateString) => {
    const isoString = dateString.replace(" ", "T") + "Z";
    return new Date(isoString);
  },
  hasDatePassed: (date) => {
    const now = new Date();
    return date < now;
  },
};
