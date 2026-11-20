type Ctx = { params: Promise<{ id: string }> };

export async function GET(req: Request, { params }: Ctx) {
  const { id } = await params;
  return Response.json({ id, name: new URL(req.url).searchParams.get("name") ?? "" });
}

export async function POST(req: Request, { params }: Ctx) {
  const { id } = await params;
  let body: { name?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("invalid JSON", { status: 400 });
  }
  return Response.json({ id, name: body.name ?? "" }, { status: 201 });
}
