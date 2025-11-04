import express from "express";
import fetch from "node-fetch";

const app = express();

app.post("/deploy", async (req, res) => {
  try {
    // Optional: authenticate with a secret token
    const triggerUrl = "https://api.github.com/repos/mohithacky/test_hw/dispatches";
    const token = process.env.GITHUB_TOKEN; // store this in Firebase Functions config

    const response = await fetch(triggerUrl, {
      method: "POST",
      headers: {
        "Accept": "application/vnd.github+json",
        "Authorization": `Bearer ${token}`
      },
      body: JSON.stringify({
        event_type: "deploy_trigger" // custom event name
      })
    });

    if (!response.ok) throw new Error(`GitHub API error: ${response.statusText}`);

    res.status(200).json({ message: "Triggered deploy workflow successfully!" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default app;
