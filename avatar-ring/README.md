# Avatar ring

A dependency-free HTML, CSS, and JavaScript prototype. It loads the supplied GitHub avatar, samples a centered circular crop in a browser canvas, extracts three representative colors, and paints a CSS conic-gradient ring. Nothing computes palettes on a server.

From this folder:

```sh
python3 -m http.server 8080 --bind 127.0.0.1
```

Open <http://localhost:8080>. There is no install or build step. You can also open `index.html` directly in a browser.

Try a local picture, switch the preview between light and dark, or adjust the ring width. Local files use temporary blob URLs and are not uploaded. The only external request made by the page is for the GitHub avatar.

The `How it works` section shows measured extraction time, excluding image download and decoding. Each image selection recomputes its palette. Palette extraction uses a 64 × 64 sample, alpha-weighted RGB clustering, and population/separation scoring. Solid images repeat their color; fully transparent images show an error. This is a small visual experiment, not a perceptually tuned color engine.

Remote image hosts must allow CORS for canvas pixel access. The supplied GitHub URL does. Network or decoding failures show an error with an option to choose another file or reload the GitHub avatar.

`PLAN.md` preserves the original brainstorming discussion, including the earlier server-side option. This prototype follows the later browser-side approach.
