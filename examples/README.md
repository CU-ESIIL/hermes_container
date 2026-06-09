# Example Snapshots

This directory stores selected outputs captured from local OpenClaw workspace runs. These examples are tracked so the repository can preserve reproducible agent workflows without committing the whole live `/workspace` directory.

Examples should include generated reports, analysis scripts, outputs, figures, and project-state files that are useful for review. They should not include local `.env` files, OpenClaw auth state, Slack tokens, OAuth callback URLs, raw credential stores, broad logs, or private source materials unless the repository owner explicitly approves them for publication.

## Available Examples

| Example | Description |
| --- | --- |
| `pdf_to_text.sh` | Convert a PDF to text with `pdftotext`. |
| `pdf_to_images.sh` | Render PDF pages to images with `pdftoppm`. |
| `markdown_to_html.sh` | Render Markdown to HTML with `pandoc`. |
| `image_thumbnail_example.sh` | Create a thumbnail with ImageMagick. |
| `playwright_screenshot_example.py` | Capture a web page screenshot with Playwright after browser binaries are installed. |
| `notebook_placeholder.ipynb` | Minimal notebook scaffold for persistent `/data/notebooks` workflows. |
| `spatiotemporal/` | Stream-first STAC, COG, Zarr, worker-job, and output-index examples. |
| `urban_wildlife_corridors/` | Agent-generated project snapshot for an urban wildlife corridor simulation and manuscript-scaffold discussion. |
