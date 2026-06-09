# Model and Auth Options

Local Docker gives you control. OAuth/subscription login may be cheapest when available. API keys are more predictable. Hosted services are easier. Local models maximize sovereignty but need hardware.

This page is a practical comparison, not a guarantee of provider availability, quotas, or future pricing. ChatGPT/Codex OAuth support can depend on your Hermes version, account entitlement, provider policy, weekly quota windows, and re-login requirements.

| Option | Best for | Monthly cost structure | Token/API cost | Setup difficulty | Privacy/data control | Laptop resource use | Reliability | Main tradeoff |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Local Docker + ChatGPT/Codex OAuth | Users who already have a qualifying ChatGPT/Codex subscription and want a local workspace | Docker is free; subscription cost is paid separately | May be included within subscription limits, but quotas and model access can change | Medium | Strong local file control, but prompts still go to the provider | Moderate for Docker and agent tooling | Good when auth is fresh and routes are supported | Not guaranteed, may have weekly quota limits, and may require re-login |
| Local Docker + OpenAI API key | Users who want predictable automation and explicit billing | Docker is free; API usage is pay-as-you-go | Billed by API usage under your OpenAI platform account | Medium | Strong local file control, provider sees API requests | Moderate for Docker and agent tooling | Usually predictable for scripts and CI-style workflows | Usage can cost more during long agent sessions |
| Hosted Hermes Launch style service | Users who want less local setup and easier operations | Hosted plan fee, usually separate from any provider usage rules | May be bundled, metered, or bring-your-own-key depending on service | Low | Less local control because runtime is hosted | Low | Often smoother for uptime, updates, and remote access | You trade control and transparency for convenience |
| Local Docker + Ollama/local model | Users prioritizing sovereignty, offline work, or private experiments | Docker is free; hardware and electricity are the main recurring costs | No external token billing for local inference | High | Highest control when models and data stay local | High, especially for larger models | Depends on your hardware, model size, and Ollama health | Needs capable hardware and may be slower or less capable than hosted frontier models |

## How To Choose

Choose **OAuth** if you already pay for ChatGPT/Codex, your Hermes version supports the route, and occasional re-login is acceptable.

Choose an **OpenAI API key** if you need repeatable automation, clearer billing, or fewer surprises around provider routes.

Choose a **hosted service** if you value fast setup, managed updates, and remote access more than local runtime control.

Choose **Ollama/local models** if data control matters most and you have hardware that can comfortably run the model you need.

For multi-agent work, model choice can vary by role. Keep the PI Liaison and Scientific Director on the most reliable approved route, then evaluate open-model API candidates for narrower specialist roles. See [Model Routing](model-routing.md).
