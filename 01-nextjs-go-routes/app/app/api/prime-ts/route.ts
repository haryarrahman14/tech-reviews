export async function GET(req: Request) {
  const n = Math.min(Number(new URL(req.url).searchParams.get("n")) || 0, 5_000_000);
  let count = 0;
  for (let i = 2; i < n; i++) {
    let prime = true;
    for (let j = 2; j * j <= i; j++) {
      if (i % j === 0) {
        prime = false;
        break;
      }
    }
    if (prime) count++;
  }
  return Response.json({ n, primes: count });
}
