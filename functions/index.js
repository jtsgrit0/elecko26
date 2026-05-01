const functions = require("firebase-functions");
const axios = require("axios");
const cors = require("cors")({ origin: true });

exports.proxy = functions.https.onRequest((request, response) => {
  cors(request, response, () => {
    const url = request.query.url;
    if (!url) {
      return response.status(400).send("URL parameter is missing");
    }

    axios
      .get(url, {
        headers: {
          "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36",
        },
      })
      .then((res) => {
        response.status(200).send(res.data);
      })
      .catch((error) => {
        response.status(500).send(error.toString());
      });
  });
});