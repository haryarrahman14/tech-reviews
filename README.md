# Tech Reviews

New things in the tools I use, tried on a real project and measured. Every review has code you can run, the raw results, and an article.

| | Question | Short answer | Read | Code |
|---|---|---|---|---|
| 01 | Next.js API routes can now be written in Go. How is `route.go` different from `route.ts`? | `route.go` is about 3× faster. `route.ts` wins on deploy, caching and stability. For now, stay on `route.ts`. | [Article](https://haryarrahman.tech/blog/nextjs-route-go-vs-route-ts) | [`01-nextjs-go-routes/`](01-nextjs-go-routes/) |

![Comparison table of route.ts and route.go: route.go wins on speed, route.ts wins on the rest](content/01-nextjs-go-routes/img/en/4-summary.png)

Rules: every number comes from the code in this repo, run on the machine named in the review. Raw output is in each review's `results/`.

Articles: [haryarrahman.tech/blog](https://haryarrahman.tech/blog) · Short videos: [@bassically.en](https://www.instagram.com/bassically.en/) (English), [@dasarnya.id](https://www.instagram.com/dasarnya.id/) (Indonesian)
