module.exports = async function (context, events) {
  const batch = Array.isArray(events) ? events : [events];
  const size = batch.filter((item) => item !== undefined && item !== null).length;

  context.log(`tail processor received batch size=${size}`);
};