// media-search — proxies TMDB/RAWG so API keys stay server-side.
// Deploy in Supabase: Edge Functions -> Deploy new function -> name it
// exactly "media-search" -> paste this file -> Deploy.
// Then add secrets TMDB_KEY and RAWG_KEY under Edge Functions -> Secrets.

const TMDB = Deno.env.get("TMDB_KEY") ?? "";
const RAWG = Deno.env.get("RAWG_KEY") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
  try {
    const { action, kind, q, id } = await req.json();
    let url = "";
    if (action === "search" && typeof q === "string" && q.length >= 2) {
      if (kind === "films") url = `https://api.themoviedb.org/3/search/movie?api_key=${TMDB}&query=${encodeURIComponent(q)}`;
      else if (kind === "tv") url = `https://api.themoviedb.org/3/search/tv?api_key=${TMDB}&query=${encodeURIComponent(q)}`;
      else if (kind === "games") url = `https://api.rawg.io/api/games?key=${RAWG}&search=${encodeURIComponent(q)}&page_size=6`;
    } else if (action === "detail" && (typeof id === "number" || typeof id === "string")) {
      if (kind === "films") url = `https://api.themoviedb.org/3/movie/${id}/credits?api_key=${TMDB}`;
      else if (kind === "tv") url = `https://api.themoviedb.org/3/tv/${id}?api_key=${TMDB}`;
      else if (kind === "games") url = `https://api.rawg.io/api/games/${id}?key=${RAWG}`;
    }
    if (!url) return json({ error: "bad request" }, 400);
    const r = await fetch(url);
    return new Response(await r.text(), { status: r.status, headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
