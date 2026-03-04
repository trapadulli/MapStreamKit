module.exports = async function (context) {
  context.res = {
    status: 200,
    body: {
      status: "ok",
      service: "msk-adapter"
    }
  };
};